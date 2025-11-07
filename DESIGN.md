# 技术设计文档

## 架构设计

### 整体架构

ZLift 采用分层架构设计：

```
┌─────────────────────────────────────┐
│         用户代码层                   │
│  (使用 Owned, Borrowed 等类型)      │
└─────────────────────────────────────┘
              │
┌─────────────────────────────────────┐
│          API 层                      │
│  (Owned, Borrowed, BorrowedMut)     │
└─────────────────────────────────────┘
              │
┌─────────────────────────────────────┐
│         检查器层                     │
│  (BorrowChecker, 运行时验证)        │
└─────────────────────────────────────┘
              │
┌─────────────────────────────────────┐
│         状态管理层                   │
│  (OwnershipState, 借用计数)         │
└─────────────────────────────────────┘
```

### 核心组件

#### 1. 所有权系统

**Owned(T)** 是系统的核心，负责管理值的所有权。

```zig
pub fn Owned(comptime T: type) type {
    return struct {
        value: T,                    // 实际值
        state: OwnershipState,        // 所有权状态
        borrow_count: usize,          // 不可变借用计数
        mut_borrow_count: usize,      // 可变借用计数
        // ...
    };
}
```

**状态机设计**:

```
owned ──take()──> moved
  │
  ├─borrow()──> borrowed ──release()──> owned
  │
  └─borrowMut()──> borrowed_mut ──release()──> owned
```

#### 2. 借用系统

**Borrowed(T)** 和 **BorrowedMut(T)** 提供借用语义：

- `Borrowed(T)`: 不可变借用，允许多个同时存在
- `BorrowedMut(T)`: 可变借用，独占访问

#### 3. 检查器系统

**编译时检查** (BorrowChecker):
- 使用 `comptime` 函数在编译时验证某些规则
- 通过 `@compileError` 提供编译时错误

**运行时检查**:
- 状态验证
- 借用冲突检测
- 使用 `@panic` 处理运行时违规

#### 4. 深度复制系统

**deepCopy()** 函数:
- 递归复制复杂数据结构
- 支持嵌套结构体、数组、可选类型
- 自动识别并处理 Owned 类型字段

**OwnedDeepCopy** 包装器:
- 提供深度复制语义的包装类型
- 支持结构体等复杂类型

#### 5. 线程间所有权转移系统

**OwnedSend(T)** 类型:
- 通过转移所有权实现线程安全
- 类似 Rust 的 Send trait
- 支持嵌套 OwnedSend 字段
- 每个字段可独立转移

## 类型系统设计

### 泛型设计

所有核心类型都使用 Zig 的泛型系统：

```zig
pub fn Owned(comptime T: type) type { ... }
pub fn Borrowed(comptime T: type) type { ... }
pub fn BorrowedMut(comptime T: type) type { ... }
```

这允许类型系统在编译时进行类型检查。

### 所有权状态枚举

```zig
const OwnershipState = enum {
    owned,        // 拥有所有权，可以使用
    moved,        // 已移动，不能再使用
    borrowed,     // 被不可变借用
    borrowed_mut, // 被可变借用
};
```

## API 设计

### 核心 API

#### Owned(T)

```zig
// 创建
pub fn init(value: T) Self

// 移动
pub fn take(self: *Self) T

// 借用
pub fn borrow(self: *Self) Borrowed(T)
pub fn borrowMut(self: *Self) BorrowedMut(T)

// 访问
pub fn get(self: *Self) *T
pub fn getMut(self: *Self) *T

// 检查
pub fn isValid(self: *const Self) bool
```

#### Borrowed(T)

```zig
// 访问
pub fn get(self: *const Self) *const T
pub fn deref(self: *const Self) T

// 释放
pub fn release(self: *Self) void
```

#### BorrowedMut(T)

```zig
// 访问
pub fn get(self: *Self) *T
pub fn getConst(self: *const Self) *const T
pub fn deref(self: *Self) T

// 释放
pub fn release(self: *Self) void
```

### 辅助函数 API

提供便捷的辅助函数：

```zig
pub fn owned(comptime T: type, value: T) Owned(T)
pub fn move(comptime T: type, owned_val: *Owned(T)) T
pub fn borrow(comptime T: type, owned_val: *Owned(T)) Borrowed(T)
pub fn borrowMut(comptime T: type, owned_val: *Owned(T)) BorrowedMut(T)
pub fn ownedSend(comptime T: type, value: T) OwnedSend(T)
pub fn deepCopy(comptime T: type, value: T) T
```

### OwnedSend API

```zig
// 创建
pub fn init(value: T) Self

// 转移
pub fn sendToThread(self: *Self) T

// 访问（仅在当前线程）
pub fn get(self: *Self) *T
pub fn getMut(self: *Self) *T

// 检查
pub fn isInCurrentThread(self: *const Self) bool
pub fn isValid(self: *const Self) bool
```

## 借用规则实现

### 规则 1: 多个不可变借用

**实现方式**:
- 使用 `borrow_count` 跟踪不可变借用数量
- 允许多个 `Borrowed(T)` 同时存在
- 状态设为 `borrowed`

**代码**:
```zig
pub fn borrow(self: *Self) Borrowed(T) {
    if (self.state == .borrowed_mut) {
        @panic("cannot create immutable borrow while mutable borrow exists");
    }
    self.state = .borrowed;
    self.borrow_count += 1;
    return Borrowed(T).init(self);
}
```

### 规则 2: 独占可变借用

**实现方式**:
- 使用 `mut_borrow_count` 跟踪可变借用
- 检查是否存在其他借用
- 状态设为 `borrowed_mut`

**代码**:
```zig
pub fn borrowMut(self: *Self) BorrowedMut(T) {
    if (self.state == .borrowed or self.state == .borrowed_mut) {
        @panic("cannot create mutable borrow while borrow exists");
    }
    self.state = .borrowed_mut;
    self.mut_borrow_count = 1;
    return BorrowedMut(T).init(self);
}
```

### 规则 3: 借用期间不能移动

**实现方式**:
- 在 `take()` 方法中检查状态
- 如果处于借用状态，拒绝移动

**代码**:
```zig
pub fn take(self: *Self) T {
    if (self.state == .borrowed or self.state == .borrowed_mut) {
        @panic("cannot move value while it is borrowed");
    }
    // ...
}
```

## 编译时检查机制

### Comptime 函数

使用 `comptime` 关键字在编译时执行检查：

```zig
pub const BorrowChecker = struct {
    pub fn comptimeCheckNotMoved(comptime state: OwnershipState) void {
        if (state == .moved) {
            @compileError("attempted to use moved value");
        }
    }
    // ...
};
```

### 限制

由于 Zig 的类型系统限制，编译时检查主要针对：
- 常量值的状态
- 类型级别的验证

大部分检查在运行时进行。

## 运行时验证机制

### 状态跟踪

每个 `Owned` 值维护：
- `state`: 当前所有权状态
- `borrow_count`: 活跃的不可变借用数量
- `mut_borrow_count`: 活跃的可变借用数量

### 验证点

在关键操作点进行验证：
1. **移动时**: 检查是否已移动或正在借用
2. **借用时**: 检查是否存在冲突的借用
3. **释放时**: 更新状态和计数

### 错误处理

使用 `@panic` 处理运行时违规：
- 提供清晰的错误信息
- 立即终止程序（防止未定义行为）

## 内存安全保证

### 防止的问题

1. **使用已移动的值**
   - 通过状态检查防止

2. **双重释放**
   - 移动后状态变为 `moved`，无法再次释放

3. **借用冲突**
   - 运行时检查防止多个可变借用
   - 防止可变和不可变借用同时存在

4. **悬垂引用**
   - 借用持有对 `Owned` 的引用
   - 释放借用时更新状态

### 限制

- 不防止所有内存安全问题（如越界访问）
- 主要关注所有权和借用语义
- 需要用户正确使用 API

## 性能考虑

### 开销分析

1. **内存开销**:
   - 每个 `Owned` 值增加约 16-24 字节（状态 + 计数）
   - 每个借用增加 8 字节（指针）

2. **运行时开销**:
   - 状态检查：O(1)
   - 借用操作：O(1)
   - 释放操作：O(1)

3. **编译时开销**:
   - Comptime 检查：编译时执行，无运行时开销

### 优化建议

1. 在 ReleaseFast 模式下，某些检查可以优化掉
2. 对于性能关键代码，可以考虑禁用某些检查
3. 使用内联函数减少函数调用开销

## 扩展性设计

### 已实现扩展

1. **深度复制支持** ✅
   - `deepCopy()` 函数支持复杂数据结构
   - 支持嵌套结构体和 Owned 类型
   - `OwnedDeepCopy` 包装器类型

2. **嵌套结构体支持** ✅
   - 完整支持嵌套结构体中的 Owned 类型
   - 支持深度嵌套结构体
   - 嵌套字段的独立生命周期控制

3. **线程间所有权转移** ✅
   - `OwnedSend` 类型（类似 Rust 的 Send）
   - 通过转移所有权实现线程安全
   - 支持嵌套 OwnedSend 字段

4. **指针使用支持** ✅
   - 文档说明指针与 Owned 系统的交互
   - 指针在借用和移动时的行为

### 未来扩展方向

1. **生命周期参数**
   - 支持显式生命周期标注
   - 类似 Rust 的 `'a` 语法

2. **更多 Rust 特性**
   - `Rc<T>` (引用计数)
   - `RefCell<T>` (内部可变性)

3. **工具支持**
   - 静态分析工具
   - IDE 插件
   - 调试工具

### 可扩展点

- 类型系统：易于添加新类型
- 检查器：可以扩展检查规则
- API：可以添加新的辅助函数

## 测试策略

### 单元测试

- 每个核心功能都有对应的测试
- 使用 Zig 的 `test` 块
- 覆盖正常情况和边界情况

### 集成测试

- 通过示例代码进行集成测试
- 验证实际使用场景

### 错误情况测试

- 测试各种违规情况
- 验证错误处理正确性

## 总结

ZLift 通过类型系统和运行时检查的结合，在 Zig 中实现了类似 Rust 的所有权系统。虽然不能完全达到 Rust 编译时检查的严格程度，但提供了实用的内存安全保障。

设计重点：
1. **简单性**: API 设计简洁易用
2. **安全性**: 运行时检查确保正确性
3. **性能**: 最小化运行时开销
4. **可扩展性**: 易于添加新功能


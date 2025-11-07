# ZLift - Zig 生命周期管理系统

基于 Zig 0.15.2 实现的仿 Rust 变量生命周期管理系统，提供移动语义和借用检查功能。

## 特性

- **移动语义 (Move Semantics)**: 实现值的所有权转移，确保值只能被使用一次
- **借用检查 (Borrow Checker)**: 支持不可变借用和可变借用，防止数据竞争
- **编译时检查**: 利用 Zig 的 comptime 特性进行编译时验证
- **运行时验证**: 提供运行时检查作为补充，确保内存安全

## 快速开始

### 构建项目

```bash
source env.sh  # 设置 Zig 0.15.2 路径
zig build
```

### 运行示例

```bash
zig build run
```

### 运行测试

```bash
zig build test
```

## 使用示例

### 基本所有权

```zig
const lifetime = @import("lifetime");

// 创建拥有所有权的值
var owned_val = lifetime.owned(i32, 42);

// 移动值（转移所有权）
const moved = lifetime.move(i32, &owned_val);
// owned_val 现在已失效
```

### 不可变借用

```zig
var owned_val = lifetime.owned(i32, 100);

// 创建不可变借用（可以有多个）
var borrow1 = owned_val.borrow();
var borrow2 = owned_val.borrow();

// 使用借用
std.debug.print("值: {}\n", .{borrow1.deref()});

// 释放借用
borrow1.release();
borrow2.release();
```

### 可变借用

```zig
var owned_val = lifetime.owned(i32, 200);

// 创建可变借用（独占）
var borrow_mut = owned_val.borrowMut();

// 通过可变借用修改值
borrow_mut.get().* = 300;

// 释放借用
borrow_mut.release();
```

## API 参考

### Owned(T)

拥有所有权的包装类型。

- `init(value: T)`: 创建新的 Owned 值
- `take()`: 转移所有权（移动）
- `borrow()`: 创建不可变借用
- `borrowMut()`: 创建可变借用
- `get()`: 获取值的引用（未借用时）
- `getMut()`: 获取值的可变引用（未借用时）
- `isValid()`: 检查值是否有效

### Borrowed(T)

不可变借用类型。

- `get()`: 获取值的不可变引用
- `deref()`: 解引用获取值
- `release()`: 释放借用

### BorrowedMut(T)

可变借用类型。

- `get()`: 获取值的可变引用
- `getConst()`: 获取值的不可变引用
- `deref()`: 解引用获取值
- `release()`: 释放借用

### 辅助函数

- `owned(T, value)`: 创建 Owned 值
- `move(T, owned_val)`: 移动值
- `borrow(T, owned_val)`: 创建不可变借用
- `borrowMut(T, owned_val)`: 创建可变借用

## 借用规则

1. **多个不可变借用**: 可以同时存在多个不可变借用
2. **独占可变借用**: 可变借用是独占的，不能与其他借用同时存在
3. **借用期间不能移动**: 在借用期间不能移动值
4. **借用必须释放**: 使用完借用后应该调用 `release()` 释放

## 项目结构

```
zlift/
├── build.zig          # 构建配置
├── build.zig.zon      # 包配置
├── src/
│   ├── lifetime.zig   # 核心生命周期管理库
│   ├── main.zig       # 示例程序入口
│   └── examples/      # 示例代码
│       ├── move_semantics.zig
│       ├── borrowing.zig
│       └── lifetime_examples.zig
├── PLAN.md            # 项目计划文档
├── DESIGN.md          # 技术设计文档
└── README.md          # 本文件
```

## 设计理念

本项目旨在在 Zig 中模拟 Rust 的所有权系统，通过类型系统和运行时检查的结合，提供类似的内存安全保障。虽然 Zig 本身不强制执行这些规则，但通过库的方式可以让开发者选择性地使用这些安全特性。

## 限制

- 借用检查主要在运行时进行，编译时检查有限
- 性能开销：运行时检查会带来一定的性能开销
- 不是 Zig 语言的原生特性，需要显式使用库提供的类型

## 许可证

本项目采用 MIT 许可证。

## 贡献

欢迎提交 Issue 和 Pull Request！


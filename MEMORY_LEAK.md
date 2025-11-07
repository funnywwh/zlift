# 如何解决内存泄漏问题

本文档说明在使用 ZLift 生命周期管理系统时如何避免和解决内存泄漏问题。

## 内存泄漏问题

### 什么是内存泄漏？

内存泄漏是指程序分配的内存无法被释放，导致内存使用量持续增长。

### 常见的内存泄漏场景

1. **忘记释放借用**
   ```zig
   // ❌ 错误：忘记释放借用
   var borrow = owned_val.borrow();
   // 忘记调用 borrow.release();
   ```

2. **循环引用导致无法释放**
   ```zig
   // ❌ 错误：循环引用
   node1.next = &node2;
   node2.next = &node1;  // 无法释放
   ```

3. **移动后忘记清理**
   ```zig
   // ❌ 错误：移动后原值可能包含需要释放的资源
   const moved = owned_val.take();
   // 如果 owned_val 包含动态分配的内存，可能泄漏
   ```

4. **动态分配的内存未释放**
   ```zig
   // ❌ 错误：分配的内存未释放
   const str = allocator.dupe(u8, "hello") catch return;
   // 忘记调用 allocator.free(str);
   ```

5. **异常路径未释放资源**
   ```zig
   // ❌ 错误：异常时未释放
   var borrow = owned_val.borrow();
   if (some_condition) return;  // 提前返回，未释放
   borrow.release();
   ```

## 解决方案

### 方案 1: 使用 defer 确保释放

**defer 是 Zig 的关键特性，确保资源在作用域结束时自动释放**：

```zig
var owned_val = lifetime.owned(i32, 100);

// ✅ 正确：使用 defer 确保释放
{
    var borrow = owned_val.borrow();
    defer borrow.release();  // 确保在作用域结束时释放
    
    std.debug.print("使用借用: {}\n", .{borrow.deref()});
    // 即使这里发生错误或提前返回，defer 也会执行
}

// 借用已释放，可以继续使用
std.debug.print("值仍然有效: {}\n", .{owned_val.get().*});
```

**优点**:
- 自动释放，即使发生错误
- 代码更安全
- 符合 Zig 的最佳实践

**最佳实践**:
- 总是使用 `defer` 释放借用
- 在获取资源后立即使用 `defer`

### 方案 2: 使用 Arena 分配器统一管理

**Arena 分配器统一管理所有内存，释放时一次性释放所有内存**：

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();  // 释放所有在 Arena 中分配的内存

const allocator = arena.allocator();

// 在 Arena 中创建多个 Owned 值
const Person = struct {
    name: lifetime.Owned([]const u8),
    age: lifetime.Owned(i32),
};

const name1 = allocator.dupe(u8, "Alice") catch return;
const name2 = allocator.dupe(u8, "Bob") catch return;

const person1 = Person{
    .name = lifetime.owned([]const u8, name1),
    .age = lifetime.owned(i32, 30),
};

// Arena 释放时，所有内存一起释放
```

**优点**:
- 统一管理，无需逐个释放
- 避免部分释放问题
- 简化内存管理

**适用场景**:
- 临时数据结构
- 一次性使用的数据
- 需要同时释放的多个对象

### 方案 3: 使用作用域限制生命周期

**使用作用域限制借用的生命周期，确保自动释放**：

```zig
var owned_val = lifetime.owned(i32, 42);

// 使用作用域限制借用的生命周期
{
    var borrow1 = owned_val.borrow();
    defer borrow1.release();
    
    std.debug.print("借用1: {}\n", .{borrow1.deref()});
    
    {
        var borrow2 = owned_val.borrow();
        defer borrow2.release();
        
        std.debug.print("借用2: {}\n", .{borrow2.deref()});
        // borrow2 在这里自动释放
    }
    
    // borrow1 在这里自动释放
}

// 所有借用都已释放
```

**优点**:
- 清晰的生命周期管理
- 借用自动释放
- 避免忘记释放

### 方案 4: 使用 RAII 模式

**RAII (Resource Acquisition Is Initialization) - 资源获取即初始化**：

```zig
const Resource = struct {
    value: lifetime.Owned(i32),
    
    fn init(val: i32) @This() {
        return @This(){
            .value = lifetime.owned(i32, val),
        };
    }
    
    // 析构函数（Zig 中使用 defer 或作用域）
    fn deinit(self: *@This()) void {
        // 如果需要清理，在这里进行
        _ = self;
    }
};

{
    var resource = Resource.init(100);
    defer resource.deinit();
    
    std.debug.print("资源值: {}\n", .{resource.value.get().*});
    // resource 在作用域结束时自动清理
}
```

**优点**:
- 资源自动管理
- 异常安全
- 符合 RAII 原则

### 方案 5: 避免循环引用

**循环引用会导致内存泄漏，因为对象无法被释放**：

详细内容请参考 `CIRCULAR_REFERENCE.md`。

**解决方案**:
1. 使用索引而不是指针
2. 使用弱引用（Weak）
3. 使用单向引用
4. 重新设计数据结构

### 方案 6: 检查资源泄漏

**使用 `isValid()` 检查资源状态，及时发现泄漏问题**：

```zig
var owned_val = lifetime.owned(i32, 200);

// 检查值是否有效
std.debug.print("初始状态 isValid: {}\n", .{owned_val.isValid()});

// 创建借用
var borrow = owned_val.borrow();
std.debug.print("借用后 isValid: {}\n", .{owned_val.isValid()});

// 释放借用
borrow.release();
std.debug.print("释放后 isValid: {}\n", .{owned_val.isValid()});

// 移动值
const moved = owned_val.take();
std.debug.print("移动后 isValid: {}\n", .{owned_val.isValid()});
```

**优点**:
- 可以检查资源状态
- 及时发现泄漏问题
- 调试更容易

## 最佳实践

### 1. 总是使用 defer 释放资源

```zig
var borrow = owned_val.borrow();
defer borrow.release();  // ✅ 总是使用 defer
```

### 2. 使用 Arena 分配器统一管理

```zig
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();  // ✅ 统一释放
```

### 3. 使用作用域限制生命周期

```zig
{
    var borrow = owned_val.borrow();
    defer borrow.release();
    // 使用 borrow
}  // ✅ 自动释放
```

### 4. 避免循环引用

- 使用索引而不是指针
- 使用弱引用（Weak）
- 使用单向引用

### 5. 检查资源状态

```zig
if (owned_val.isValid()) {
    // ✅ 检查后再使用
}
```

### 6. 使用 RAII 模式

- 资源获取即初始化
- 资源释放在析构时

### 7. 测试和验证

- 使用内存检查工具（如 Valgrind）
- 检查资源泄漏
- 验证所有路径都正确释放

## 内存泄漏检测

### 使用 Zig 的内存检查

Zig 提供了内存检查工具，可以在编译时和运行时检测内存问题：

```bash
# 使用 AddressSanitizer
zig build -Doptimize=Debug -fsanitize=address

# 使用 LeakSanitizer
zig build -Doptimize=Debug -fsanitize=leak
```

### 手动检查

1. **检查借用计数**
   - 确保所有借用都已释放
   - 使用 `isValid()` 检查状态

2. **检查移动状态**
   - 确保移动后的值被正确使用
   - 避免重复移动

3. **检查循环引用**
   - 使用索引或弱引用
   - 避免双向引用

## 常见错误和修复

### 错误 1: 忘记释放借用

```zig
// ❌ 错误
var borrow = owned_val.borrow();
// 忘记 release()

// ✅ 正确
var borrow = owned_val.borrow();
defer borrow.release();
```

### 错误 2: 异常路径未释放

```zig
// ❌ 错误
var borrow = owned_val.borrow();
if (error_condition) return;  // 提前返回，未释放
borrow.release();

// ✅ 正确
var borrow = owned_val.borrow();
defer borrow.release();  // 即使提前返回也会释放
if (error_condition) return;
```

### 错误 3: 循环引用

```zig
// ❌ 错误
node1.next = &node2;
node2.next = &node1;  // 循环引用

// ✅ 正确：使用索引
nodes[0].next_index = 1;
nodes[1].next_index = 0;  // 使用索引，可以释放
```

### 错误 4: 动态内存未释放

```zig
// ❌ 错误
const str = allocator.dupe(u8, "hello") catch return;
// 忘记 free

// ✅ 正确：使用 Arena
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
defer arena.deinit();
const str = arena.allocator().dupe(u8, "hello") catch return;
// Arena 释放时自动释放
```

## 示例代码

完整示例请参考 `src/examples/memory_leak.zig`，包含：

- `memoryLeakProblem()` - 内存泄漏问题演示
- `solutionUsingDefer()` - 使用 defer 的解决方案
- `solutionUsingArena()` - 使用 Arena 的解决方案
- `solutionUsingScope()` - 使用作用域的解决方案
- `solutionUsingRAII()` - 使用 RAII 的解决方案
- `solutionAvoidCircularReference()` - 避免循环引用
- `solutionCheckLeaks()` - 检查资源泄漏
- `bestPractices()` - 最佳实践总结

## 总结

避免内存泄漏的关键原则：

1. **总是使用 defer**: 确保资源自动释放
2. **使用 Arena**: 统一管理内存
3. **使用作用域**: 限制生命周期
4. **避免循环引用**: 使用索引或弱引用
5. **检查资源状态**: 使用 `isValid()` 检查
6. **使用 RAII**: 资源自动管理
7. **测试验证**: 使用工具检查泄漏

通过这些方法，可以有效地避免内存泄漏问题，确保内存安全。


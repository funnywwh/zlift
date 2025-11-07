# 指针使用指南

本文档说明如何在 ZLift 生命周期管理系统中使用指针。

## 基本指针操作

### 1. 获取 Owned 值的指针

```zig
var owned_val = lifetime.owned(i32, 42);

// 获取可变指针
const ptr = owned_val.get();
ptr.* = 100;  // 通过指针修改值

// 获取不可变指针
const const_ptr = owned_val.get();
// const_ptr.* = 100;  // 错误：不可变指针不能修改
```

### 2. 结构体包含指针字段

```zig
const Node = struct {
    value: i32,
    next: ?*Node,  // 可选指针字段
};

var node1 = Node{ .value = 1, .next = null };
var node2 = Node{ .value = 2, .next = null };
node1.next = &node2;  // 链接节点
```

### 3. Owned 值包含指针

```zig
const Data = struct {
    value: i32,
    ptr: *i32,  // 指向外部值的指针
};

var num: i32 = 100;
var data = lifetime.owned(Data, .{
    .value = 42,
    .ptr = &num,  // 指针指向外部变量
});

// 通过指针修改外部值
data.value.ptr.* = 200;
```

## 指针与借用

### 指针和借用的关系

```zig
var owned_val = lifetime.owned(i32, 42);

// 获取指针
const ptr = owned_val.get();

// 创建借用
var borrow = owned_val.borrow();
std.debug.print("借用值: {}\n", .{borrow.deref()});

// 在借用期间，仍然可以通过指针访问
// 但要注意借用规则：不能移动值
borrow.release();

// 移动值后，指针失效（不应再使用）
const moved = owned_val.take();
```

## 指针数组

```zig
var nums = [_]i32{ 10, 20, 30, 40, 50 };
var ptrs: [5]*i32 = undefined;

// 创建指针数组
for (0..5) |i| {
    ptrs[i] = &nums[i];
}

// 通过指针数组访问
for (ptrs) |ptr| {
    std.debug.print("{} ", .{ptr.*});
}
```

## 嵌套指针和 Owned

```zig
const Container = struct {
    data: lifetime.Owned(i32),
    ref: *lifetime.Owned(i32),  // 指向另一个 Owned 值的指针
};

var owned_val = lifetime.owned(i32, 42);
var container = Container{
    .data = lifetime.owned(i32, 100),
    .ref = &owned_val,  // 指针指向另一个 Owned 值
};

// 通过引用修改
container.ref.value = 200;
```

## 函数参数中的指针

```zig
// 接受可变指针的函数
fn modifyValue(ptr: *i32) void {
    ptr.* = 999;
}

// 接受不可变指针的函数
fn readValue(ptr: *const i32) i32 {
    return ptr.*;
}

// 使用
var num: i32 = 42;
modifyValue(&num);

// 与 Owned 结合
var owned = lifetime.owned(i32, 100);
modifyValue(owned.get());
```

## 多级指针

```zig
var num: i32 = 42;
var ptr: *i32 = &num;
const ptr_to_ptr: **i32 = &ptr;

// 通过多级指针访问
std.debug.print("{}", .{ptr_to_ptr.*.*});

// 通过多级指针修改
ptr_to_ptr.*.* = 100;
```

## 指针与深度复制

**重要提示**：深度复制时，指针会被复制，但指向同一内存地址。

```zig
const WithPointer = struct {
    value: i32,
    ptr: *i32,
};

var num: i32 = 42;
const original = WithPointer{
    .value = 10,
    .ptr = &num,
};

// 深度复制
const copied = lifetime.deepCopy(WithPointer, original);

// 注意：original.ptr 和 copied.ptr 指向同一内存
// 修改 original.ptr.* 会影响 copied.ptr.*
original.ptr.* = 100;
// copied.ptr.* 现在也是 100
```

## 注意事项

1. **指针生命周期**：指针指向的值必须在使用指针期间保持有效
2. **移动后指针失效**：当 Owned 值被移动后，指向它的指针不应再使用
3. **借用期间**：在借用期间，可以通过指针访问值，但不能移动值
4. **深度复制限制**：深度复制不会复制指针指向的内容，只复制指针本身

## 最佳实践

1. **优先使用借用**：对于临时访问，优先使用 `borrow()` 而不是获取指针
2. **明确所有权**：确保指针指向的值有明确的所有者
3. **避免悬垂指针**：确保指针指向的值在使用期间有效
4. **谨慎使用多级指针**：多级指针会增加代码复杂度，谨慎使用

## 示例代码

完整示例请参考 `src/examples/pointer_usage.zig`，包含以下示例：

- `pointerWithOwnedExample()` - 指针与 Owned 值结合使用
- `structWithPointerExample()` - 结构体包含指针字段
- `ownedWithPointerExample()` - Owned 值包含指针
- `pointerArrayExample()` - 指针数组
- `nestedPointerOwnedExample()` - 嵌套指针和 Owned
- `pointerInFunctionExample()` - 函数参数中的指针
- `pointerBorrowCheckExample()` - 指针的借用检查
- `multiLevelPointerExample()` - 多级指针
- `pointerDeepCopyExample()` - 指针与深度复制


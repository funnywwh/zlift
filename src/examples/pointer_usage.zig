const std = @import("std");
const lifetime = @import("lifetime");

/// 指针与 Owned 值结合使用
pub fn pointerWithOwnedExample() void {
    std.debug.print("=== 指针与 Owned 值结合使用 ===\n", .{});

    // 创建 Owned 值
    var owned_val = lifetime.owned(i32, 42);

    // 获取值的指针
    const ptr = owned_val.get();
    std.debug.print("通过指针访问值: {}\n", .{ptr.*});

    // 通过指针修改值
    ptr.* = 100;
    std.debug.print("修改后的值: {}\n", .{owned_val.value});

    // 创建不可变指针
    const const_ptr = owned_val.get();
    std.debug.print("通过不可变指针访问: {}\n", .{const_ptr.*});

    std.debug.print("\n", .{});
}

// 链表节点结构体
const Node = struct {
    value: i32,
    next: ?*Node,
};

/// 结构体包含指针字段
pub fn structWithPointerExample() void {
    std.debug.print("=== 结构体包含指针字段 ===\n", .{});

    // 创建节点
    var node1 = Node{ .value = 1, .next = null };
    var node2 = Node{ .value = 2, .next = null };
    var node3 = Node{ .value = 3, .next = null };

    // 链接节点
    node2.next = &node3;
    node1.next = &node2;

    // 遍历链表
    var current: ?*Node = &node1;
    std.debug.print("链表: ", .{});
    while (current) |node| {
        std.debug.print("{} -> ", .{node.value});
        current = node.next;
    }
    std.debug.print("null\n", .{});

    std.debug.print("\n", .{});
}

/// Owned 值包含指针
pub fn ownedWithPointerExample() void {
    std.debug.print("=== Owned 值包含指针 ===\n", .{});

    const Data = struct {
        value: i32,
        ptr: *i32,
    };

    var num: i32 = 100;
    var data = lifetime.owned(Data, .{
        .value = 42,
        .ptr = &num,
    });

    std.debug.print("Data.value: {}\n", .{data.value.value});
    std.debug.print("Data.ptr.*: {}\n", .{data.value.ptr.*});

    // 通过指针修改
    data.value.ptr.* = 200;
    std.debug.print("修改后 num: {}\n", .{num});
    std.debug.print("修改后 Data.ptr.*: {}\n", .{data.value.ptr.*});

    // 通过可变借用修改
    var borrow_mut = data.borrowMut();
    borrow_mut.get().value = 300;
    borrow_mut.get().ptr.* = 400;
    std.debug.print("借用修改后 value: {}\n", .{borrow_mut.get().value});
    std.debug.print("借用修改后 ptr.*: {}\n", .{borrow_mut.get().ptr.*});
    borrow_mut.release();

    std.debug.print("\n", .{});
}

/// 指针数组
pub fn pointerArrayExample() void {
    std.debug.print("=== 指针数组 ===\n", .{});

    var nums = [_]i32{ 10, 20, 30, 40, 50 };
    var ptrs: [5]*i32 = undefined;

    // 创建指针数组
    for (0..5) |i| {
        ptrs[i] = &nums[i];
    }

    std.debug.print("通过指针数组访问: ", .{});
    for (ptrs) |ptr| {
        std.debug.print("{} ", .{ptr.*});
    }
    std.debug.print("\n", .{});

    // 修改值
    ptrs[0].* = 100;
    std.debug.print("修改后 nums[0]: {}\n", .{nums[0]});

    std.debug.print("\n", .{});
}

/// 嵌套指针和 Owned
pub fn nestedPointerOwnedExample() void {
    std.debug.print("=== 嵌套指针和 Owned ===\n", .{});

    const Container = struct {
        data: lifetime.Owned(i32),
        ref: *lifetime.Owned(i32),
    };

    var owned_val = lifetime.owned(i32, 42);
    var container = Container{
        .data = lifetime.owned(i32, 100),
        .ref = &owned_val,
    };

    std.debug.print("container.data.value: {}\n", .{container.data.value});
    std.debug.print("container.ref.value: {}\n", .{container.ref.value});

    // 通过引用修改
    container.ref.value = 200;
    std.debug.print("修改后 container.ref.value: {}\n", .{container.ref.value});
    std.debug.print("修改后 owned_val.value: {}\n", .{owned_val.value});

    // 借用 container.data
    var borrow = container.data.borrow();
    std.debug.print("借用 container.data: {}\n", .{borrow.deref()});
    borrow.release();

    std.debug.print("\n", .{});
}

// 辅助函数：修改值
fn modifyValue(ptr: *i32) void {
    ptr.* = 999;
}

// 辅助函数：读取值
fn readValue(ptr: *const i32) i32 {
    return ptr.*;
}

/// 函数参数中的指针
pub fn pointerInFunctionExample() void {
    std.debug.print("=== 函数参数中的指针 ===\n", .{});

    var num: i32 = 42;
    std.debug.print("初始值: {}\n", .{num});

    // 传递可变指针
    modifyValue(&num);
    std.debug.print("修改后: {}\n", .{num});

    // 传递不可变指针
    const result = readValue(&num);
    std.debug.print("读取值: {}\n", .{result});

    // 与 Owned 结合
    var owned = lifetime.owned(i32, 100);
    modifyValue(owned.get());
    std.debug.print("通过指针修改 Owned 值: {}\n", .{owned.value});

    std.debug.print("\n", .{});
}

/// 指针的借用检查
pub fn pointerBorrowCheckExample() void {
    std.debug.print("=== 指针的借用检查 ===\n", .{});

    var owned_val = lifetime.owned(i32, 42);

    // 获取指针
    const ptr1 = owned_val.get();
    std.debug.print("ptr1.*: {}\n", .{ptr1.*});

    // 创建借用
    var borrow = owned_val.borrow();
    std.debug.print("借用值: {}\n", .{borrow.deref()});

    // 在借用期间，仍然可以通过指针访问（但要注意借用规则）
    // 这里展示指针和借用的关系
    std.debug.print("借用期间 ptr1.*: {}\n", .{ptr1.*});

    borrow.release();

    // 移动值后，指针失效
    const moved = owned_val.take();
    std.debug.print("移动后的值: {}\n", .{moved});
    // ptr1 现在指向已移动的值，不应该再使用

    std.debug.print("\n", .{});
}

/// 多级指针
pub fn multiLevelPointerExample() void {
    std.debug.print("=== 多级指针 ===\n", .{});

    var num: i32 = 42;
    var ptr: *i32 = &num;
    const ptr_to_ptr: **i32 = &ptr;

    std.debug.print("num: {}\n", .{num});
    std.debug.print("ptr.*: {}\n", .{ptr.*});
    std.debug.print("ptr_to_ptr.*.*: {}\n", .{ptr_to_ptr.*.*});

    // 通过多级指针修改
    ptr_to_ptr.*.* = 100;
    std.debug.print("修改后 num: {}\n", .{num});

    std.debug.print("\n", .{});
}

/// 指针与深度复制
pub fn pointerDeepCopyExample() void {
    std.debug.print("=== 指针与深度复制 ===\n", .{});

    const WithPointer = struct {
        value: i32,
        ptr: *i32,
    };

    var num: i32 = 42;
    const original = WithPointer{
        .value = 10,
        .ptr = &num,
    };

    // 深度复制（注意：指针会被复制，但指向同一内存）
    const copied = lifetime.deepCopy(WithPointer, original);

    std.debug.print("original.value: {}\n", .{original.value});
    std.debug.print("copied.value: {}\n", .{copied.value});
    std.debug.print("original.ptr == copied.ptr: {}\n", .{original.ptr == copied.ptr});

    // 修改原始值
    original.ptr.* = 100;
    std.debug.print("修改后 original.ptr.*: {}\n", .{original.ptr.*});
    std.debug.print("修改后 copied.ptr.*: {}\n", .{copied.ptr.*}); // 指向同一内存

    std.debug.print("\n", .{});
}

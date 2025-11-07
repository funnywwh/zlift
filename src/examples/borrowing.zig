const std = @import("std");
const lifetime = @import("lifetime");

/// 不可变借用示例
pub fn immutableBorrowExample() void {
    std.debug.print("=== 不可变借用示例 ===\n", .{});

    var owned_val = lifetime.owned(i32, 50);

    // 创建不可变借用
    var borrow1 = owned_val.borrow();
    var borrow2 = owned_val.borrow(); // 可以创建多个不可变借用

    std.debug.print("原始值: {}\n", .{owned_val.value});
    std.debug.print("借用1的值: {}\n", .{borrow1.deref()});
    std.debug.print("借用2的值: {}\n", .{borrow2.deref()});

    // 释放借用
    borrow1.release();
    borrow2.release();

    // 现在可以移动或修改值
    owned_val.value = 100;
    std.debug.print("修改后的值: {}\n", .{owned_val.value});

    std.debug.print("\n", .{});
}

/// 可变借用示例
pub fn mutableBorrowExample() void {
    std.debug.print("=== 可变借用示例 ===\n", .{});

    var owned_val = lifetime.owned(i32, 75);

    // 创建可变借用
    var borrow_mut = owned_val.borrowMut();

    // 通过可变借用修改值
    borrow_mut.get().* = 150;
    std.debug.print("通过可变借用修改后的值: {}\n", .{borrow_mut.deref()});

    // 释放可变借用
    borrow_mut.release();

    std.debug.print("释放借用后的值: {}\n", .{owned_val.value});

    std.debug.print("\n", .{});
}

/// 借用规则示例
pub fn borrowRulesExample() void {
    std.debug.print("=== 借用规则示例 ===\n", .{});

    var owned_val = lifetime.owned(i32, 200);

    // 规则1: 可以有多个不可变借用
    var b1 = owned_val.borrow();
    var b2 = owned_val.borrow();
    std.debug.print("多个不可变借用: {}, {}\n", .{ b1.deref(), b2.deref() });
    b1.release();
    b2.release();

    // 规则2: 可变借用是独占的
    var b_mut = owned_val.borrowMut();
    b_mut.get().* = 300;
    std.debug.print("可变借用修改: {}\n", .{b_mut.deref()});
    b_mut.release();

    // 规则3: 不能在借用期间移动
    var b3 = owned_val.borrow();
    _ = b3.deref(); // 使用借用
    // 如果尝试移动，会在运行时 panic
    // const moved = owned_val.take(); // 这会导致 panic
    // 必须先释放借用
    b3.release();

    std.debug.print("\n", .{});
}

/// 使用辅助函数的示例
pub fn helperFunctionsExample() void {
    std.debug.print("=== 辅助函数示例 ===\n", .{});

    // 使用 owned() 创建
    var val = lifetime.owned(i32, 42);

    // 使用 borrow() 创建不可变借用
    var b = lifetime.borrow(i32, &val);
    std.debug.print("借用值: {}\n", .{b.deref()});
    b.release();

    // 使用 borrowMut() 创建可变借用
    var b_mut = lifetime.borrowMut(i32, &val);
    b_mut.get().* = 100;
    std.debug.print("可变借用修改: {}\n", .{b_mut.deref()});
    b_mut.release();

    std.debug.print("\n", .{});
}

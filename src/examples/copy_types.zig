const std = @import("std");
const lifetime = @import("lifetime");

/// 复制类型示例
pub fn copyTypesExample() void {
    std.debug.print("=== 复制类型示例 ===\n", .{});

    // 基本数值类型可以复制
    var int_val = lifetime.ownedCopy(i32, 42);
    std.debug.print("创建复制类型值: {}\n", .{int_val.value()});

    // 复制值（不转移所有权）
    const copied1 = int_val.copy();
    const copied2 = int_val.copy();
    std.debug.print("复制1: {}, 复制2: {}\n", .{ copied1, copied2 });
    std.debug.print("原值仍然有效: {}\n", .{int_val.value()});

    // 浮点数
    var float_val = lifetime.ownedCopy(f64, 3.14);
    std.debug.print("浮点数: {d}\n", .{float_val.value()});
    const copied_float = float_val.copy();
    std.debug.print("复制的浮点数: {d}\n", .{copied_float});

    // 布尔值
    var bool_val = lifetime.ownedCopy(bool, true);
    std.debug.print("布尔值: {}\n", .{bool_val.value()});
    const copied_bool = bool_val.copy();
    std.debug.print("复制的布尔值: {}\n", .{copied_bool});

    std.debug.print("\n", .{});
}

/// 复制类型与移动类型对比
pub fn copyVsMoveExample() void {
    std.debug.print("=== 复制类型 vs 移动类型 ===\n", .{});

    // 复制类型：可以多次复制
    var copy_val = lifetime.ownedCopy(i32, 100);
    const c1 = copy_val.copy();
    const c2 = copy_val.copy();
    const c3 = copy_val.copy();
    std.debug.print("复制类型可以多次复制: {}, {}, {}\n", .{ c1, c2, c3 });
    std.debug.print("原值仍然可用: {}\n", .{copy_val.value()});

    // 移动类型：只能移动一次
    var move_val = lifetime.owned(i32, 200);
    const m1 = move_val.take();
    std.debug.print("移动类型只能移动一次: {}\n", .{m1});
    // move_val 现在已失效，不能再使用

    std.debug.print("\n", .{});
}

/// 复制类型在函数参数中的使用
fn processCopyValue(val: lifetime.OwnedCopy(i32)) i32 {
    const copied = val.copy();
    return copied * 2;
}

pub fn copyInFunctionsExample() void {
    std.debug.print("=== 复制类型在函数中的使用 ===\n", .{});

    var val = lifetime.ownedCopy(i32, 50);
    const result = processCopyValue(val);
    std.debug.print("处理结果: {}\n", .{result});
    // val 仍然有效，因为使用的是复制语义
    std.debug.print("原值仍然有效: {}\n", .{val.value()});

    std.debug.print("\n", .{});
}

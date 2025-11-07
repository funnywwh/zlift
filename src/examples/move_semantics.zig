const std = @import("std");
const lifetime = @import("lifetime");

/// 移动语义示例
pub fn run() void {
    std.debug.print("=== 移动语义示例 ===\n", .{});

    // 创建一个拥有所有权的值
    var owned_val = lifetime.Owned(i32).init(42);
    std.debug.print("创建 Owned 值: {}\n", .{owned_val.value});

    // 移动值（转移所有权）
    const moved_value = owned_val.take();
    std.debug.print("移动后的值: {}\n", .{moved_value});

    // 原值已失效，不能再使用
    // owned_val.value; // 这会导致编译错误或运行时错误

    // 使用辅助函数
    var val2 = lifetime.owned(i32, 100);
    const moved2 = lifetime.move(i32, &val2);
    std.debug.print("使用辅助函数移动: {}\n", .{moved2});

    std.debug.print("\n", .{});
}

/// 函数参数移动示例
fn takeOwnership(val: lifetime.Owned(i32)) i32 {
    var mut_val = val;
    return mut_val.take();
}

pub fn functionMoveExample() void {
    std.debug.print("=== 函数参数移动示例 ===\n", .{});

    const val = lifetime.owned(i32, 200);
    const result = takeOwnership(val);
    std.debug.print("函数移动后的值: {}\n", .{result});

    // val 已失效，不能再使用
    std.debug.print("\n", .{});
}

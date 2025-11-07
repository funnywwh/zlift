const std = @import("std");
const lifetime = @import("lifetime");

/// 生命周期管理综合示例
pub fn comprehensiveExample() void {
    std.debug.print("=== 生命周期管理综合示例 ===\n", .{});

    // 场景1: 基本所有权转移
    std.debug.print("场景1: 所有权转移\n", .{});
    var val1 = lifetime.owned(i32, 10);
    const moved = lifetime.move(i32, &val1);
    std.debug.print("  移动后的值: {}\n", .{moved});

    // 场景2: 借用链
    std.debug.print("场景2: 借用链\n", .{});
    var val2 = lifetime.owned(i32, 20);
    {
        var b1 = val2.borrow();
        {
            var b2 = val2.borrow();
            std.debug.print("  嵌套借用: {}, {}\n", .{ b1.deref(), b2.deref() });
            b2.release();
        }
        b1.release();
    }
    // 借用释放后可以继续使用
    val2.value = 30;
    std.debug.print("  借用释放后修改: {}\n", .{val2.value});

    // 场景3: 可变借用修改
    std.debug.print("场景3: 可变借用修改\n", .{});
    var val3 = lifetime.owned(i32, 40);
    {
        var b_mut = val3.borrowMut();
        b_mut.get().* = 50;
        std.debug.print("  可变借用修改: {}\n", .{b_mut.deref()});
        b_mut.release();
    }
    std.debug.print("  释放后查看: {}\n", .{val3.value});

    std.debug.print("\n", .{});
}

/// 复杂数据结构示例
pub fn complexDataExample() void {
    std.debug.print("=== 复杂数据结构示例 ===\n", .{});

    // 字符串所有权
    const str = lifetime.owned([]const u8, "Hello, World!");
    std.debug.print("字符串: {s}\n", .{str.value});

    // 数组所有权
    const arr = lifetime.owned([3]i32, .{ 1, 2, 3 });
    std.debug.print("数组: {any}\n", .{arr.value});

    // 结构体所有权
    const Point = struct {
        x: i32,
        y: i32,
    };

    var point = lifetime.owned(Point, .{ .x = 10, .y = 20 });
    std.debug.print("点: ({}, {})\n", .{ point.value.x, point.value.y });

    // 通过可变借用修改结构体
    var b_mut = point.borrowMut();
    b_mut.get().x = 100;
    b_mut.get().y = 200;
    std.debug.print("修改后的点: ({}, {})\n", .{ b_mut.get().x, b_mut.get().y });
    b_mut.release();

    std.debug.print("\n", .{});
}

/// 函数间传递示例
fn processValue(val: *lifetime.Owned(i32)) void {
    var b_mut = val.borrowMut();
    b_mut.get().* *= 2;
    b_mut.release();
}

fn readValue(val: *lifetime.Owned(i32)) i32 {
    var b = val.borrow();
    const result = b.deref();
    b.release();
    return result;
}

pub fn functionPassingExample() void {
    std.debug.print("=== 函数间传递示例 ===\n", .{});

    var val = lifetime.owned(i32, 5);
    std.debug.print("初始值: {}\n", .{val.value});

    // 通过引用传递，可以借用
    processValue(&val);
    std.debug.print("处理后的值: {}\n", .{val.value});

    // 读取值
    const read = readValue(&val);
    std.debug.print("读取的值: {}\n", .{read});

    std.debug.print("\n", .{});
}

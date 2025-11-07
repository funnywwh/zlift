const std = @import("std");
const lifetime = @import("lifetime");

// 导入示例模块
const move_semantics = @import("examples/move_semantics.zig");
const borrowing = @import("examples/borrowing.zig");
const lifetime_examples = @import("examples/lifetime_examples.zig");
const copy_types = @import("examples/copy_types.zig");
const nested_types = @import("examples/nested_types.zig");
const deep_copy = @import("examples/deep_copy.zig");
const pointer_usage = @import("examples/pointer_usage.zig");
const owned_deep_copy = @import("examples/owned_deep_copy.zig");

pub fn main() !void {
    std.debug.print("Zig 生命周期管理系统示例\n", .{});
    std.debug.print("========================\n\n", .{});

    // 运行移动语义示例
    move_semantics.run();
    move_semantics.functionMoveExample();

    // 运行借用示例
    borrowing.immutableBorrowExample();
    borrowing.mutableBorrowExample();
    borrowing.borrowRulesExample();
    borrowing.helperFunctionsExample();

    // 运行生命周期示例
    lifetime_examples.comprehensiveExample();
    lifetime_examples.complexDataExample();
    lifetime_examples.functionPassingExample();

    // 运行复制类型示例
    copy_types.copyTypesExample();
    copy_types.copyVsMoveExample();
    copy_types.copyInFunctionsExample();

    // 运行嵌套类型示例
    nested_types.nestedStructExample();
    nested_types.deeplyNestedExample();
    nested_types.structWithArrayExample();
    nested_types.structInStructExample();

    // 运行深度复制示例
    deep_copy.simpleStructDeepCopy();
    deep_copy.nestedStructDeepCopy();
    deep_copy.arrayDeepCopy();
    deep_copy.nestedArrayDeepCopy();
    deep_copy.ownedDeepCopyExample();
    deep_copy.complexNestedDeepCopy();

    // 运行指针使用示例
    pointer_usage.pointerWithOwnedExample();
    pointer_usage.structWithPointerExample();
    pointer_usage.ownedWithPointerExample();
    pointer_usage.pointerArrayExample();
    pointer_usage.nestedPointerOwnedExample();
    pointer_usage.pointerInFunctionExample();
    pointer_usage.pointerBorrowCheckExample();
    pointer_usage.multiLevelPointerExample();
    pointer_usage.pointerDeepCopyExample();

    // 运行 Owned 深度复制示例
    owned_deep_copy.structWithOwnedDeepCopy();
    owned_deep_copy.nestedStructWithOwnedDeepCopy();
    owned_deep_copy.structWithOwnedArrayDeepCopy();
    owned_deep_copy.mixedTypesDeepCopy();
    owned_deep_copy.ownedCloneExample();

    std.debug.print("所有示例运行完成！\n", .{});
}

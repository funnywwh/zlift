const std = @import("std");
const lifetime = @import("lifetime");

/// 循环引用问题演示
pub fn circularReferenceProblem() void {
    std.debug.print("=== 循环引用问题演示 ===\n", .{});

    std.debug.print("问题：两个节点相互引用会导致无法释放\n", .{});
    std.debug.print("解决方案：\n", .{});
    std.debug.print("1. 使用弱引用（Weak references）\n", .{});
    std.debug.print("2. 使用索引而不是直接指针\n", .{});
    std.debug.print("3. 重新设计数据结构，避免循环\n", .{});
    std.debug.print("4. 使用单向引用，而不是双向引用\n\n", .{});
}

/// 解决方案 1: 使用索引而不是直接引用
pub fn solutionUsingIndices() void {
    std.debug.print("=== 解决方案 1: 使用索引而不是直接引用 ===\n", .{});

    const Node = struct {
        name: lifetime.Owned([]const u8),
        next_index: ?usize = null,
    };

    // 使用固定大小数组存储节点，通过索引引用
    var nodes: [2]Node = undefined;

    // 创建节点
    nodes[0] = Node{
        .name = lifetime.owned([]const u8, "Node1"),
        .next_index = null,
    };

    nodes[1] = Node{
        .name = lifetime.owned([]const u8, "Node2"),
        .next_index = 0, // 引用第一个节点
    };

    // 更新第一个节点指向第二个
    nodes[0].next_index = 1;

    std.debug.print("节点结构:\n", .{});
    for (nodes, 0..) |node, i| {
        std.debug.print("  Node[{}]: {s}\n", .{ i, node.name.value });
        if (node.next_index) |next| {
            std.debug.print("    -> Node[{}]\n", .{next});
        }
    }

    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 没有循环引用问题\n", .{});
    std.debug.print("- 可以安全释放所有节点\n", .{});
    std.debug.print("- 通过索引访问，避免悬垂指针\n\n", .{});
}

/// 解决方案 2: 使用单向引用（树形结构）
pub fn solutionUsingTreeStructure() void {
    std.debug.print("=== 解决方案 2: 使用树形结构（单向引用）===\n", .{});

    const TreeNode = struct {
        name: lifetime.Owned([]const u8),
        children: [2]*@This(),
        child_count: usize,

        fn init(name: []const u8) @This() {
            return @This(){
                .name = lifetime.owned([]const u8, name),
                .children = undefined,
                .child_count = 0,
            };
        }
    };

    // 创建树形结构（使用固定大小数组）
    var root = TreeNode.init("Root");
    var child1 = TreeNode.init("Child1");
    var child2 = TreeNode.init("Child2");

    // 父节点引用子节点（单向）
    root.children[0] = &child1;
    root.children[1] = &child2;
    root.child_count = 2;

    std.debug.print("树形结构:\n", .{});
    std.debug.print("  {s}\n", .{root.name.value});
    for (root.children[0..root.child_count]) |child| {
        std.debug.print("    - {s}\n", .{child.name.value});
    }

    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 没有循环引用\n", .{});
    std.debug.print("- 清晰的父子关系\n", .{});
    std.debug.print("- 易于遍历和释放\n\n", .{});
}

/// 解决方案 3: 使用弱引用（Weak references）
pub fn solutionUsingWeakReferences() void {
    std.debug.print("=== 解决方案 3: 使用弱引用 ===\n", .{});

    var owned_val = lifetime.owned(i32, 100);

    // 创建弱引用（不持有所有权）
    var weak_ref = lifetime.weak(i32, owned_val.get());
    std.debug.print("创建弱引用指向值: {}\n", .{owned_val.get().*});

    // 尝试升级为强引用
    if (weak_ref.upgrade()) |ptr| {
        std.debug.print("弱引用升级成功，值: {}\n", .{ptr.*});
    }

    // 弱引用不会阻止对象移动
    const moved = owned_val.take();
    std.debug.print("移动值: {}\n", .{moved});

    // 注意：弱引用仍然持有指针，但对象已移动
    // 实际应用中需要更复杂的机制来检测对象是否已释放
    std.debug.print("弱引用仍然存在，但对象已移动\n", .{});
    std.debug.print("需要手动清空弱引用\n", .{});
    weak_ref.clear();

    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 不会阻止对象释放\n", .{});
    std.debug.print("- 可以打破循环引用\n", .{});
    std.debug.print("- 需要手动管理生命周期\n\n", .{});
}

/// 解决方案 4: 重新设计数据结构
pub fn solutionRedesignDataStructure() void {
    std.debug.print("=== 解决方案 4: 重新设计数据结构 ===\n", .{});

    std.debug.print("示例：将双向链表改为单向链表\n\n", .{});

    std.debug.print("单向链表：\n", .{});
    std.debug.print("  Node1 -> Node2 -> Node3 -> null\n", .{});
    std.debug.print("  优点：没有循环，可以安全释放\n\n", .{});

    std.debug.print("如果必须使用双向引用，考虑：\n", .{});
    std.debug.print("1. 使用索引而不是指针\n", .{});
    std.debug.print("2. 使用弱引用（Weak）\n", .{});
    std.debug.print("3. 手动管理生命周期，确保释放顺序\n\n", .{});
}

/// 最佳实践总结
pub fn bestPractices() void {
    std.debug.print("=== 避免循环引用的最佳实践 ===\n", .{});

    std.debug.print("1. 优先使用单向引用\n", .{});
    std.debug.print("   - 树形结构\n", .{});
    std.debug.print("   - 单向链表\n", .{});
    std.debug.print("   - 有向无环图（DAG）\n\n", .{});

    std.debug.print("2. 使用索引而不是指针\n", .{});
    std.debug.print("   - 将对象存储在数组中\n", .{});
    std.debug.print("   - 使用索引引用其他对象\n", .{});
    std.debug.print("   - 避免直接指针引用\n\n", .{});

    std.debug.print("3. 使用弱引用（Weak）\n", .{});
    std.debug.print("   - 当需要双向引用时\n", .{});
    std.debug.print("   - 弱引用不会阻止对象释放\n", .{});
    std.debug.print("   - 需要检查弱引用是否仍然有效\n\n", .{});

    std.debug.print("4. 重新设计数据结构\n", .{});
    std.debug.print("   - 分析是否真的需要循环引用\n", .{});
    std.debug.print("   - 考虑使用事件系统或观察者模式\n", .{});
    std.debug.print("   - 使用回调函数而不是直接引用\n\n", .{});

    std.debug.print("5. 手动管理生命周期\n", .{});
    std.debug.print("   - 明确释放顺序\n", .{});
    std.debug.print("   - 使用 Arena 分配器统一管理\n", .{});
    std.debug.print("   - 在释放前断开循环引用\n\n", .{});
}

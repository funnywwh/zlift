const std = @import("std");
const lifetime = @import("lifetime");

/// 内存泄漏问题演示
pub fn memoryLeakProblem() void {
    std.debug.print("=== 内存泄漏问题演示 ===\n", .{});

    std.debug.print("常见的内存泄漏场景：\n", .{});
    std.debug.print("1. 忘记释放借用\n", .{});
    std.debug.print("2. 循环引用导致无法释放\n", .{});
    std.debug.print("3. 移动后忘记清理\n", .{});
    std.debug.print("4. 动态分配的内存未释放\n", .{});
    std.debug.print("5. 异常路径未释放资源\n\n", .{});
}

/// 解决方案 1: 使用 defer 确保释放
pub fn solutionUsingDefer() void {
    std.debug.print("=== 解决方案 1: 使用 defer 确保释放 ===\n", .{});

    var owned_val = lifetime.owned(i32, 100);

    // ✅ 正确：使用 defer 确保释放
    {
        var borrow = owned_val.borrow();
        defer borrow.release(); // 确保在作用域结束时释放

        std.debug.print("使用借用: {}\n", .{borrow.deref()});
        // 即使这里发生错误或提前返回，defer 也会执行
    }

    // 借用已释放，可以继续使用
    std.debug.print("借用已释放，值仍然有效: {}\n", .{owned_val.get().*});

    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 自动释放，即使发生错误\n", .{});
    std.debug.print("- 代码更安全\n", .{});
    std.debug.print("- 符合 Zig 的最佳实践\n\n", .{});
}

/// 解决方案 2: 使用 Arena 分配器统一管理
pub fn solutionUsingArena() void {
    std.debug.print("=== 解决方案 2: 使用 Arena 分配器统一管理 ===\n", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // 释放所有在 Arena 中分配的内存

    const allocator = arena.allocator();

    // 在 Arena 中创建多个 Owned 值
    const Person = struct {
        name: lifetime.Owned([]const u8),
        age: lifetime.Owned(i32),
    };

    // 注意：这里需要分配内存来存储字符串
    // 使用 Arena 分配器确保所有内存一起释放
    const name1 = allocator.dupe(u8, "Alice") catch return;
    const name2 = allocator.dupe(u8, "Bob") catch return;

    const person1 = Person{
        .name = lifetime.owned([]const u8, name1),
        .age = lifetime.owned(i32, 30),
    };

    const person2 = Person{
        .name = lifetime.owned([]const u8, name2),
        .age = lifetime.owned(i32, 25),
    };

    std.debug.print("Person1: {s}, {}\n", .{ person1.name.value, person1.age.value });
    std.debug.print("Person2: {s}, {}\n", .{ person2.name.value, person2.age.value });

    // Arena 释放时，所有内存一起释放
    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 统一管理，无需逐个释放\n", .{});
    std.debug.print("- 避免部分释放问题\n", .{});
    std.debug.print("- 简化内存管理\n\n", .{});
}

/// 解决方案 3: 使用作用域管理生命周期
pub fn solutionUsingScope() void {
    std.debug.print("=== 解决方案 3: 使用作用域管理生命周期 ===\n", .{});

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
    std.debug.print("所有借用已释放\n", .{});

    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 清晰的生命周期管理\n", .{});
    std.debug.print("- 借用自动释放\n", .{});
    std.debug.print("- 避免忘记释放\n\n", .{});
}

/// 解决方案 4: 使用 RAII 模式
pub fn solutionUsingRAII() void {
    std.debug.print("=== 解决方案 4: 使用 RAII 模式 ===\n", .{});

    // RAII (Resource Acquisition Is Initialization)
    // 资源获取即初始化，资源释放在析构时

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

    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 资源自动管理\n", .{});
    std.debug.print("- 异常安全\n", .{});
    std.debug.print("- 符合 RAII 原则\n\n", .{});
}

/// 解决方案 5: 避免循环引用
pub fn solutionAvoidCircularReference() void {
    std.debug.print("=== 解决方案 5: 避免循环引用 ===\n", .{});

    std.debug.print("循环引用会导致内存泄漏，因为对象无法被释放\n", .{});
    std.debug.print("解决方案：\n", .{});
    std.debug.print("1. 使用索引而不是指针\n", .{});
    std.debug.print("2. 使用弱引用（Weak）\n", .{});
    std.debug.print("3. 使用单向引用\n", .{});
    std.debug.print("4. 重新设计数据结构\n\n", .{});
    std.debug.print("详细内容请参考 CIRCULAR_REFERENCE.md\n\n", .{});
}

/// 解决方案 6: 检查资源泄漏
pub fn solutionCheckLeaks() void {
    std.debug.print("=== 解决方案 6: 检查资源泄漏 ===\n", .{});

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
    std.debug.print("移动的值: {}\n", .{moved});

    std.debug.print("\n优点：\n", .{});
    std.debug.print("- 可以检查资源状态\n", .{});
    std.debug.print("- 及时发现泄漏问题\n", .{});
    std.debug.print("- 调试更容易\n\n", .{});
}

/// 最佳实践总结
pub fn bestPractices() void {
    std.debug.print("=== 避免内存泄漏的最佳实践 ===\n", .{});

    std.debug.print("1. 总是使用 defer 释放资源\n", .{});
    std.debug.print("   var borrow = owned_val.borrow();\n", .{});
    std.debug.print("   defer borrow.release();\n\n", .{});

    std.debug.print("2. 使用 Arena 分配器统一管理\n", .{});
    std.debug.print("   var arena = ArenaAllocator.init(...);\n", .{});
    std.debug.print("   defer arena.deinit();\n\n", .{});

    std.debug.print("3. 使用作用域限制生命周期\n", .{});
    std.debug.print("   {{\n", .{});
    std.debug.print("       var borrow = ...;\n", .{});
    std.debug.print("       defer borrow.release();\n", .{});
    std.debug.print("   }}\n\n", .{});

    std.debug.print("4. 避免循环引用\n", .{});
    std.debug.print("   - 使用索引而不是指针\n", .{});
    std.debug.print("   - 使用弱引用（Weak）\n", .{});
    std.debug.print("   - 使用单向引用\n\n", .{});

    std.debug.print("5. 检查资源状态\n", .{});
    std.debug.print("   if (owned_val.isValid()) {{ ... }}\n\n", .{});

    std.debug.print("6. 使用 RAII 模式\n", .{});
    std.debug.print("   - 资源获取即初始化\n", .{});
    std.debug.print("   - 资源释放在析构时\n\n", .{});

    std.debug.print("7. 测试和验证\n", .{});
    std.debug.print("   - 使用内存检查工具\n", .{});
    std.debug.print("   - 检查资源泄漏\n", .{});
    std.debug.print("   - 验证所有路径都正确释放\n\n", .{});
}

const std = @import("std");
const lifetime = @import("lifetime");

/// 简单结构体的深度复制
pub fn simpleStructDeepCopy() void {
    std.debug.print("=== 简单结构体深度复制 ===\n", .{});

    const Point = struct {
        x: i32,
        y: i32,
    };

    const point = Point{ .x = 10, .y = 20 };
    const copied = lifetime.deepCopy(Point, point);

    std.debug.print("原始点: ({}, {})\n", .{ point.x, point.y });
    std.debug.print("复制的点: ({}, {})\n", .{ copied.x, copied.y });

    // 修改复制的点不影响原始点
    var mut_copied = copied;
    mut_copied.x = 100;
    std.debug.print("修改后的复制点: ({}, {})\n", .{ mut_copied.x, mut_copied.y });
    std.debug.print("原始点不变: ({}, {})\n", .{ point.x, point.y });

    std.debug.print("\n", .{});
}

/// 嵌套结构体的深度复制
pub fn nestedStructDeepCopy() void {
    std.debug.print("=== 嵌套结构体深度复制 ===\n", .{});

    const Point = struct {
        x: i32,
        y: i32,
    };

    const Rectangle = struct {
        top_left: Point,
        bottom_right: Point,
        area: i32,
    };

    const rect = Rectangle{
        .top_left = Point{ .x = 0, .y = 0 },
        .bottom_right = Point{ .x = 100, .y = 100 },
        .area = 10000,
    };

    const copied = lifetime.deepCopy(Rectangle, rect);

    std.debug.print("原始矩形:\n", .{});
    std.debug.print("  top_left: ({}, {})\n", .{ rect.top_left.x, rect.top_left.y });
    std.debug.print("  bottom_right: ({}, {})\n", .{ rect.bottom_right.x, rect.bottom_right.y });
    std.debug.print("  area: {}\n", .{rect.area});

    std.debug.print("复制的矩形:\n", .{});
    std.debug.print("  top_left: ({}, {})\n", .{ copied.top_left.x, copied.top_left.y });
    std.debug.print("  bottom_right: ({}, {})\n", .{ copied.bottom_right.x, copied.bottom_right.y });
    std.debug.print("  area: {}\n", .{copied.area});

    // 修改复制的矩形
    var mut_copied = copied;
    mut_copied.top_left.x = 10;
    mut_copied.top_left.y = 20;
    std.debug.print("修改后的复制矩形 top_left: ({}, {})\n", .{ mut_copied.top_left.x, mut_copied.top_left.y });
    std.debug.print("原始矩形 top_left 不变: ({}, {})\n", .{ rect.top_left.x, rect.top_left.y });

    std.debug.print("\n", .{});
}

/// 数组的深度复制
pub fn arrayDeepCopy() void {
    std.debug.print("=== 数组深度复制 ===\n", .{});

    const arr: [5]i32 = .{ 1, 2, 3, 4, 5 };
    const copied = lifetime.deepCopy([5]i32, arr);

    std.debug.print("原始数组: {any}\n", .{arr});
    std.debug.print("复制的数组: {any}\n", .{copied});

    // 修改复制的数组
    var mut_copied = copied;
    mut_copied[0] = 100;
    std.debug.print("修改后的复制数组: {any}\n", .{mut_copied});
    std.debug.print("原始数组不变: {any}\n", .{arr});

    std.debug.print("\n", .{});
}

/// 嵌套数组的深度复制
pub fn nestedArrayDeepCopy() void {
    std.debug.print("=== 嵌套数组深度复制 ===\n", .{});

    const Matrix = struct {
        data: [3][3]i32,
    };

    const matrix = Matrix{
        .data = .{
            .{ 1, 2, 3 },
            .{ 4, 5, 6 },
            .{ 7, 8, 9 },
        },
    };

    const copied = lifetime.deepCopy(Matrix, matrix);

    std.debug.print("原始矩阵:\n", .{});
    for (matrix.data) |row| {
        std.debug.print("  {any}\n", .{row});
    }

    std.debug.print("复制的矩阵:\n", .{});
    for (copied.data) |row| {
        std.debug.print("  {any}\n", .{row});
    }

    // 修改复制的矩阵
    var mut_copied = copied;
    mut_copied.data[0][0] = 100;
    std.debug.print("修改后的复制矩阵[0][0]: {}\n", .{mut_copied.data[0][0]});
    std.debug.print("原始矩阵[0][0]不变: {}\n", .{matrix.data[0][0]});

    std.debug.print("\n", .{});
}

/// 使用 OwnedDeepCopy 包装器
pub fn ownedDeepCopyExample() void {
    std.debug.print("=== OwnedDeepCopy 包装器示例 ===\n", .{});

    const Person = struct {
        name: []const u8,
        age: i32,
        scores: [3]i32,
    };

    const person = Person{
        .name = "David",
        .age = 25,
        .scores = .{ 90, 85, 95 },
    };

    var owned_person = lifetime.ownedDeepCopy(Person, person);

    std.debug.print("原始 Person: {s}, age={}, scores={any}\n", .{ person.name, person.age, person.scores });

    // 深度复制
    const copied = owned_person.deepCopyValue();
    std.debug.print("深度复制的 Person: {s}, age={}, scores={any}\n", .{ copied.name, copied.age, copied.scores });

    // 可以多次深度复制
    const copied2 = owned_person.deepCopyValue();
    std.debug.print("再次深度复制: {s}, age={}\n", .{ copied2.name, copied2.age });

    // 原值仍然有效
    std.debug.print("原值仍然有效: {s}\n", .{owned_person.value().name});

    std.debug.print("\n", .{});
}

/// 复杂嵌套结构体的深度复制
pub fn complexNestedDeepCopy() void {
    std.debug.print("=== 复杂嵌套结构体深度复制 ===\n", .{});

    const Address = struct {
        street: []const u8,
        city: []const u8,
        zip: i32,
    };

    const Contact = struct {
        email: []const u8,
        phone: []const u8,
    };

    const Employee = struct {
        name: []const u8,
        age: i32,
        address: Address,
        contact: Contact,
        skills: [3][]const u8,
    };

    const employee = Employee{
        .name = "Eve",
        .age = 30,
        .address = Address{
            .street = "456 Oak Ave",
            .city = "Boston",
            .zip = 2101,
        },
        .contact = Contact{
            .email = "eve@example.com",
            .phone = "555-5678",
        },
        .skills = .{ "Rust", "Zig", "C++" },
    };

    const copied = lifetime.deepCopy(Employee, employee);

    std.debug.print("原始 Employee:\n", .{});
    std.debug.print("  name: {s}, age: {}\n", .{ employee.name, employee.age });
    std.debug.print("  address: {s}, {s}, {}\n", .{ employee.address.street, employee.address.city, employee.address.zip });
    std.debug.print("  contact: {s}, {s}\n", .{ employee.contact.email, employee.contact.phone });

    std.debug.print("复制的 Employee:\n", .{});
    std.debug.print("  name: {s}, age: {}\n", .{ copied.name, copied.age });
    std.debug.print("  address: {s}, {s}, {}\n", .{ copied.address.street, copied.address.city, copied.address.zip });
    std.debug.print("  contact: {s}, {s}\n", .{ copied.contact.email, copied.contact.phone });

    std.debug.print("\n", .{});
}

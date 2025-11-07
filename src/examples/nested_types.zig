const std = @import("std");
const lifetime = @import("lifetime");

/// 嵌套结构体示例：结构体包含 Owned 值
pub fn nestedStructExample() void {
    std.debug.print("=== 嵌套结构体示例 ===\n", .{});

    // 定义包含 Owned 值的结构体
    const Person = struct {
        name: lifetime.Owned([]const u8),
        age: lifetime.Owned(i32),
    };

    // 创建嵌套结构体
    var person = Person{
        .name = lifetime.owned([]const u8, "Alice"),
        .age = lifetime.owned(i32, 30),
    };

    std.debug.print("创建 Person: name={s}, age={}\n", .{ person.name.value, person.age.value });

    // 访问嵌套的 Owned 值
    var name_borrow = person.name.borrow();
    std.debug.print("借用 name: {s}\n", .{name_borrow.deref()});
    name_borrow.release();

    // 移动嵌套的 Owned 值
    const moved_age = person.age.take();
    std.debug.print("移动 age: {}\n", .{moved_age});
    // person.age 现在已失效

    std.debug.print("\n", .{});
}

/// 深度嵌套结构体示例
pub fn deeplyNestedExample() void {
    std.debug.print("=== 深度嵌套结构体示例 ===\n", .{});

    // 定义多层嵌套结构体
    const Address = struct {
        street: lifetime.Owned([]const u8),
        city: lifetime.Owned([]const u8),
        zip: lifetime.Owned(i32),
    };

    const Contact = struct {
        email: lifetime.Owned([]const u8),
        phone: lifetime.Owned([]const u8),
    };

    const Employee = struct {
        name: lifetime.Owned([]const u8),
        address: Address,
        contact: Contact,
        salary: lifetime.Owned(f64),
    };

    // 创建深度嵌套结构体
    var employee = Employee{
        .name = lifetime.owned([]const u8, "Bob"),
        .address = Address{
            .street = lifetime.owned([]const u8, "123 Main St"),
            .city = lifetime.owned([]const u8, "New York"),
            .zip = lifetime.owned(i32, 10001),
        },
        .contact = Contact{
            .email = lifetime.owned([]const u8, "bob@example.com"),
            .phone = lifetime.owned([]const u8, "555-1234"),
        },
        .salary = lifetime.owned(f64, 75000.0),
    };

    std.debug.print("Employee: {s}\n", .{employee.name.value});
    std.debug.print("  Address: {s}, {s}, {}\n", .{ employee.address.street.value, employee.address.city.value, employee.address.zip.value });
    std.debug.print("  Contact: {s}, {s}\n", .{ employee.contact.email.value, employee.contact.phone.value });
    std.debug.print("  Salary: {d}\n", .{employee.salary.value});

    // 借用嵌套字段
    var street_borrow = employee.address.street.borrow();
    std.debug.print("借用 street: {s}\n", .{street_borrow.deref()});
    street_borrow.release();

    // 可变借用修改嵌套字段
    var salary_borrow = employee.salary.borrowMut();
    salary_borrow.get().* = 80000.0;
    std.debug.print("修改后的 salary: {d}\n", .{salary_borrow.deref()});
    salary_borrow.release();

    std.debug.print("\n", .{});
}

/// 结构体包含多个 Owned 值的数组
pub fn structWithArrayExample() void {
    std.debug.print("=== 结构体包含数组示例 ===\n", .{});

    const Student = struct {
        name: lifetime.Owned([]const u8),
        grades: lifetime.Owned([5]i32),
    };

    var student = Student{
        .name = lifetime.owned([]const u8, "Charlie"),
        .grades = lifetime.owned([5]i32, .{ 85, 90, 88, 92, 87 }),
    };

    std.debug.print("Student: {s}\n", .{student.name.value});
    std.debug.print("Grades: {any}\n", .{student.grades.value});

    // 修改数组中的值
    var grades_borrow = student.grades.borrowMut();
    grades_borrow.get()[0] = 95;
    std.debug.print("修改后的 grades: {any}\n", .{grades_borrow.get()});
    grades_borrow.release();

    std.debug.print("\n", .{});
}

/// 结构体包含结构体（非 Owned）
pub fn structInStructExample() void {
    std.debug.print("=== 结构体包含结构体示例 ===\n", .{});

    const Point = struct {
        x: i32,
        y: i32,
    };

    const Rectangle = struct {
        top_left: lifetime.Owned(Point),
        bottom_right: lifetime.Owned(Point),
        label: lifetime.Owned([]const u8),
    };

    var rect = Rectangle{
        .top_left = lifetime.owned(Point, .{ .x = 0, .y = 0 }),
        .bottom_right = lifetime.owned(Point, .{ .x = 100, .y = 100 }),
        .label = lifetime.owned([]const u8, "My Rectangle"),
    };

    std.debug.print("Rectangle: {s}\n", .{rect.label.value});
    std.debug.print("  Top-left: ({}, {})\n", .{ rect.top_left.value.x, rect.top_left.value.y });
    std.debug.print("  Bottom-right: ({}, {})\n", .{ rect.bottom_right.value.x, rect.bottom_right.value.y });

    // 修改嵌套结构体
    var top_left_borrow = rect.top_left.borrowMut();
    top_left_borrow.get().x = 10;
    top_left_borrow.get().y = 20;
    std.debug.print("修改后的 top-left: ({}, {})\n", .{ top_left_borrow.get().x, top_left_borrow.get().y });
    top_left_borrow.release();

    std.debug.print("\n", .{});
}

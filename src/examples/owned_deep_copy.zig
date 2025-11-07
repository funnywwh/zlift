const std = @import("std");
const lifetime = @import("lifetime");

/// 结构体包含 Owned 类型的深度复制
pub fn structWithOwnedDeepCopy() void {
    std.debug.print("=== 结构体包含 Owned 类型的深度复制 ===\n", .{});

    const Person = struct {
        name: lifetime.Owned([]const u8),
        age: lifetime.Owned(i32),
    };

    const person = Person{
        .name = lifetime.owned([]const u8, "Alice"),
        .age = lifetime.owned(i32, 30),
    };

    std.debug.print("原始 Person:\n", .{});
    std.debug.print("  name: {s}\n", .{person.name.value});
    std.debug.print("  age: {}\n", .{person.age.value});

    // 深度复制
    var copied = lifetime.deepCopy(Person, person);

    std.debug.print("复制的 Person:\n", .{});
    std.debug.print("  name: {s}\n", .{copied.name.value});
    std.debug.print("  age: {}\n", .{copied.age.value});

    // 修改复制的值
    // 注意：字符串是切片，不能直接修改，这里只是演示借用
    var copied_name_borrow = copied.name.borrow();
    std.debug.print("借用 name: {s}\n", .{copied_name_borrow.deref()});
    copied_name_borrow.release();

    var copied_age_borrow = copied.age.borrowMut();
    copied_age_borrow.get().* = 31;
    std.debug.print("修改后复制的 age: {}\n", .{copied_age_borrow.get().*});
    copied_age_borrow.release();

    // 原始值不变
    std.debug.print("原始 age 不变: {}\n", .{person.age.value});

    std.debug.print("\n", .{});
}

/// 嵌套结构体包含 Owned 类型
pub fn nestedStructWithOwnedDeepCopy() void {
    std.debug.print("=== 嵌套结构体包含 Owned 类型的深度复制 ===\n", .{});

    const Address = struct {
        street: lifetime.Owned([]const u8),
        city: lifetime.Owned([]const u8),
    };

    const Employee = struct {
        name: lifetime.Owned([]const u8),
        address: Address,
        salary: lifetime.Owned(f64),
    };

    const employee = Employee{
        .name = lifetime.owned([]const u8, "Bob"),
        .address = Address{
            .street = lifetime.owned([]const u8, "123 Main St"),
            .city = lifetime.owned([]const u8, "New York"),
        },
        .salary = lifetime.owned(f64, 75000.0),
    };

    std.debug.print("原始 Employee:\n", .{});
    std.debug.print("  name: {s}\n", .{employee.name.value});
    std.debug.print("  address.street: {s}\n", .{employee.address.street.value});
    std.debug.print("  address.city: {s}\n", .{employee.address.city.value});
    std.debug.print("  salary: {d}\n", .{employee.salary.value});

    // 深度复制
    var copied = lifetime.deepCopy(Employee, employee);

    std.debug.print("复制的 Employee:\n", .{});
    std.debug.print("  name: {s}\n", .{copied.name.value});
    std.debug.print("  address.street: {s}\n", .{copied.address.street.value});
    std.debug.print("  address.city: {s}\n", .{copied.address.city.value});
    std.debug.print("  salary: {d}\n", .{copied.salary.value});

    // 修改复制的值
    var salary_borrow = copied.salary.borrowMut();
    salary_borrow.get().* = 80000.0;
    std.debug.print("修改后复制的 salary: {d}\n", .{salary_borrow.get().*});
    salary_borrow.release();

    // 原始值不变
    std.debug.print("原始 salary 不变: {d}\n", .{employee.salary.value});

    std.debug.print("\n", .{});
}

/// 结构体包含 Owned 数组
pub fn structWithOwnedArrayDeepCopy() void {
    std.debug.print("=== 结构体包含 Owned 数组的深度复制 ===\n", .{});

    const Student = struct {
        name: lifetime.Owned([]const u8),
        grades: lifetime.Owned([3]i32),
    };

    const student = Student{
        .name = lifetime.owned([]const u8, "Charlie"),
        .grades = lifetime.owned([3]i32, .{ 85, 90, 88 }),
    };

    std.debug.print("原始 Student:\n", .{});
    std.debug.print("  name: {s}\n", .{student.name.value});
    std.debug.print("  grades: {any}\n", .{student.grades.value});

    // 深度复制
    var copied = lifetime.deepCopy(Student, student);

    std.debug.print("复制的 Student:\n", .{});
    std.debug.print("  name: {s}\n", .{copied.name.value});
    std.debug.print("  grades: {any}\n", .{copied.grades.value});

    // 修改复制的数组
    var grades_borrow = copied.grades.borrowMut();
    grades_borrow.get()[0] = 95;
    std.debug.print("修改后复制的 grades: {any}\n", .{grades_borrow.get()});
    grades_borrow.release();

    // 原始值不变
    std.debug.print("原始 grades 不变: {any}\n", .{student.grades.value});

    std.debug.print("\n", .{});
}

/// 混合类型：Owned 和普通字段
pub fn mixedTypesDeepCopy() void {
    std.debug.print("=== 混合类型深度复制 ===\n", .{});

    const Point = struct {
        x: i32,
        y: i32,
    };

    const Shape = struct {
        name: lifetime.Owned([]const u8),
        center: Point, // 普通字段
        area: lifetime.Owned(f64),
    };

    const shape = Shape{
        .name = lifetime.owned([]const u8, "Circle"),
        .center = Point{ .x = 10, .y = 20 },
        .area = lifetime.owned(f64, 314.16),
    };

    std.debug.print("原始 Shape:\n", .{});
    std.debug.print("  name: {s}\n", .{shape.name.value});
    std.debug.print("  center: ({}, {})\n", .{ shape.center.x, shape.center.y });
    std.debug.print("  area: {d}\n", .{shape.area.value});

    // 深度复制
    var copied = lifetime.deepCopy(Shape, shape);

    std.debug.print("复制的 Shape:\n", .{});
    std.debug.print("  name: {s}\n", .{copied.name.value});
    std.debug.print("  center: ({}, {})\n", .{ copied.center.x, copied.center.y });
    std.debug.print("  area: {d}\n", .{copied.area.value});

    // 修改复制的值
    copied.center.x = 100;
    copied.center.y = 200;
    std.debug.print("修改后复制的 center: ({}, {})\n", .{ copied.center.x, copied.center.y });

    var area_borrow = copied.area.borrowMut();
    area_borrow.get().* = 500.0;
    std.debug.print("修改后复制的 area: {d}\n", .{area_borrow.get().*});
    area_borrow.release();

    // 原始值不变
    std.debug.print("原始 center 不变: ({}, {})\n", .{ shape.center.x, shape.center.y });
    std.debug.print("原始 area 不变: {d}\n", .{shape.area.value});

    std.debug.print("\n", .{});
}

/// 使用 Owned 的 clone 方法
pub fn ownedCloneExample() void {
    std.debug.print("=== Owned 的 clone 方法 ===\n", .{});

    var owned_val = lifetime.owned(i32, 42);
    std.debug.print("原始 Owned 值: {}\n", .{owned_val.value});

    // 使用 clone 方法
    var cloned = owned_val.clone();
    std.debug.print("克隆的 Owned 值: {}\n", .{cloned.value});

    // 修改克隆的值
    var cloned_borrow = cloned.borrowMut();
    cloned_borrow.get().* = 100;
    std.debug.print("修改后克隆的值: {}\n", .{cloned_borrow.get().*});
    cloned_borrow.release();

    // 原始值不变
    std.debug.print("原始值不变: {}\n", .{owned_val.value});

    // 可以多次克隆
    const cloned2 = owned_val.clone();
    const cloned3 = owned_val.clone();
    std.debug.print("多次克隆: {}, {}\n", .{ cloned2.value, cloned3.value });

    std.debug.print("\n", .{});
}

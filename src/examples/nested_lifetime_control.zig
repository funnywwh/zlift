const std = @import("std");
const lifetime = @import("lifetime");

/// 嵌套结构体中 Owned 字段的生命周期控制
pub fn nestedOwnedLifetimeControl() void {
    std.debug.print("=== 嵌套结构体中 Owned 字段的生命周期控制 ===\n", .{});

    const Person = struct {
        name: lifetime.Owned([]const u8),
        age: lifetime.Owned(i32),
    };

    var person = Person{
        .name = lifetime.owned([]const u8, "Alice"),
        .age = lifetime.owned(i32, 30),
    };

    std.debug.print("1. 初始状态:\n", .{});
    std.debug.print("   name: {s}, age: {}\n", .{ person.name.value, person.age.value });
    std.debug.print("   name.isValid(): {}, age.isValid(): {}\n", .{ person.name.isValid(), person.age.isValid() });

    // 2. 借用嵌套字段
    std.debug.print("\n2. 借用嵌套字段:\n", .{});
    var name_borrow = person.name.borrow();
    var age_borrow = person.age.borrow();
    std.debug.print("   借用 name: {s}\n", .{name_borrow.deref()});
    std.debug.print("   借用 age: {}\n", .{age_borrow.deref()});
    std.debug.print("   name.isValid(): {} (借用中)\n", .{person.name.isValid()});

    // 3. 释放借用
    name_borrow.release();
    age_borrow.release();
    std.debug.print("   释放借用后 name.isValid(): {}\n", .{person.name.isValid()});

    // 4. 移动嵌套字段
    std.debug.print("\n3. 移动嵌套字段:\n", .{});
    const moved_age = person.age.take();
    std.debug.print("   移动 age: {}\n", .{moved_age});
    std.debug.print("   age.isValid(): {} (已移动)\n", .{person.age.isValid()});
    // person.age 现在已失效，不能再使用

    // 5. 可变借用修改嵌套字段
    std.debug.print("\n4. 可变借用修改嵌套字段:\n", .{});
    var name_mut_borrow = person.name.borrow();
    // 注意：字符串切片不能修改，这里只是演示借用
    std.debug.print("   借用 name: {s}\n", .{name_mut_borrow.deref()});
    name_mut_borrow.release();

    std.debug.print("\n", .{});
}

/// 深度嵌套结构体的生命周期控制
pub fn deeplyNestedLifetimeControl() void {
    std.debug.print("=== 深度嵌套结构体的生命周期控制 ===\n", .{});

    const Address = struct {
        street: lifetime.Owned([]const u8),
        city: lifetime.Owned([]const u8),
    };

    const Employee = struct {
        name: lifetime.Owned([]const u8),
        address: Address,
        salary: lifetime.Owned(f64),
    };

    var employee = Employee{
        .name = lifetime.owned([]const u8, "Bob"),
        .address = Address{
            .street = lifetime.owned([]const u8, "123 Main St"),
            .city = lifetime.owned([]const u8, "New York"),
        },
        .salary = lifetime.owned(f64, 75000.0),
    };

    std.debug.print("1. 初始状态:\n", .{});
    std.debug.print("   name: {s}\n", .{employee.name.value});
    std.debug.print("   address.street: {s}\n", .{employee.address.street.value});
    std.debug.print("   address.city: {s}\n", .{employee.address.city.value});
    std.debug.print("   salary: {d}\n", .{employee.salary.value});

    // 2. 借用深度嵌套字段
    std.debug.print("\n2. 借用深度嵌套字段:\n", .{});
    var street_borrow = employee.address.street.borrow();
    var city_borrow = employee.address.city.borrow();
    std.debug.print("   借用 street: {s}\n", .{street_borrow.deref()});
    std.debug.print("   借用 city: {s}\n", .{city_borrow.deref()});

    // 3. 在借用期间，不能移动
    // 如果尝试移动，会在运行时 panic
    // const moved_street = employee.address.street.take(); // 这会导致 panic

    street_borrow.release();
    city_borrow.release();

    // 4. 释放借用后可以移动
    std.debug.print("\n3. 释放借用后移动字段:\n", .{});
    const moved_street = employee.address.street.take();
    std.debug.print("   移动 street: {s}\n", .{moved_street});
    std.debug.print("   address.street.isValid(): {}\n", .{employee.address.street.isValid()});

    // 5. 可变借用修改嵌套字段
    std.debug.print("\n4. 可变借用修改嵌套字段:\n", .{});
    var salary_borrow = employee.salary.borrowMut();
    salary_borrow.get().* = 80000.0;
    std.debug.print("   修改后 salary: {d}\n", .{salary_borrow.get().*});
    salary_borrow.release();
    std.debug.print("   释放后 salary: {d}\n", .{employee.salary.value});

    std.debug.print("\n", .{});
}

/// 嵌套结构体的移动语义
pub fn nestedStructMoveSemantics() void {
    std.debug.print("=== 嵌套结构体的移动语义 ===\n", .{});

    const Container = struct {
        data: lifetime.Owned(i32),
        label: lifetime.Owned([]const u8),
    };

    var container1 = Container{
        .data = lifetime.owned(i32, 42),
        .label = lifetime.owned([]const u8, "Container1"),
    };

    std.debug.print("1. 创建 container1:\n", .{});
    std.debug.print("   data: {}, label: {s}\n", .{ container1.data.value, container1.label.value });

    // 2. 移动整个结构体（结构体本身是值类型，会复制，但 Owned 字段会移动）
    std.debug.print("\n2. 移动结构体（值复制，但 Owned 字段移动）:\n", .{});
    // 注意：在 Zig 中，结构体赋值是复制，但我们可以移动其中的 Owned 字段
    const moved_data = container1.data.take();
    const moved_label = container1.label.take();
    std.debug.print("   移动 data: {}\n", .{moved_data});
    std.debug.print("   移动 label: {s}\n", .{moved_label});
    std.debug.print("   container1.data.isValid(): {}\n", .{container1.data.isValid()});
    std.debug.print("   container1.label.isValid(): {}\n", .{container1.label.isValid()});

    // 3. 创建新容器，使用移动的值
    std.debug.print("\n3. 创建新容器:\n", .{});
    const container2 = Container{
        .data = lifetime.owned(i32, moved_data),
        .label = lifetime.owned([]const u8, moved_label),
    };
    std.debug.print("   container2.data: {}, label: {s}\n", .{ container2.data.value, container2.label.value });

    std.debug.print("\n", .{});
}

/// 借用规则在嵌套结构体中的表现
pub fn borrowRulesInNestedStruct() void {
    std.debug.print("=== 借用规则在嵌套结构体中的表现 ===\n", .{});

    const Data = struct {
        value1: lifetime.Owned(i32),
        value2: lifetime.Owned(i32),
    };

    var data = Data{
        .value1 = lifetime.owned(i32, 10),
        .value2 = lifetime.owned(i32, 20),
    };

    std.debug.print("1. 多个不可变借用:\n", .{});
    var b1 = data.value1.borrow();
    var b2 = data.value1.borrow(); // 可以多个不可变借用
    std.debug.print("   借用1: {}, 借用2: {}\n", .{ b1.deref(), b2.deref() });
    b1.release();
    b2.release();

    std.debug.print("\n2. 可变借用独占:\n", .{});
    var b_mut = data.value1.borrowMut();
    b_mut.get().* = 100;
    std.debug.print("   可变借用修改: {}\n", .{b_mut.get().*});
    // 在可变借用期间，不能创建其他借用
    // var b3 = data.value1.borrow(); // 这会导致 panic
    b_mut.release();

    std.debug.print("\n3. 不同字段可以同时借用:\n", .{});
    var b_v1 = data.value1.borrow();
    var b_v2 = data.value2.borrowMut(); // 不同字段可以同时借用
    std.debug.print("   借用 value1: {}\n", .{b_v1.deref()});
    b_v2.get().* = 200;
    std.debug.print("   可变借用 value2: {}\n", .{b_v2.get().*});
    b_v1.release();
    b_v2.release();

    std.debug.print("\n", .{});
}

// 辅助函数：更新配置
fn updateConfig(config: *const Config) void {
    var mut_config: *Config = @constCast(config);
    var port_borrow = mut_config.port.borrowMut();
    port_borrow.get().* = 8080;
    port_borrow.release();
}

// 辅助函数：读取配置
fn readConfig(config: *const Config) void {
    var mut_config: *Config = @constCast(config);
    var host_borrow = mut_config.host.borrow();
    var port_borrow = mut_config.port.borrow();
    std.debug.print("   Config: {s}:{}\n", .{ host_borrow.deref(), port_borrow.deref() });
    host_borrow.release();
    port_borrow.release();
}

const Config = struct {
    host: lifetime.Owned([]const u8),
    port: lifetime.Owned(i32),
};

/// 嵌套结构体在函数间传递
pub fn nestedStructFunctionPassing() void {
    std.debug.print("=== 嵌套结构体在函数间传递 ===\n", .{});

    var config = Config{
        .host = lifetime.owned([]const u8, "localhost"),
        .port = lifetime.owned(i32, 3000),
    };

    std.debug.print("1. 初始配置:\n", .{});
    readConfig(&config);

    std.debug.print("\n2. 更新配置:\n", .{});
    updateConfig(&config);
    readConfig(&config);

    std.debug.print("\n3. 移动字段:\n", .{});
    const moved_port = config.port.take();
    std.debug.print("   移动 port: {}\n", .{moved_port});
    // config.port 现在已失效

    std.debug.print("\n", .{});
}

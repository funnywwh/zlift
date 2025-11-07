const std = @import("std");
const lifetime = @import("lifetime");
const Thread = std.Thread;

/// 线程间所有权转移示例（类似 Rust 的 Send）
pub fn threadTransferExample() void {
    std.debug.print("=== 线程间所有权转移示例 ===\n", .{});

    // 创建可在线程间转移的值
    var send_val = lifetime.ownedSend(i32, 100);
    std.debug.print("创建 OwnedSend 值: {}\n", .{send_val.get().*});
    std.debug.print("在当前线程: {}\n", .{send_val.isInCurrentThread()});

    // 转移到另一个线程
    const moved_value = send_val.sendToThread();
    std.debug.print("转移的值: {}\n", .{moved_value});
    std.debug.print("转移后 isValid: {}\n", .{send_val.isValid()});

    // 原值已失效，不能再访问
    // send_val.get().*; // 这会导致 panic

    std.debug.print("\n", .{});
}

/// 多线程间转移所有权
pub fn multiThreadTransfer() void {
    std.debug.print("=== 多线程间转移所有权 ===\n", .{});

    // 检查是否支持多线程
    // 在实际多线程环境中运行

    const Worker = struct {
        value: i32,
        worker_id: usize,

        fn run(self: *@This()) void {
            std.debug.print("线程 {} 接收值: {}\n", .{ self.worker_id, self.value });
            // 值现在属于这个线程，可以安全使用
            const result = self.value * 2;
            std.debug.print("线程 {} 处理结果: {}\n", .{ self.worker_id, result });
        }
    };

    // 创建多个值，分别转移到不同线程
    var val1 = lifetime.ownedSend(i32, 10);
    var val2 = lifetime.ownedSend(i32, 20);
    var val3 = lifetime.ownedSend(i32, 30);

    // 转移到线程
    const moved1 = val1.sendToThread();
    const moved2 = val2.sendToThread();
    const moved3 = val3.sendToThread();

    var worker1 = Worker{ .value = moved1, .worker_id = 1 };
    var worker2 = Worker{ .value = moved2, .worker_id = 2 };
    var worker3 = Worker{ .value = moved3, .worker_id = 3 };

    var thread1 = Thread.spawn(.{}, Worker.run, .{&worker1}) catch {
        std.debug.print("无法创建线程\n", .{});
        return;
    };
    var thread2 = Thread.spawn(.{}, Worker.run, .{&worker2}) catch {
        std.debug.print("无法创建线程\n", .{});
        return;
    };
    var thread3 = Thread.spawn(.{}, Worker.run, .{&worker3}) catch {
        std.debug.print("无法创建线程\n", .{});
        return;
    };

    thread1.join();
    thread2.join();
    thread3.join();

    std.debug.print("\n", .{});
}

/// 通过通道转移所有权
pub fn transferViaChannel() void {
    std.debug.print("=== 通过通道转移所有权 ===\n", .{});

    // 创建一个简单的通道来转移值
    const Channel = struct {
        value: ?i32 = null,
        mutex: std.Thread.Mutex = .{},
        cond: std.Thread.Condition = .{},

        fn send(self: *@This(), val: i32) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.value != null) {
                self.cond.wait(&self.mutex);
            }

            self.value = val;
            self.cond.signal();
        }

        fn receive(self: *@This()) i32 {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.value == null) {
                self.cond.wait(&self.mutex);
            }

            const val = self.value.?;
            self.value = null;
            self.cond.signal();
            return val;
        }
    };

    var channel = Channel{};

    const Sender = struct {
        channel: *Channel,
        value: i32,

        fn run(self: *@This()) void {
            std.debug.print("发送线程: 发送值 {}\n", .{self.value});
            self.channel.send(self.value);
            std.debug.print("发送线程: 值已发送\n", .{});
        }
    };

    const Receiver = struct {
        channel: *Channel,

        fn run(self: *@This()) void {
            const received = self.channel.receive();
            std.debug.print("接收线程: 接收值 {}\n", .{received});
            // 值现在属于接收线程
        }
    };

    // 创建可转移的值
    var send_val = lifetime.ownedSend(i32, 42);
    const value_to_send = send_val.sendToThread();

    var sender = Sender{ .channel = &channel, .value = value_to_send };
    var receiver = Receiver{ .channel = &channel };

    var send_thread = Thread.spawn(.{}, Sender.run, .{&sender}) catch {
        std.debug.print("无法创建线程\n", .{});
        return;
    };
    var recv_thread = Thread.spawn(.{}, Receiver.run, .{&receiver}) catch {
        std.debug.print("无法创建线程\n", .{});
        return;
    };

    send_thread.join();
    recv_thread.join();

    std.debug.print("\n", .{});
}

/// 转移后原线程无法访问
pub fn transferSafetyExample() void {
    std.debug.print("=== 转移后原线程无法访问 ===\n", .{});

    var send_val = lifetime.ownedSend(i32, 100);
    std.debug.print("初始值: {}\n", .{send_val.get().*});
    std.debug.print("isValid: {}\n", .{send_val.isValid()});

    // 转移值
    const moved = send_val.sendToThread();
    std.debug.print("转移的值: {}\n", .{moved});

    // 原值已失效
    std.debug.print("转移后 isValid: {}\n", .{send_val.isValid()});
    std.debug.print("转移后 isInCurrentThread: {}\n", .{send_val.isInCurrentThread()});

    // 尝试访问会导致 panic
    // send_val.get().*; // 这会导致 panic: "cannot access moved value"

    std.debug.print("\n", .{});
}

/// 嵌套结构体的线程间转移（普通嵌套）
pub fn nestedStructTransfer() void {
    std.debug.print("=== 嵌套结构体的线程间转移 ===\n", .{});

    const Config = struct {
        host: []const u8,
        port: i32,
    };

    var send_config = lifetime.ownedSend(Config, .{
        .host = "localhost",
        .port = 3000,
    });

    std.debug.print("初始配置: {s}:{}\n", .{ send_config.get().host, send_config.get().port });

    // 转移到另一个线程
    const moved_config = send_config.sendToThread();
    std.debug.print("转移的配置: {s}:{}\n", .{ moved_config.host, moved_config.port });

    // 原值已失效
    std.debug.print("转移后 isValid: {}\n", .{send_config.isValid()});

    std.debug.print("\n", .{});
}

/// 结构体中包含 OwnedSend 字段（嵌套 OwnedSend）
pub fn structWithOwnedSendFields() void {
    std.debug.print("=== 结构体中包含 OwnedSend 字段 ===\n", .{});

    const ServerConfig = struct {
        host: lifetime.OwnedSend([]const u8),
        port: lifetime.OwnedSend(i32),
    };

    var config = ServerConfig{
        .host = lifetime.ownedSend([]const u8, "localhost"),
        .port = lifetime.ownedSend(i32, 3000),
    };

    std.debug.print("初始配置:\n", .{});
    std.debug.print("  host: {s}, port: {}\n", .{ config.host.get().*, config.port.get().* });

    // 可以独立转移嵌套的 OwnedSend 字段
    std.debug.print("\n1. 转移 host 字段:\n", .{});
    const moved_host = config.host.sendToThread();
    std.debug.print("  转移的 host: {s}\n", .{moved_host});
    std.debug.print("  config.host.isValid(): {}\n", .{config.host.isValid()});
    std.debug.print("  config.port.isValid(): {} (port 仍然有效)\n", .{config.port.isValid()});

    // port 仍然可以访问
    std.debug.print("\n2. 继续使用 port:\n", .{});
    std.debug.print("  port: {}\n", .{config.port.get().*});

    // 转移 port
    std.debug.print("\n3. 转移 port 字段:\n", .{});
    const moved_port = config.port.sendToThread();
    std.debug.print("  转移的 port: {}\n", .{moved_port});
    std.debug.print("  config.port.isValid(): {}\n", .{config.port.isValid()});

    std.debug.print("\n", .{});
}

/// 深度嵌套的 OwnedSend
pub fn deeplyNestedOwnedSend() void {
    std.debug.print("=== 深度嵌套的 OwnedSend ===\n", .{});

    const Address = struct {
        street: lifetime.OwnedSend([]const u8),
        city: lifetime.OwnedSend([]const u8),
    };

    const Employee = struct {
        name: lifetime.OwnedSend([]const u8),
        address: Address,
        salary: lifetime.OwnedSend(i32),
    };

    var employee = Employee{
        .name = lifetime.ownedSend([]const u8, "Alice"),
        .address = Address{
            .street = lifetime.ownedSend([]const u8, "123 Main St"),
            .city = lifetime.ownedSend([]const u8, "New York"),
        },
        .salary = lifetime.ownedSend(i32, 75000),
    };

    std.debug.print("初始 Employee:\n", .{});
    std.debug.print("  name: {s}\n", .{employee.name.get().*});
    std.debug.print("  address.street: {s}\n", .{employee.address.street.get().*});
    std.debug.print("  address.city: {s}\n", .{employee.address.city.get().*});
    std.debug.print("  salary: {}\n", .{employee.salary.get().*});

    // 可以独立转移任意深度的字段
    std.debug.print("\n1. 转移 name:\n", .{});
    const moved_name = employee.name.sendToThread();
    std.debug.print("  转移的 name: {s}\n", .{moved_name});
    std.debug.print("  employee.name.isValid(): {}\n", .{employee.name.isValid()});

    std.debug.print("\n2. 转移嵌套字段 address.street:\n", .{});
    const moved_street = employee.address.street.sendToThread();
    std.debug.print("  转移的 street: {s}\n", .{moved_street});
    std.debug.print("  employee.address.street.isValid(): {}\n", .{employee.address.street.isValid()});

    std.debug.print("\n3. 其他字段仍然有效:\n", .{});
    std.debug.print("  address.city: {s}\n", .{employee.address.city.get().*});
    std.debug.print("  salary: {}\n", .{employee.salary.get().*});

    std.debug.print("\n", .{});
}

/// 嵌套 OwnedSend 在多线程中的使用
pub fn nestedOwnedSendInThreads() void {
    std.debug.print("=== 嵌套 OwnedSend 在多线程中的使用 ===\n", .{});

    const Config = struct {
        host: lifetime.OwnedSend([]const u8),
        port: lifetime.OwnedSend(i32),
    };

    var config = Config{
        .host = lifetime.ownedSend([]const u8, "localhost"),
        .port = lifetime.ownedSend(i32, 8080),
    };

    const Worker = struct {
        host: []const u8,
        worker_id: usize,

        fn run(self: *@This()) void {
            std.debug.print("线程 {} 使用 host: {s}\n", .{ self.worker_id, self.host });
        }
    };

    // 转移 host 到线程1
    const moved_host = config.host.sendToThread();
    var worker1 = Worker{ .host = moved_host, .worker_id = 1 };

    // 转移 port 到线程2（需要重新创建，因为 port 还在）
    // 注意：这里演示的是分别转移不同字段
    var port_val = lifetime.ownedSend(i32, config.port.get().*);
    const moved_port = port_val.sendToThread();

    const PortWorker = struct {
        port: i32,
        worker_id: usize,

        fn run(self: *@This()) void {
            std.debug.print("线程 {} 使用 port: {}\n", .{ self.worker_id, self.port });
        }
    };

    var worker2 = PortWorker{ .port = moved_port, .worker_id = 2 };

    var thread1 = Thread.spawn(.{}, Worker.run, .{&worker1}) catch {
        std.debug.print("无法创建线程\n", .{});
        return;
    };
    var thread2 = Thread.spawn(.{}, PortWorker.run, .{&worker2}) catch {
        std.debug.print("无法创建线程\n", .{});
        return;
    };

    thread1.join();
    thread2.join();

    std.debug.print("\n", .{});
}

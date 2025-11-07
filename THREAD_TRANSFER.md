# 线程间所有权转移（类似 Rust 的 Send）

本文档说明如何通过转移所有权实现线程安全，而不是通过共享和锁。

## 设计理念

类似 Rust 的 `Send` trait，通过**移动语义**实现线程安全：

1. **值只能在一个线程中拥有**
2. **通过移动（转移所有权）将值传递给另一个线程**
3. **一旦转移，原线程就无法再访问该值**
4. **不需要锁**，因为每个值只在一个线程中

## OwnedSend 类型

`OwnedSend(T)` 提供了线程间安全转移的机制：

```zig
// 创建可转移的值
var send_val = lifetime.ownedSend(i32, 100);

// 在当前线程使用
std.debug.print("值: {}\n", .{send_val.get().*});

// 转移到另一个线程
const moved_value = send_val.sendToThread();

// 原值已失效，不能再访问
// send_val.get().*; // 这会导致 panic
```

## 核心特性

### 1. 线程绑定

值在创建时绑定到当前线程：

```zig
var send_val = lifetime.ownedSend(i32, 42);
// 值现在属于当前线程
```

### 2. 所有权转移

通过 `sendToThread()` 转移所有权：

```zig
const moved = send_val.sendToThread();
// 值现在可以安全地传递给另一个线程
// send_val 已失效
```

### 3. 转移后无法访问

转移后，原线程无法再访问：

```zig
var send_val = lifetime.ownedSend(i32, 100);
const moved = send_val.sendToThread();

// ❌ 错误：无法访问已转移的值
send_val.get().*; // panic: "cannot access moved value"
```

### 4. 线程检查

只能从创建线程转移：

```zig
var send_val = lifetime.ownedSend(i32, 42);

// 只能在创建线程中转移
const moved = send_val.sendToThread(); // ✅ 正确

// 如果从其他线程尝试转移会失败
// （运行时检查）
```

## 使用模式

### 模式 1: 直接转移给线程

```zig
const Worker = struct {
    value: i32,
    
    fn run(self: *@This()) void {
        // 值现在属于这个线程
        std.debug.print("接收值: {}\n", .{self.value});
    }
};

// 创建值
var send_val = lifetime.ownedSend(i32, 42);

// 转移到线程
const moved = send_val.sendToThread();
var worker = Worker{ .value = moved };
var thread = std.Thread.spawn(.{}, Worker.run, .{&worker});
thread.join();
```

### 模式 2: 通过通道转移

```zig
// 创建通道
const Channel = struct {
    value: ?i32 = null,
    mutex: std.Thread.Mutex = .{},
    // ...
};

var channel = Channel{};

// 创建值并转移
var send_val = lifetime.ownedSend(i32, 100);
const value_to_send = send_val.sendToThread();

// 通过通道发送
channel.send(value_to_send);

// 在另一个线程接收
const received = channel.receive();
// 值现在属于接收线程
```

### 模式 3: 多个值分别转移

```zig
// 创建多个值
var val1 = lifetime.ownedSend(i32, 10);
var val2 = lifetime.ownedSend(i32, 20);
var val3 = lifetime.ownedSend(i32, 30);

// 分别转移到不同线程
const moved1 = val1.sendToThread();
const moved2 = val2.sendToThread();
const moved3 = val3.sendToThread();

// 每个线程拥有自己的值，互不干扰
```

## 与共享方式的对比

### 共享方式（OwnedThreadSafe）

```zig
// ❌ 共享方式：需要锁，性能开销大
var shared = lifetime.ownedThreadSafe(i32, 0);
// 多个线程共享同一个值，需要锁保护
```

### 转移方式（OwnedSend）

```zig
// ✅ 转移方式：不需要锁，性能更好
var send_val = lifetime.ownedSend(i32, 0);
const moved = send_val.sendToThread();
// 值只属于一个线程，无需锁
```

## 优势

1. **无锁设计**: 不需要互斥锁，性能更好
2. **编译时安全**: 通过类型系统保证安全性
3. **简单清晰**: 所有权转移语义明确
4. **避免竞争**: 值只在一个线程中，不可能有竞争

## 限制

1. **只能转移一次**: 转移后原值失效
2. **不能共享**: 值只能属于一个线程
3. **需要复制**: 如果需要在多个线程使用，需要复制值

## 适用场景

### 适合使用 OwnedSend

- 值只需要在一个线程中使用
- 需要将值传递给另一个线程
- 不需要多线程共享访问
- 性能要求高（避免锁开销）

### 不适合使用 OwnedSend

- 需要多个线程同时访问同一个值
- 需要共享状态
- 需要引用计数语义

## 嵌套 OwnedSend 支持

### 结构体中包含 OwnedSend 字段

`OwnedSend` 完全支持嵌套，可以在结构体中包含 `OwnedSend` 字段：

```zig
const ServerConfig = struct {
    host: lifetime.OwnedSend([]const u8),
    port: lifetime.OwnedSend(i32),
};

var config = ServerConfig{
    .host = lifetime.ownedSend([]const u8, "localhost"),
    .port = lifetime.ownedSend(i32, 3000),
};
```

### 独立转移嵌套字段

每个 `OwnedSend` 字段可以独立转移，不影响其他字段：

```zig
// 转移 host，port 仍然有效
const moved_host = config.host.sendToThread();
std.debug.print("port 仍然有效: {}\n", .{config.port.get().*});

// 之后可以转移 port
const moved_port = config.port.sendToThread();
```

### 深度嵌套支持

支持任意深度的嵌套：

```zig
const Address = struct {
    street: lifetime.OwnedSend([]const u8),
    city: lifetime.OwnedSend([]const u8),
};

const Employee = struct {
    name: lifetime.OwnedSend([]const u8),
    address: Address,  // 嵌套结构体
    salary: lifetime.OwnedSend(i32),
};

// 可以独立转移任意深度的字段
const moved_name = employee.name.sendToThread();
const moved_street = employee.address.street.sendToThread();
```

### 多线程使用嵌套字段

嵌套的 `OwnedSend` 字段可以分别转移到不同的线程：

```zig
// host 转移到线程1
const moved_host = config.host.sendToThread();
var worker1 = Worker{ .host = moved_host };

// port 转移到线程2
const moved_port = config.port.sendToThread();
var worker2 = PortWorker{ .port = moved_port };
```

## 示例代码

完整示例请参考 `src/examples/thread_transfer.zig`，包含：

- `threadTransferExample()` - 基本转移示例
- `transferSafetyExample()` - 转移安全性验证
- `nestedStructTransfer()` - 嵌套结构体转移（普通嵌套）
- `structWithOwnedSendFields()` - 结构体中包含 OwnedSend 字段
- `deeplyNestedOwnedSend()` - 深度嵌套的 OwnedSend
- `nestedOwnedSendInThreads()` - 嵌套 OwnedSend 在多线程中的使用
- `multiThreadTransfer()` - 多线程转移
- `transferViaChannel()` - 通过通道转移

## 总结

通过转移所有权实现线程安全是 Rust 的核心设计理念：

1. **值只能在一个线程中**
2. **通过移动转移所有权**
3. **转移后原线程无法访问**
4. **无需锁，性能更好**

这种方式比共享+锁的方式更安全、更高效。


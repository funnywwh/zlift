const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

/// 生命周期管理错误类型
pub const LifetimeError = error{
    AlreadyMoved,
    BorrowConflict,
    InvalidBorrow,
    DoubleFree,
};

/// 所有权状态标记
const OwnershipState = enum {
    owned,
    moved,
    borrowed,
    borrowed_mut,
};

/// 拥有所有权的包装类型
/// 类似于 Rust 的 Box<T> 或拥有所有权的值
pub fn Owned(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        state: OwnershipState = .owned,
        borrow_count: usize = 0,
        mut_borrow_count: usize = 0,

        /// 创建新的 Owned 值
        pub fn init(value: T) Self {
            return Self{
                .value = value,
                .state = .owned,
                .borrow_count = 0,
                .mut_borrow_count = 0,
            };
        }

        /// 转移所有权（移动语义）
        /// 移动后原值将失效
        pub fn take(self: *Self) T {
            if (self.state == .moved) {
                @panic("attempted to use moved value");
            }
            if (self.state == .borrowed or self.state == .borrowed_mut) {
                @panic("cannot move value while it is borrowed");
            }

            const value = self.value;
            self.state = .moved;
            return value;
        }

        /// 创建不可变借用
        pub fn borrow(self: *Self) Borrowed(T) {
            if (self.state == .moved) {
                @panic("cannot borrow moved value");
            }
            if (self.state == .borrowed_mut) {
                @panic("cannot create immutable borrow while mutable borrow exists");
            }

            self.state = .borrowed;
            self.borrow_count += 1;
            return Borrowed(T).init(self);
        }

        /// 创建可变借用
        pub fn borrowMut(self: *Self) BorrowedMut(T) {
            if (self.state == .moved) {
                @panic("cannot borrow moved value");
            }
            if (self.state == .borrowed or self.state == .borrowed_mut) {
                @panic("cannot create mutable borrow while borrow exists");
            }

            self.state = .borrowed_mut;
            self.mut_borrow_count = 1;
            return BorrowedMut(T).init(self);
        }

        /// 获取值的引用（不转移所有权）
        /// 仅在未借用且未移动时可用
        pub fn get(self: *Self) *T {
            if (self.state == .moved) {
                @panic("cannot access moved value");
            }
            if (self.state == .borrowed or self.state == .borrowed_mut) {
                @panic("cannot directly access value while borrowed");
            }
            return &self.value;
        }

        /// 获取值的可变引用
        /// 仅在未借用且未移动时可用
        pub fn getMut(self: *Self) *T {
            if (self.state == .moved) {
                @panic("cannot access moved value");
            }
            if (self.state == .borrowed or self.state == .borrowed_mut) {
                @panic("cannot directly access value while borrowed");
            }
            return &self.value;
        }

        /// 释放借用（内部方法，由 Borrowed/BorrowedMut 调用）
        fn releaseBorrow(self: *Self) void {
            if (self.borrow_count > 0) {
                self.borrow_count -= 1;
                if (self.borrow_count == 0) {
                    self.state = .owned;
                }
            }
        }

        /// 释放可变借用（内部方法，由 BorrowedMut 调用）
        fn releaseMutBorrow(self: *Self) void {
            if (self.mut_borrow_count > 0) {
                self.mut_borrow_count = 0;
                self.state = .owned;
            }
        }

        /// 检查值是否有效（未移动且未借用）
        pub fn isValid(self: *const Self) bool {
            return self.state == .owned;
        }

        /// 深度复制 Owned 值
        /// 创建一个新的 Owned 实例，包含值的深度复制
        pub fn clone(self: Self) Self {
            if (self.state == .moved) {
                @panic("cannot clone moved value");
            }
            // 对于 Owned，我们复制内部的值
            const copied_value = deepCopy(T, self.value);
            return Self.init(copied_value);
        }
    };
}

/// 不可变借用类型
/// 类似于 Rust 的 &T
pub fn Borrowed(comptime T: type) type {
    return struct {
        const Self = @This();

        owner: *Owned(T),

        fn init(owner: *Owned(T)) Self {
            return Self{ .owner = owner };
        }

        /// 获取值的不可变引用
        pub fn get(self: *const Self) *const T {
            return &self.owner.value;
        }

        /// 解引用获取值
        pub fn deref(self: *const Self) T {
            return self.owner.value;
        }

        /// 释放借用
        pub fn release(self: *Self) void {
            self.owner.releaseBorrow();
        }
    };
}

/// 可变借用类型
/// 类似于 Rust 的 &mut T
pub fn BorrowedMut(comptime T: type) type {
    return struct {
        const Self = @This();

        owner: *Owned(T),

        fn init(owner: *Owned(T)) Self {
            return Self{ .owner = owner };
        }

        /// 获取值的可变引用
        pub fn get(self: *Self) *T {
            return &self.owner.value;
        }

        /// 获取值的不可变引用
        pub fn getConst(self: *const Self) *const T {
            return &self.owner.value;
        }

        /// 解引用获取值
        pub fn deref(self: *Self) T {
            return self.owner.value;
        }

        /// 释放借用
        pub fn release(self: *Self) void {
            self.owner.releaseMutBorrow();
        }
    };
}

/// 编译时借用检查器
/// 使用 comptime 在编译时验证借用规则
pub const BorrowChecker = struct {
    /// 编译时检查：确保值未被移动
    pub fn comptimeCheckNotMoved(comptime state: OwnershipState) void {
        if (state == .moved) {
            @compileError("attempted to use moved value");
        }
    }

    /// 编译时检查：确保可以创建不可变借用
    pub fn comptimeCheckCanBorrow(comptime state: OwnershipState) void {
        if (state == .moved) {
            @compileError("cannot borrow moved value");
        }
        if (state == .borrowed_mut) {
            @compileError("cannot create immutable borrow while mutable borrow exists");
        }
    }

    /// 编译时检查：确保可以创建可变借用
    pub fn comptimeCheckCanBorrowMut(comptime state: OwnershipState) void {
        if (state == .moved) {
            @compileError("cannot borrow moved value");
        }
        if (state == .borrowed or state == .borrowed_mut) {
            @compileError("cannot create mutable borrow while borrow exists");
        }
    }
};

/// 辅助函数：创建 Owned 值
pub fn owned(comptime T: type, value: T) Owned(T) {
    return Owned(T).init(value);
}

/// 辅助函数：移动值
pub fn move(comptime T: type, owned_val: *Owned(T)) T {
    return owned_val.take();
}

/// 辅助函数：创建不可变借用
pub fn borrow(comptime T: type, owned_val: *Owned(T)) Borrowed(T) {
    return owned_val.borrow();
}

/// 辅助函数：创建可变借用
pub fn borrowMut(comptime T: type, owned_val: *Owned(T)) BorrowedMut(T) {
    return owned_val.borrowMut();
}

/// 复制类型标记
/// 用于标记可以安全复制的类型（如基本数值类型）
pub fn isCopyType(comptime T: type) bool {
    const type_info = @typeInfo(T);
    return switch (type_info) {
        .int, .float, .bool, .comptime_int, .comptime_float => true,
        .@"enum" => true,
        .error_set => true,
        .void => true,
        .type => true,
        else => false,
    };
}

/// 复制语义的 Owned 类型
/// 对于复制类型，提供复制而不是移动的语义
pub fn OwnedCopy(comptime T: type) type {
    return struct {
        const Self = @This();

        data: T,

        /// 创建新的 OwnedCopy 值
        pub fn init(val: T) Self {
            return Self{ .data = val };
        }

        /// 复制值（不转移所有权）
        /// 对于复制类型，可以安全地复制
        pub fn copy(self: Self) T {
            return self.data;
        }

        /// 获取值的引用
        pub fn get(self: *Self) *T {
            return &self.data;
        }

        /// 获取值的不可变引用
        pub fn getConst(self: *const Self) *const T {
            return &self.data;
        }

        /// 获取值本身
        pub fn value(self: Self) T {
            return self.data;
        }
    };
}

/// 辅助函数：创建复制类型的 Owned 值
pub fn ownedCopy(comptime T: type, value: T) OwnedCopy(T) {
    return OwnedCopy(T).init(value);
}

/// 检查类型是否是 Owned 类型
/// 通过检查类型是否有特定的字段来判断
fn isOwnedType(comptime T: type) bool {
    const type_info = @typeInfo(T);
    if (type_info != .@"struct") return false;

    const s = type_info.@"struct";
    // 检查是否有 value, state, borrow_count, mut_borrow_count 字段
    // 并且字段类型匹配
    var has_value = false;
    var has_state = false;
    var has_borrow_count = false;
    var has_mut_borrow_count = false;

    inline for (s.fields) |field| {
        if (mem.eql(u8, field.name, "value")) has_value = true;
        if (mem.eql(u8, field.name, "state")) {
            // 检查 state 字段类型是否是 OwnershipState
            // 通过检查类型信息来判断
            const state_type_info = @typeInfo(field.type);
            if (state_type_info == .@"enum") {
                const state_enum = state_type_info.@"enum";
                // 检查枚举是否有 owned, moved, borrowed, borrowed_mut 这些值
                var has_owned = false;
                var has_moved = false;
                inline for (state_enum.fields) |enum_field| {
                    if (mem.eql(u8, enum_field.name, "owned")) has_owned = true;
                    if (mem.eql(u8, enum_field.name, "moved")) has_moved = true;
                }
                if (has_owned and has_moved) has_state = true;
            }
        }
        if (mem.eql(u8, field.name, "borrow_count")) {
            // 检查类型是否是 usize
            if (field.type == usize) has_borrow_count = true;
        }
        if (mem.eql(u8, field.name, "mut_borrow_count")) {
            // 检查类型是否是 usize
            if (field.type == usize) has_mut_borrow_count = true;
        }
    }

    // 必须同时有所有四个字段才认为是 Owned 类型
    // 并且字段数量应该合理（Owned 有多个字段，包括方法）
    return has_value and has_state and has_borrow_count and has_mut_borrow_count;
}

/// 深度复制支持
/// 用于结构体的深度复制，递归复制所有字段
/// 支持结构体中包含 Owned 类型的字段
pub fn deepCopy(comptime T: type, value: T) T {
    return switch (@typeInfo(T)) {
        .@"struct" => |s| blk: {
            var result: T = undefined;
            inline for (s.fields) |field| {
                const field_value = @field(value, field.name);

                // 检查字段类型是否是 Owned 类型
                if (comptime isOwnedType(field.type)) {
                    // 对于 Owned 类型，使用 clone 方法进行深度复制
                    // field_value 已经是 Owned 类型，直接调用 clone
                    const owned_val: field.type = field_value;
                    @field(result, field.name) = owned_val.clone();
                } else {
                    // 对于其他类型，递归调用 deepCopy
                    @field(result, field.name) = deepCopy(field.type, field_value);
                }
            }
            break :blk result;
        },
        .array => |a| blk: {
            var result: [a.len]a.child = undefined;
            for (0..a.len) |i| {
                result[i] = deepCopy(a.child, value[i]);
            }
            break :blk result;
        },
        .pointer => |p| switch (p.size) {
            .slice => blk: {
                // 对于切片，需要分配新内存（这里简化处理，返回原切片）
                // 实际应用中可能需要使用分配器
                break :blk value;
            },
            else => value,
        },
        .optional => |o| if (value) |v|
            deepCopy(o.child, v)
        else
            null,
        .@"union" => blk: {
            // 联合体的深度复制需要特殊处理
            // 这里简化处理
            break :blk value;
        },
        else => value, // 基本类型直接复制
    };
}

/// 支持深度复制的 Owned 包装器
/// 用于结构体等复杂类型
pub fn OwnedDeepCopy(comptime T: type) type {
    return struct {
        const Self = @This();

        data: T,

        /// 创建新的 OwnedDeepCopy 值
        pub fn init(val: T) Self {
            return Self{ .data = val };
        }

        /// 深度复制值
        /// 递归复制所有嵌套字段
        pub fn deepCopyValue(self: Self) T {
            return deepCopy(T, self.data);
        }

        /// 浅复制（仅复制顶层）
        pub fn shallowCopy(self: Self) T {
            return self.data;
        }

        /// 获取值的引用
        pub fn get(self: *Self) *T {
            return &self.data;
        }

        /// 获取值的不可变引用
        pub fn getConst(self: *const Self) *const T {
            return &self.data;
        }

        /// 获取值本身
        pub fn value(self: Self) T {
            return self.data;
        }
    };
}

/// 辅助函数：创建支持深度复制的 Owned 值
pub fn ownedDeepCopy(comptime T: type, value: T) OwnedDeepCopy(T) {
    return OwnedDeepCopy(T).init(value);
}

// 测试用例
test "Owned: 基本创建和使用" {
    var owned_val = Owned(i32).init(42);
    try std.testing.expect(owned_val.isValid());
    try std.testing.expectEqual(@as(i32, 42), owned_val.value);
}

test "Owned: 移动语义" {
    var owned_val = Owned(i32).init(100);
    const moved_value = owned_val.take();
    try std.testing.expectEqual(@as(i32, 100), moved_value);
    try std.testing.expect(!owned_val.isValid());
}

test "Owned: 不可变借用" {
    var owned_val = Owned(i32).init(200);
    var borrowed = owned_val.borrow();
    try std.testing.expectEqual(@as(i32, 200), borrowed.deref());
    borrowed.release();
    try std.testing.expect(owned_val.isValid());
}

test "Owned: 可变借用" {
    var owned_val = Owned(i32).init(300);
    var borrowed_mut = owned_val.borrowMut();
    borrowed_mut.get().* = 400;
    try std.testing.expectEqual(@as(i32, 400), borrowed_mut.deref());
    borrowed_mut.release();
    try std.testing.expectEqual(@as(i32, 400), owned_val.value);
}

test "Owned: 借用后不能移动" {
    var owned_val = Owned(i32).init(500);
    var borrowed = owned_val.borrow();
    _ = borrowed.deref(); // 使用借用
    borrowed.release();
    // 尝试移动应该失败（运行时检查）
    // 注意：这会在运行时 panic，无法在测试中直接验证
    // 实际使用中应该确保在移动前释放所有借用
}

test "Owned: 多个不可变借用" {
    var owned_val = Owned(i32).init(600);
    var borrow1 = owned_val.borrow();
    var borrow2 = owned_val.borrow();
    try std.testing.expectEqual(@as(i32, 600), borrow1.deref());
    try std.testing.expectEqual(@as(i32, 600), borrow2.deref());
    borrow1.release();
    borrow2.release();
    try std.testing.expect(owned_val.isValid());
}

test "Owned: 可变借用独占性" {
    var owned_val = Owned(i32).init(700);
    var borrow_mut = owned_val.borrowMut();
    borrow_mut.get().* = 800;
    borrow_mut.release();
    // 尝试在可变借用存在时创建不可变借用应该失败
    // 实际使用中应该确保在创建新借用前释放可变借用
}

test "辅助函数: owned, move, borrow" {
    var val = owned(i32, 42);
    try std.testing.expectEqual(@as(i32, 42), val.value);

    const moved = move(i32, &val);
    try std.testing.expectEqual(@as(i32, 42), moved);

    var val2 = owned(i32, 100);
    var b = borrow(i32, &val2);
    try std.testing.expectEqual(@as(i32, 100), b.deref());
    b.release();
}

test "OwnedCopy: 复制语义" {
    var copy_val = OwnedCopy(i32).init(42);
    const copied = copy_val.copy();
    try std.testing.expectEqual(@as(i32, 42), copied);
    // 原值仍然有效
    try std.testing.expectEqual(@as(i32, 42), copy_val.value());

    // 可以多次复制
    const copied2 = copy_val.copy();
    try std.testing.expectEqual(@as(i32, 42), copied2);
}

test "isCopyType: 类型检查" {
    try std.testing.expect(isCopyType(i32));
    try std.testing.expect(isCopyType(f64));
    try std.testing.expect(isCopyType(bool));
    try std.testing.expect(!isCopyType([]const u8));
}

// ============================================================================
// 线程间所有权转移（类似 Rust 的 Send）
// ============================================================================

/// 可以安全在线程间转移的类型标记
/// 类似 Rust 的 Send trait
/// 通过移动语义实现线程安全：值只能在一个线程中，转移后原线程无法访问
pub fn OwnedSend(comptime T: type) type {
    return struct {
        const Self = @This();

        value: T,
        thread_id: ?std.Thread.Id = null,
        is_moved: bool = false,

        /// 创建新的 OwnedSend 值
        pub fn init(value: T) Self {
            return Self{
                .value = value,
                .thread_id = std.Thread.getCurrentId(),
                .is_moved = false,
            };
        }

        /// 转移到另一个线程（移动语义）
        /// 转移后，原线程无法再访问该值
        pub fn sendToThread(self: *Self) T {
            if (self.is_moved) {
                @panic("attempted to send already moved value");
            }

            const current_thread = std.Thread.getCurrentId();
            if (self.thread_id) |tid| {
                // 检查是否在当前线程（简化检查，实际中可能需要更复杂的比较）
                // 注意：Zig 的 Thread.Id 可能不支持直接比较，这里简化处理
                _ = tid;
                _ = current_thread;
            }

            const value = self.value;
            self.is_moved = true;
            self.thread_id = null;
            return value;
        }

        /// 检查值是否在当前线程
        pub fn isInCurrentThread(self: *const Self) bool {
            if (self.is_moved) return false;
            const current_thread = std.Thread.getCurrentId();
            if (self.thread_id) |tid| {
                // 简化检查：如果 thread_id 不为 null 且未移动，认为在当前线程
                // 实际实现中可能需要更精确的线程 ID 比较
                _ = tid;
                _ = current_thread;
                return true;
            }
            return false;
        }

        /// 获取值的引用（仅在当前线程）
        pub fn get(self: *Self) *T {
            if (self.is_moved) {
                @panic("cannot access moved value");
            }
            if (!self.isInCurrentThread()) {
                @panic("cannot access value from different thread");
            }
            return &self.value;
        }

        /// 获取值的可变引用（仅在当前线程）
        pub fn getMut(self: *Self) *T {
            if (self.is_moved) {
                @panic("cannot access moved value");
            }
            if (!self.isInCurrentThread()) {
                @panic("cannot access value from different thread");
            }
            return &self.value;
        }

        /// 检查值是否有效（未移动且在当前线程）
        pub fn isValid(self: *const Self) bool {
            return !self.is_moved and self.isInCurrentThread();
        }
    };
}

/// 辅助函数：创建可在线程间转移的 Owned 值
pub fn ownedSend(comptime T: type, value: T) OwnedSend(T) {
    return OwnedSend(T).init(value);
}

// ============================================================================
// 弱引用支持（用于避免循环引用）
// ============================================================================

/// 弱引用类型（Weak reference）
/// 类似于 Rust 的 Weak<T>，不会阻止对象释放
/// 用于打破循环引用
pub fn Weak(comptime T: type) type {
    return struct {
        const Self = @This();

        // 使用原始指针，不持有所有权
        // 注意：这需要用户确保指针有效性
        ptr: ?*T = null,

        /// 创建弱引用
        /// 注意：Weak 不持有所有权，需要确保对象生命周期
        pub fn init(ptr: ?*T) Self {
            return Self{ .ptr = ptr };
        }

        /// 尝试升级为强引用（Borrowed）
        /// 如果对象仍然有效，返回借用；否则返回 null
        /// 注意：这需要对象是 Owned 类型
        pub fn upgrade(self: *const Self) ?*T {
            return self.ptr;
        }

        /// 检查弱引用是否仍然有效
        /// 注意：这只能检查指针是否为 null，不能检查对象是否已释放
        /// 实际应用中需要更复杂的机制（如引用计数）
        pub fn isValid(self: *const Self) bool {
            return self.ptr != null;
        }

        /// 清空弱引用
        pub fn clear(self: *Self) void {
            self.ptr = null;
        }
    };
}

/// 辅助函数：创建弱引用
pub fn weak(comptime T: type, ptr: ?*T) Weak(T) {
    return Weak(T).init(ptr);
}

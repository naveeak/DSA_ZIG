const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const StackError = error {
  EmptyStackException,
  StackOverFlowException
};

pub fn Stack(comptime T: type) type {
    const MAX_SIZE: usize = 100;
    return struct {
        items: []T,
        allocator: Allocator,
        size: usize,

        ///  setting default size to 100
        fn init(allocator: Allocator) !Stack(T) {
            return .{ .allocator = allocator, .items = try allocator.alloc(T, MAX_SIZE), .size = 0 };
        }

        fn deinit(self: *Stack(T)) void {
            self.allocator.free(self.items);
        }

        fn push(self: *Stack(T), value: T) !void {
            if(self.size == MAX_SIZE) return error.StackOverFlowException;
            self.items[self.size] = value;
            self.size += 1;
        }

        fn pop(self: *Stack(T)) !T {
            if (self.size == 0) return error.EmptyStackException;
            const returnValue = self.items[self.size - 1];
            self.size -= 1;
            return returnValue;
        }

        fn peek(self: *Stack(T)) !T {
            if (isEmpty(self)) return error.EmptyStackException;
            const returnValue = self.items[self.size - 1];
            return returnValue;
        }

        fn getSize(self: *Stack(T)) usize {
            return self.size;
        }

        fn isEmpty(self: *Stack(T)) bool {
            return self.size == 0;
        }
    };
}
test "stack - initialization" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try testing.expectEqual(@as(usize, 0), stack.size);
    try testing.expectEqual(@as(usize, 100), stack.items.len);
}

test "stack - push" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try stack.push(42);
    try testing.expectEqual(@as(usize, 1), stack.size);
    try testing.expectEqual(@as(i32, 42), stack.items[0]);

    try stack.push(43);
    try testing.expectEqual(@as(usize, 2), stack.size);
    try testing.expectEqual(@as(i32, 43), stack.items[1]);
}

test "stack - pop" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try stack.push(42);
    try stack.push(43);

    const val = try stack.pop();
    try testing.expectEqual(@as(i32, 43), val);
    try testing.expectEqual(@as(usize, 1), stack.size);

    var empty_stack = try Stack(i32).init(allocator);
    try testing.expectError(error.EmptyStackException, empty_stack.pop());
}

test "stack - peek" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try stack.push(42);
    const val = try stack.peek();
    try testing.expectEqual(@as(i32, 42), val);
    try testing.expectEqual(@as(usize, 1), stack.size);

    var empty_stack = try Stack(i32).init(allocator);
    try testing.expectError(error.EmptyStackException, empty_stack.peek());
}

test "stack - isEmpty" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try testing.expect(stack.isEmpty());
    try stack.push(42);
    try testing.expect(!stack.isEmpty());
    _ = try stack.pop();
    try testing.expect(stack.isEmpty());
}

test "stack - size" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try testing.expectEqual(@as(usize, 0), stack.size);
    try stack.push(42);
    try testing.expectEqual(@as(usize, 1), stack.size);
    _ = try stack.pop();
    try testing.expectEqual(@as(usize, 0), stack.size);
}

test "stack operations" {
    var stack = try Stack(i32).init(testing.allocator);
    defer stack.deinit();

    // Test initial conditions
    try testing.expect(stack.isEmpty());
    try testing.expectEqual(@as(usize, 0), stack.getSize());

    // Test successful pushes
    for(0..100)|i|{
    try stack.push(@intCast(i));}
    try testing.expectEqual(@as(usize, 100), stack.getSize());

    // Test stack overflow
    try testing.expectError(error.StackOverFlowException, stack.push(40));

    // Test other operations remain valid
    try testing.expectEqual(@as(i32, 99), try stack.peek());
    try testing.expectEqual(@as(i32, 99), try stack.pop());
    try testing.expectEqual(@as(usize, 99), stack.getSize());
}

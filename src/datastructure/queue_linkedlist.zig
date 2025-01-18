const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const queueError = error{ QueueFullException, QueueEmptyException };

pub fn Queue(comptime T: type) type {
    const MAX_SIZE: usize = 1024;
    return struct {
        items: []T,
        allocator: Allocator,
        size: usize,
        front: usize = 0,
        rear: usize = 0,

        pub fn init(allocator: Allocator, size: usize) !Queue(T) {
            return .{ .allocator = allocator, .items = try allocator.alloc(T, size), .size = size };
        }

        pub fn init_default(allocator: Allocator) !Queue(T) {
            return .{ .allocator = allocator, .items = try allocator.alloc(T, MAX_SIZE), .size = MAX_SIZE };
        }

        pub fn deinit(self: *Queue(T)) void {
            self.allocator.free(self.items);
        }

        pub fn getSize(self: *Queue(T)) usize {
            std.debug.print("Queue state: rear={d} front={d} size={d}\n", .{ self.rear, self.front, self.size });
            return ((self.rear + self.size) - self.front) % self.size;
        }

        pub fn isEmpty(self: *Queue(T)) bool {
            return self.rear == self.front;
        }

        pub fn enqueue(self: *Queue(T), element: T) !void {
            if (getSize(self) == self.size - 1) return queueError.QueueFullException;
            self.items[self.rear] = element;
            self.rear = (self.rear + 1) % self.size;
        }

        pub fn dequeue(self: *Queue(T)) !T {
            if (isEmpty(self)) return queueError.QueueEmptyException;
            const result = self.items[self.front];
            self.front = (self.front + 1) % self.size;
            return result;
        }

        pub fn peek(self: *Queue(T)) !T {
            if (isEmpty(self)) return queueError.QueueEmptyException;
            const result = self.items[self.front];
            return result;
        }
    };
}

test "queue initialization" {
    // Test custom size init
    var queue = try Queue(i32).init(testing.allocator, 5);
    defer queue.deinit();
    try testing.expectEqual(@as(usize, 5), queue.size);
    try testing.expect(queue.isEmpty());

    // Test default size init
    var default_queue = try Queue(i32).init_default(testing.allocator);
    defer default_queue.deinit();
    try testing.expectEqual(@as(usize, 1024), default_queue.size);
    try testing.expect(default_queue.isEmpty());
}

test "queue enqueue operations" {
    var queue = try Queue(i32).init(testing.allocator, 4);
    defer queue.deinit();

    try queue.enqueue(10);
    try testing.expectEqual(@as(usize, 1), queue.getSize());
    try testing.expectEqual(@as(i32, 10), try queue.peek());

    try queue.enqueue(20);
    try queue.enqueue(30);
    try testing.expectEqual(@as(usize, 3), queue.getSize());

    // Test queue full condition
    try testing.expectError(error.QueueFullException, queue.enqueue(40));
}

test "queue dequeue operations" {
    var queue = try Queue(i32).init(testing.allocator, 3);
    defer queue.deinit();

    // Test empty queue dequeue
    try testing.expectError(error.QueueEmptyException, queue.dequeue());

    try queue.enqueue(10);
    try queue.enqueue(20);

    try testing.expectEqual(@as(i32, 10), try queue.dequeue());
    try testing.expectEqual(@as(i32, 20), try queue.peek());
    try testing.expectEqual(@as(usize, 1), queue.getSize());
}

test "queue circular behavior" {
    var queue = try Queue(i32).init(testing.allocator, 4);
    defer queue.deinit();

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);
    _ = try queue.dequeue();
    _ = try queue.dequeue();

    // Should be able to enqueue after dequeue
    try queue.enqueue(4);
    try queue.enqueue(5);
    try testing.expectEqual(@as(i32, 3), try queue.dequeue());
    try testing.expectEqual(@as(i32, 4), try queue.dequeue());
}

test "queue peek operations" {
    var queue = try Queue(i32).init(testing.allocator, 3);
    defer queue.deinit();

    try testing.expectError(error.QueueEmptyException, queue.peek());

    try queue.enqueue(10);
    try testing.expectEqual(@as(i32, 10), try queue.peek());

    // Peek shouldn't remove the element
    try testing.expectEqual(@as(i32, 10), try queue.peek());
    try testing.expectEqual(@as(usize, 1), queue.getSize());
}

test "queue comprehensive test suite" {
    // Init tests
    var queue = try Queue(i32).init(testing.allocator, 4);
    defer queue.deinit();
    
    try testing.expect(queue.isEmpty());
    try testing.expectEqual(@as(usize, 0), queue.getSize());

    // Basic operations
    try queue.enqueue(10);
    try testing.expectEqual(@as(usize, 1), queue.getSize());
    try testing.expectEqual(@as(i32, 10), try queue.peek());

    // Fill queue
    try queue.enqueue(20);
    try queue.enqueue(30);
    try testing.expectEqual(@as(usize, 3), queue.getSize());

    // Test circular behavior
    _ = try queue.dequeue();  // Remove 10
    _ = try queue.dequeue();  // Remove 20
    try queue.enqueue(40);    // Should wrap around
    try queue.enqueue(50);    // Should fit
    try testing.expectEqual(@as(i32, 30), try queue.peek());
    
    // Test full queue
    try testing.expectError(error.QueueFullException, queue.enqueue(60));

    // Test empty queue
    _ = try queue.dequeue();  // Remove 30
    _ = try queue.dequeue();  // Remove 40
    _ = try queue.dequeue();  // Remove 50
    try testing.expect(queue.isEmpty());
    try testing.expectError(error.QueueEmptyException, queue.dequeue());
    try testing.expectError(error.QueueEmptyException, queue.peek());
}

test "queue stress test" {
    var queue = try Queue(i32).init(testing.allocator, 4);
    defer queue.deinit();

    // Repeated enqueue/dequeue cycles
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try queue.enqueue(@intCast(i));
        try queue.enqueue(@intCast(i + 1));
        _ = try queue.dequeue();
        try testing.expectEqual(@as(usize, 1), queue.getSize());
        _ = try queue.dequeue();
        try testing.expect(queue.isEmpty());
    }
}

test "queue boundary conditions" {
    var queue = try Queue(i32).init(testing.allocator, 3);
    defer queue.deinit();

    // Test single element
    try queue.enqueue(42);
    try testing.expectEqual(@as(i32, 42), try queue.peek());
    try testing.expectEqual(@as(i32, 42), try queue.dequeue());
    
    // Test wrap-around with minimal size
    try queue.enqueue(1);
    try queue.enqueue(2);
    _ = try queue.dequeue();
    try queue.enqueue(3);
    try testing.expectEqual(@as(i32, 2), try queue.dequeue());
    try testing.expectEqual(@as(i32, 3), try queue.dequeue());
}

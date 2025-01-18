const std = @import("std");
const testing = std.testing;

const LinkedLiatError = error{ IndexNotExistException, QueueEmptyException };

pub fn LinkedList(comptime T: type) type {
    return struct {
        head: *Node(T),
        tail: *Node(T),
        size: usize,

        pub fn init() LinkedList(T) {
            return .{ .head = undefined, .tail = undefined, .size = 0 };
        }

        pub fn deinit(self: *LinkedList(T)) void {
            self.head = undefined;
            self.tail = undefined;
            self.size = 0;
        }

        pub fn clear(self: *LinkedList(T)) void {
            self.deinit();
        }

        pub fn isEmpty(self: *LinkedList(T)) bool{
            return self.head == undefined;
        }

        pub fn add(self: *LinkedList(T), element: T) !void {
            if (self.head == undefined and self.tail == undefined) {
                self.head = *Node(T).init(element);
                self.tail = self.head;
            } else {
                self.tail.setNext(*Node(T).init(element));
            }
            self.size += 1;
        }

        pub fn getSize(self: *LinkedList(T)) usize {
            return self.size;
        }

        pub fn get(self: *LinkedList(T), index: usize) ?T {
            if (index >= self.getSize()) return LinkedLiatError.IndexNotExistException;
            var current = self.head;
            var counter: usize = 0;
            while (current != undefined) {
                if (counter == index) {
                    return current.data;
                }
                current = current.next;
                counter += 1;
            }
            return undefined;
        }

        pub fn set(self: *LinkedList(T), index: usize, newData: T) void {
            if (index >= self.getSize()) return LinkedLiatError.IndexNotExistException;
            var current = self.head;
            var counter: usize  = 0;
            while (current != undefined) {
                if (counter == index) {
                    current.data = newData;
                    break;
                }
                current = current.next;
                counter += 1;
            }
        }

        pub fn remove(self: *LinkedList(T), index: usize) !void {
            if (index >= self.getSize()) return LinkedLiatError.IndexNotExistException;
            var current = self.head;
            var counter: usize  = 0;
            while (current != undefined) {
                if (counter == index) {
                    current.next = current.next.next;
                    break;
                }
                current = current.next;
                counter += 1;
            }
        }
    };
}

pub fn Node(comptime T: type) type {
    return struct {
        data: T,
        next: *Node(T),

        pub fn init(data: T) Node(T) {
            return .{ .data = data, .next = undefined };
        }

        pub fn getData(self: *Node(T)) T {
            return self.data;
        }

        pub fn getNext(self: *Node(T)) ?*Node(T) {
            return self.next;
        }

        pub fn setNext(self: *Node(T), next: *Node(T)) void {
            self.next = next;
        }
    };
}

test "LinkedList - Basic Operations" {
    var list = LinkedList(i32).init();
    defer list.deinit();

    // Test initial state
    try testing.expect(list.isEmpty());
    try testing.expectEqual(@as(usize, 0), list.size);
    try testing.expect(list.head == undefined);
    try testing.expect(list.tail == undefined);

    // Test add operations
    try list.add(10);
    try testing.expectEqual(@as(usize, 1), list.size);
    try testing.expectEqual(@as(i32, 10), list.head.?.data);

    try list.add(20);
    try testing.expectEqual(@as(usize, 2), list.size);
    try testing.expectEqual(@as(i32, 20), list.tail.?.data);
}

test "LinkedList - Remove Operations" {
    var list = LinkedList(i32).init();
    defer list.deinit();

    // Setup
    try list.add(10);
    try list.add(20);
    try list.add(30);

    // Test remove
    const removed = try list.remove();
    try testing.expectEqual(@as(i32, 30), removed);
    try testing.expectEqual(@as(usize, 2), list.size);
}

test "LinkedList - Edge Cases" {
    var list = LinkedList(i32).init();
    defer list.deinit();

    // Empty list operations
    try testing.expect(list.isEmpty());
    try testing.expectError(error.EmptyList, list.remove(0));

    // Single element
    try list.add(10);
    try testing.expectEqual(@as(usize, 1), list.size);
    try testing.expectEqual(list.head, list.tail);

    // Clear operation
    list.clear();
    try testing.expect(list.isEmpty());
}

test "LinkedList - Multiple Operations" {
    var list = LinkedList(i32).init();
    defer list.deinit();

    // Add multiple elements
    const items = [_]i32{ 10, 20, 30, 40, 50 };
    for (items) |item| {
        try list.add(item);
    }
    try testing.expectEqual(@as(usize, 5), list.size);

    // Remove all elements
    while (!list.isEmpty()) {
        _ = try list.remove();
    }
    try testing.expect(list.isEmpty());
}

test "LinkedList - Stress Test" {
    var list = LinkedList(i32).init();
    defer list.deinit();

    // Add many elements
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        try list.add(@intCast(i));
    }
    try testing.expectEqual(@as(usize, 1000), list.size);

    // Remove all elements
    i = 0;
    while (i < 1000) : (i += 1) {
        _ = try list.remove();
    }
    try testing.expect(list.isEmpty());
}

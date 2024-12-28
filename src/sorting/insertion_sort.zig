const std = @import("std");
const testing = std.testing;

pub fn sort(ip: []usize) []usize {
    if (ip.len == 0) return ip;
    for (1..ip.len) |j| {
        const key: usize = ip[j];
        var i: usize = j - 1;
        while (i >= 0 and ip[i] > key) : (i -= 1) {
            ip[i + 1] = ip[i];
            ip[i] = key;

            if (i == 0) break;
        }
    }
    return ip;
}

test "insertion sort with empty array" {
    const arr: []usize = &[_]usize{};
    const sorted = sort(arr);
    try std.testing.expectEqualSlices(usize, &[_]usize{}, sorted);
}

test "insertion sort with single element" {
    var arr = [_]usize{1};
    try std.testing.expectEqualSlices(usize, &[_]usize{1}, sort(&arr));
}

test "insertion sort with sorted array" {
    var arr = [_]usize{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqualSlices(usize, &[_]usize{ 1, 2, 3, 4, 5 }, sort(&arr));
}

test "insertion sort with reverse sorted array" {
    var arr = [_]usize{ 5, 4, 3, 2, 1 };
    try std.testing.expectEqualSlices(usize, &[_]usize{ 1, 2, 3, 4, 5 }, sort(&arr));
}

test "insertion sort with random array" {
    var arr = [_]usize{ 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5 };
    try std.testing.expectEqualSlices(usize, &[_]usize{ 1, 1, 2, 3, 3, 4, 5, 5, 5, 6, 9 }, sort(&arr));
}

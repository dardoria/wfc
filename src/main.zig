const std = @import("std");
const m = @import("model.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var model = try m.Model.new(allocator, 20, 30, 3, true, m.Heuristic.Entropy);
    defer model.deinit();

    std.debug.print("Model created successfully\n", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}

const std = @import("std");
const bb = @import("bitboard.zig");
const attacks = @import("attacks.zig");

pub fn main() anyerror!void {
    // Note that info level log messages are by default printed only in Debug
    // and ReleaseSafe build modes.
    std.log.info("{}", .{bb.southWest(1)});
    const r = attacks.slidingAttack(1, .north, 0);
    std.log.info("All your codebase are belong to us.", .{});
    bb.display(r);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}

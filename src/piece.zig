const std = @import("std");

pub const Piece = enum {
    pawn,
    rook,
    knight,
    bishop,
    queen,
    king,

    pub fn format(self: Piece, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        const c: u8 = switch (self) {
            .pawn => 'p',
            .rook => 'r',
            .knight => 'n',
            .bishop => 'b',
            .queen => 'q',
            .king => 'k',
        };
        try writer.print("{c}", .{c});
    }
};

const std = @import("std");
const Color = @import("color.zig").Color;
const CastleRights = @import("castle.zig").CastleRights;

pub const Square = enum(u6) {
    // zig fmt: off
    A1, B1, C1, D1, E1, F1, G1, H1,
    A2, B2, C2, D2, E2, F2, G2, H2,
    A3, B3, C3, D3, E3, F3, G3, H3,
    A4, B4, C4, D4, E4, F4, G4, H4,
    A5, B5, C5, D5, E5, F5, G5, H5,
    A6, B6, C6, D6, E6, F6, G6, H6,
    A7, B7, C7, D7, E7, F7, G7, H7,
    A8, B8, C8, D8, E8, F8, G8, H8,
    // zig fmt: on

    pub fn toIndex(self: Square) u6 {
        return @enumToInt(self) + @enumToInt(self) / 7;
    }

    pub fn format(self: Square, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        var name = [2]u8{ 0, 0 };
        for (@tagName(self)) |n, i| {
            name[i] = std.ascii.toLower(n);
        }
        try writer.print("{s}", .{name});
    }
};

pub fn cornerOf(castle: CastleRights, color: Color) Square {
    const sq: u6 = switch (castle) {
        .kingside => 7,
        .queenside => 0,
        else => @panic("nonsense castle"),
    };
    return @intToEnum(Square, switch (color) {
        .white => sq,
        .black => sq ^ 56,
    });
}

pub fn below(sq: u6, turn: Color) Square {
    return switch (turn) {
        .white => @intToEnum(Square, sq - 8),
        .black => @intToEnum(Square, sq + 8),
    };
}

pub fn rightBelow(sq: u6, turn: Color) Square {
    return switch (turn) {
        .white => @intToEnum(Square, sq - 7),
        .black => @intToEnum(Square, sq + 7),
    };
}

pub fn leftBelow(sq: u6, turn: Color) Square {
    return switch (turn) {
        .white => @intToEnum(Square, sq - 9),
        .black => @intToEnum(Square, sq + 9),
    };
}

pub fn doubleBelow(sq: u6, turn: Color) Square {
    return switch (turn) {
        .white => @intToEnum(Square, sq - 16),
        .black => @intToEnum(Square, sq + 16),
    };
}

const Color = @import("color.zig").Color;
const Square = @import("square.zig").Square;

const castle_from_square = [2][64]u2{
    .{
        2, 0, 0, 0, 3, 0, 0, 1, // 1
        0, 0, 0, 0, 0, 0, 0, 0, // 2
        0, 0, 0, 0, 0, 0, 0, 0, // 3
        0, 0, 0, 0, 0, 0, 0, 0, // 4
        0, 0, 0, 0, 0, 0, 0, 0, // 5
        0, 0, 0, 0, 0, 0, 0, 0, // 6
        0, 0, 0, 0, 0, 0, 0, 0, // 7
        0, 0, 0, 0, 0, 0, 0, 0, // 8
    },
    .{
        0, 0, 0, 0, 0, 0, 0, 0, // 1
        0, 0, 0, 0, 0, 0, 0, 0, // 2
        0, 0, 0, 0, 0, 0, 0, 0, // 3
        0, 0, 0, 0, 0, 0, 0, 0, // 4
        0, 0, 0, 0, 0, 0, 0, 0, // 5
        0, 0, 0, 0, 0, 0, 0, 0, // 6
        0, 0, 0, 0, 0, 0, 0, 0, // 7
        2, 0, 0, 0, 3, 0, 0, 1, // 8
    },
};

pub const CastleRights = enum(u2) {
    none,
    kingside,
    queenside,
    both,

    pub fn fromIndex(color: Color, sq: u6) CastleRights {
        return @intToEnum(CastleRights, castle_from_square[@enumToInt(color)][sq]);
    }

    pub fn add(self: *CastleRights, other: CastleRights) void {
        const i = @enumToInt(self.*);
        const o = @enumToInt(other);

        self.* = @intToEnum(CastleRights, i | o);
    }

    pub fn remove(self: *CastleRights, other: CastleRights) void {
        const i = @enumToInt(self.*);
        const o = @enumToInt(other);

        self.* = @intToEnum(CastleRights, i & ~o);
    }
};

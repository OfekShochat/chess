const Color = @import("color.zig").Color;
const CastleRights = @import("castle.zig").CastleRights;

pub const Board = struct {
    turn: Color,
    white: u64,
    black: u64,
    pieces: [7]u64 = [1]u64{0} ** 7,
    white_castling: CastleRights,
    black_castling: CastleRights,

    pub fn canCastle(self: Board, right: CastleRights) bool {
        return switch (self.turn) {
            .white => @enumToInt(self.white_castling) & @enumToInt(right),
            .black => @enumToInt(self.black_castling) & @enumToInt(right),
        } > 0;
    }
};

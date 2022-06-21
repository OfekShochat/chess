const std = @import("std");
const attacks = @import("attacks.zig");
const bb = @import("bitboard.zig");
const Board = @import("board.zig").Board;
const Piece = @import("piece.zig").Piece;
const CastleRights = @import("castle.zig").CastleRights;
const Square = @import("square.zig").Square;

pub const Move = struct {
    from: Square = Square.A1,
    to: Square = Square.A1,
    mover: Piece,
    capture: ?Piece = null,
    double_move: bool = false,
    en_passant: bool = false,
    castle: ?CastleRights = null,
    promotion: ?Piece = null,

    fn capture(from: Square, to: Square, mover: Piece, target: Piece) Move {
        return .{
            .from = from,
            .to = to,
            .mover = mover,
            .capture = target,
        };
    }

    fn castle_move(right: CastleRights) Move {
        return .{
            .mover = .King,
            .castle = right,
        };
    }

    pub fn format(self: Move, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        if (self.promotion) |promotion| {
            try writer.print("{}{}{s}", .{ self.from, self.to, promotion });
        } else if (self.castle) |castle| {
            switch (castle) {
                .kingside => try writer.print("{}{}", .{ self.from, @intToEnum(Square, @enumToInt(self.from) + 2) }),
                .queenside => try writer.print("{}{}", .{ self.from, @intToEnum(Square, @enumToInt(self.from) - 3) }),
                else => @panic("cannot {} castle"),
            }
        } else {
            try writer.print("{}{}", .{ self.from, self.to });
        }
    }
};

pub const MoveList = struct {
    moves: [256]Move,
    index: u8,

    pub fn init() MoveList {
        return .{
            .moves = [1]Move{Move{}} ** 256,
            .index = 0,
        };
    }

    pub fn push(self: *MoveList, move: Move) void {
        self.moves[self.index] = move;
        self.index += 1;
    }

    pub fn clear(self: *MoveList) void {
        self.moves = [1]Move{Move{}} ** 256;
        self.index = 0;
    }

    pub fn format(self: MoveList, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("MoveList{{ .moves = {any}, .index = {} }}", .{ self.moves[0..self.index], self.index });
    }
};

pub fn attackMoves(board: Board, comptime mover: Piece, move_list: *MoveList) void {
    var left = board.boardOf(mover) & board.getBoard(board.turn);
    while (left != 0) : (left = bb.reset(left)) {
        const sq = bb.bsf(left);

        var as = attacks.attacksOf(mover, sq, board.black | board.white) & ~board.getBoard(board.turn);
        while (as != 0) : (attacks = bb.reset(as)) {
            const to_sq = bb.bsf(as);
            move_list.add(Move.capture(sq, to_sq, mover, board.pieceOn(to_sq)));
        }
    }

    if (mover == .King) {
        if (board.canCastle(.kingside)) {
            move_list.add(Move.castle_move(.kingside));
        }
        if (board.canCastle(.queenside)) {
            move_list.add(Move.castle_move(.queenside));
        }
    }
}

const std = @import("std");
const attacks = @import("attacks.zig");
const magics = @import("magics.zig");
const bb = @import("bitboard.zig");
const Board = @import("board.zig").Board;
const Piece = @import("piece.zig").Piece;
const CastleRights = @import("castle.zig").CastleRights;
const square = @import("square.zig");
const Square = square.Square;
const Rank = @import("rank.zig").Rank;

pub const Move = struct {
    from: Square = Square.A1,
    to: Square = Square.A1,
    mover: Piece,
    capture: ?Piece = null,
    is_double: bool = false,
    is_enpass: bool = false,
    castle: ?CastleRights = null,
    promotion: ?Piece = null,

    fn capture(from: Square, to: Square, mover: Piece, target: ?Piece) Move {
        return .{
            .from = from,
            .to = to,
            .mover = mover,
            .capture = target,
        };
    }

    fn castle_move(right: CastleRights) Move {
        return .{
            .mover = .king,
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
            .moves = [1]Move{Move{ .mover = .king }} ** 256,
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

pub fn move_gen(board: *Board, move_list: *MoveList) void {
    attackMoves(board, .king, move_list);
    attackMoves(board, .knight, move_list);
    attackMoves(board, .bishop, move_list);
    attackMoves(board, .queen, move_list);
    attackMoves(board, .rook, move_list);
    pawnMoves(board, move_list);
}

pub fn attackMoves(board: *Board, comptime mover: Piece, move_list: *MoveList) void {
    var left = board.boardOf(mover) & board.us();
    while (left != 0) : (left = bb.reset(left)) {
        const sq = bb.bsf(left);

        var as = attacks.attacksOf(mover, sq, board.white | board.black) & ~board.us();
        if (mover == .queen) {}
        while (as != 0) : (as = bb.reset(as)) {
            const to_sq = bb.bsf(as);
            move_list.push(Move.capture(@intToEnum(Square, sq), @intToEnum(Square, to_sq), mover, board.pieceOn(to_sq)));
        }
    }

    if (mover == .king) {
        const kingside = magics.castleBlocksOf(board.turn, .kingside);
        const queenside = magics.castleBlocksOf(board.turn, .queenside);
        if (board.canCastle(.kingside) and kingside & (board.white | board.black) == 0) {
            move_list.push(Move.castle_move(.kingside));
        }
        if (board.canCastle(.queenside) and queenside & (board.white | board.black) == 0) {
            move_list.push(Move.castle_move(.queenside));
        }
    }
}

pub fn pawnMoves(board: *Board, move_list: *MoveList) void {
    const us = board.pawns & board.us();
    var en_pass = bb.fromSquare(board.en_pass);
    const targets = en_pass | board.them();
    const eighth = switch (board.turn) {
        .white => bb.fromRank(Rank.eighth),
        .black => bb.fromRank(Rank.first),
    };
    const second = switch (board.turn) {
        .white => bb.fromRank(Rank.second),
        .black => bb.fromRank(Rank.seventh),
    };

    var left_captures = bb.upLeft(us, board.turn) & targets & ~eighth;
    var right_captures = bb.upRight(us, board.turn) & targets & ~eighth;

    var forward = bb.up(us, board.turn) & ~(board.white | board.black | eighth);
    var double = bb.up(bb.up(us & second, board.turn) & ~(board.white | board.black), board.turn) & ~(board.white | board.black);
    var promotions = (forward | left_captures | right_captures) & eighth;

    while (left_captures != 0) : (left_captures = bb.reset(left_captures)) {
        const t = bb.bsf(left_captures);
        move_list.push(
            Move{
                .from = square.rightBelow(t, board.turn),
                .to = @intToEnum(Square, t),
                .mover = .pawn,
                .capture = board.pieceOn(t),
                .is_enpass = t == board.en_pass,
            },
        );
    }

    while (right_captures != 0) : (right_captures = bb.reset(right_captures)) {
        const t = bb.bsf(right_captures);
        move_list.push(
            Move{
                .from = square.leftBelow(t, board.turn),
                .to = @intToEnum(Square, t),
                .mover = .pawn,
                .capture = board.pieceOn(t),
                .is_enpass = t == board.en_pass,
            },
        );
    }

    if (promotions != 0) {
        var forward_proms = bb.up(us, board.turn) & ~targets & eighth;
        var left_proms = bb.upLeft(us, board.turn) & targets & eighth;
        var right_proms = bb.upRight(us, board.turn) & targets & eighth;

        while (forward_proms != 0) : (forward_proms = bb.reset(forward_proms)) {
            const t = bb.bsf(forward_proms);
            const from = square.below(t, board.turn);
            const to = @intToEnum(Square, t);
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .queen,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .rook,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .bishop,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .knight,
            });
        }

        while (left_proms != 0) : (left_proms = bb.reset(left_proms)) {
            const t = bb.bsf(left_proms);
            const from = square.rightBelow(t, board.turn);
            const to = @intToEnum(Square, t);
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .queen,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .rook,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .bishop,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .knight,
            });
        }

        while (right_proms != 0) : (right_proms = bb.reset(right_proms)) {
            const t = bb.bsf(right_proms);
            const from = square.leftBelow(t, board.turn);
            const to = @intToEnum(Square, t);
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .queen,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .rook,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .bishop,
            });
            move_list.push(Move{
                .from = from,
                .to = to,
                .mover = .pawn,
                .promotion = .knight,
            });
        }
    }

    while (forward != 0) : (forward = bb.reset(forward)) {
        const t = bb.bsf(forward);
        move_list.push(
            Move.capture(square.below(t, board.turn), @intToEnum(Square, t), .pawn, null),
        );
    }

    while (double != 0) : (double = bb.reset(double)) {
        const t = bb.bsf(double);
        move_list.push(
            Move{
                .from = square.doubleBelow(t, board.turn),
                .to = @intToEnum(Square, t),
                .mover = .pawn,
                .is_double = true,
            },
        );
    }
}

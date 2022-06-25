const std = @import("std");
const toLower = std.ascii.toLower;
const isUpper = std.ascii.isUpper;

const bb = @import("bitboard.zig");
const Color = @import("color.zig").Color;
const CastleRights = @import("castle.zig").CastleRights;
const Piece = @import("piece.zig").Piece;
const Move = @import("movegen.zig").Move;

pub const Board = struct {
    turn: Color,
    white: u64,
    black: u64,
    pawns: u64,
    knights: u64,
    bishops: u64,
    rooks: u64,
    queens: u64,
    kings: u64,
    attacks: u64,
    piece_map: [64]?Piece,
    white_castling: CastleRights,
    black_castling: CastleRights,

    fn empty() Board {
        return .{
            .turn = .white,
            .white = 0,
            .black = 0,
            .pawns = 0,
            .knights = 0,
            .bishops = 0,
            .rooks = 0,
            .queens = 0,
            .kings = 0,
            .attacks = 0,
            .piece_map = [1]?Piece{null} ** 64,
            .white_castling = .none,
            .black_castling = .none,
        };
    }

    pub fn fromFen(fen: []const u8) !Board {
        var board = Board.empty();
        var rank: u6 = 8;
        var file: u6 = 0;
        var ranks = std.mem.tokenize(u8, fen, "/");

        while (ranks.next()) |r| {
            for (r) |p| {
                switch (p) {
                    '0'...'8' => file += @intCast(u4, p - '0'),
                    else => {
                        const piece = switch (toLower(p)) {
                            'k' => Piece.king,
                            'p' => .pawn,
                            'n' => .knight,
                            'b' => .bishop,
                            'r' => .rook,
                            else => return error.InvalidPiece,
                        };
                        const color = if (isUpper(p)) Color.white else .black;

                        board.set(piece, color, (rank - 1) * 8 + file);

                        file += 1;
                    },
                }
                if (file > 8) {
                    return error.TooManySquares;
                }
            }
            if (rank == 0) break;

            rank -= 1;
            file = 0;
        }
        return board;
    }

    pub fn makemove(self: Board, move: Move) !Board {
        var board = self;
        board.turn = self.turn.opposite();

        const from = @enumToInt(move.from);
        const to = @enumToInt(move.to);

        board.set(move.mover, self.turn, to);
        board.unset(self.pieceOn(to).?, board.turn, from);
        if (move.capture) |c| {
            board.unset(c, board.turn, to);
        }

        if (move.mover == .pawn) {
            board.unset(
                .pawn,
                board.turn,
                to ^ 8,
            );
        }

        if (self.attacks & (self.kings & self.us()) > 0) {
            return error.NotLegal;
        } else {
            return board;
        }
    }

    fn set(self: *Board, piece: Piece, color: Color, sq: u6) void {
        self.piece_map[sq] = piece;
        switch (piece) {
            .pawn => self.pawns = bb.setAt(self.pawns, sq),
            .rook => self.rooks = bb.setAt(self.rooks, sq),
            .knight => self.knights = bb.setAt(self.knights, sq),
            .bishop => self.bishops = bb.setAt(self.bishops, sq),
            .queen => self.queens = bb.setAt(self.queens, sq),
            .king => self.kings = bb.setAt(self.kings, sq),
        }
        switch (color) {
            .white => self.white = bb.setAt(self.white, sq),
            .black => self.black = bb.setAt(self.black, sq),
        }
    }

    fn unset(self: *Board, piece: Piece, color: Color, sq: u6) void {
        self.piece_map[sq] = null;
        switch (piece) {
            .pawn => self.pawns = bb.removeAt(self.pawns, sq),
            .rook => self.rooks = bb.removeAt(self.rooks, sq),
            .knight => self.knights = bb.removeAt(self.knights, sq),
            .bishop => self.bishops = bb.removeAt(self.bishops, sq),
            .queen => self.queens = bb.removeAt(self.queens, sq),
            .king => self.kings = bb.removeAt(self.kings, sq),
        }
        switch (color) {
            .white => self.white = bb.removeAt(self.white, sq),
            .black => self.black = bb.removeAt(self.black, sq),
        }
    }

    pub fn pieceOn(self: Board, sq: u6) ?Piece {
        return self.piece_map[sq];
    }

    pub fn us(self: Board) u64 {
        return switch (self.turn) {
            .white => self.white,
            .black => self.black,
        };
    }

    pub fn them(self: Board) u64 {
        return switch (self.turn) {
            .white => self.black,
            .black => self.white,
        };
    }

    pub fn boardOf(self: Board, piece: Piece) u64 {
        return switch (piece) {
            .pawn => self.pawns,
            .rook => self.rooks,
            .knight => self.knights,
            .bishop => self.bishops,
            .queen => self.queens,
            .king => self.kings,
        };
    }

    pub fn canCastle(self: Board, right: CastleRights) bool {
        return switch (self.turn) {
            .white => @enumToInt(self.white_castling) & @enumToInt(right),
            .black => @enumToInt(self.black_castling) & @enumToInt(right),
        } > 0;
    }
};

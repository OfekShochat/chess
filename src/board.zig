const std = @import("std");
const toLower = std.ascii.toLower;
const isUpper = std.ascii.isUpper;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const bb = @import("bitboard.zig");
const zobrist = @import("zobrist.zig");
const magics = @import("magics.zig");
const attacks = @import("attacks.zig");
const Color = @import("color.zig").Color;
const CastleRights = @import("castle.zig").CastleRights;
const Piece = @import("piece.zig").Piece;
const Move = @import("movegen.zig").Move;
const isAttacked = attacks.isAttacked;
const allAttacks = attacks.allAttacks;

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
    piece_map: [64]?Piece,
    en_pass: u6,
    white_castling: CastleRights,
    black_castling: CastleRights,
    hash_stack: ArrayList(u64),
    hash: u64,
    half_moves: u8,

    fn empty(allocator: Allocator) !Board {
        return Board{
            .turn = .white,
            .white = 0,
            .black = 0,
            .pawns = 0,
            .knights = 0,
            .bishops = 0,
            .rooks = 0,
            .queens = 0,
            .kings = 0,
            .piece_map = [1]?Piece{null} ** 64,
            .en_pass = 0,
            .hash = 0,
            .white_castling = .none,
            .black_castling = .none,
            .hash_stack = try ArrayList(u64).initCapacity(allocator, 256),
            .half_moves = 0,
        };
    }

    pub fn deinit(self: *Board) void {
        self.hash_stack.deinit();
    }

    pub fn fromFen(fen: []const u8, allocator: Allocator) !Board {
        var board = try Board.empty(allocator);
        var parts = std.mem.tokenize(u8, fen, " ");

        try board.setupBoard(parts.next() orelse return error.IncompleteFen);

        if (parts.next()) |c| {
            board.turn = switch (c[0]) {
                'w' => .white,
                'b' => .black,
                else => return error.InvalidColor,
            };
            if (board.turn == .white) {
                board.hash ^= zobrist.side;
            }
        }

        try board.setupCastling(parts.next() orelse return error.IncompleteFen);

        if (parts.next()) |sq| {
            if (sq[0] != '-') {
                board.en_pass = @intCast(u6, (sq[1] - '1') * 8 + sq[0] - 'a');
                board.hash ^= zobrist.en_pass[board.en_pass];
            }
        } else {
            return error.IncompleteFen;
        }

        _ = parts.next(); // fullmoves
        const halfbuf = parts.next() orelse return error.IncompleteFen;
        board.half_moves = try std.fmt.parseUnsigned(u8, halfbuf, 10);

        return board;
    }

    fn setupBoard(board: *Board, pieces: []const u8) !void {
        var rank: u6 = 8;
        var file: u6 = 0;
        var ranks = std.mem.tokenize(u8, pieces, "/");

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
                            'q' => .queen,
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
    }

    fn setupCastling(board: *Board, rights: []const u8) !void {
        if (rights[0] == '-') return; // none

        for (rights) |r| {
            switch (r) {
                'K' => board.white_castling.add(.kingside),
                'k' => board.black_castling.add(.kingside),
                'Q' => board.white_castling.add(.queenside),
                'q' => board.black_castling.add(.queenside),
                else => return error.InvalidCastleRights,
            }
        }
        board.hash ^= zobrist.castles[@enumToInt(board.white_castling) | @intCast(u4, @enumToInt(board.black_castling)) << 2];
    }

    pub fn switchSides(self: *Board) void {
        self.hash ^= zobrist.side;
        self.turn = self.turn.opposite();
    }

    pub fn makemove(self: Board, move: Move) !Board {
        var board = self;
        board.switchSides();
        board.half_moves += 1;
        board.en_pass = 0;

        const from = @enumToInt(move.from);
        const to = @enumToInt(move.to);

        board.hash ^= zobrist.en_pass[self.en_pass]; // reset en passant

        if (move.castle) |c| {
            switch (c) {
                .kingside => {
                    board.unset();
                },
            }
            const as = allAttacks(board);
            if (as & self.kings & self.us() > 0) {
                return error.NotLegal;
            } else {
                return board;
            }
        }

        if (move.capture) |c| {
            board.unset(c, board.turn, to);
        }
        board.set(move.mover, self.turn, to);
        board.unset(move.mover, self.turn, from);

        if (move.mover == .pawn) {
            if (move.is_enpass) {
                board.unset(
                    .pawn,
                    board.turn,
                    to ^ 8,
                );
            } else if (move.is_double) {
                board.en_pass = to ^ 8;
                board.hash ^= zobrist.en_pass[board.en_pass];
            }
        }

        if (isAttacked(board.kings & board.them(), board)) {
            return error.NotLegal;
        } else {
            return board;
        }
    }

    pub fn isDraw(self: Board) bool {
        if (self.half_moves >= 100) return true;
        if (std.mem.len(self.hash_stack.items) > 1) {
            var index: i16 = @intCast(i16, std.mem.len(self.hash_stack.items));
            var limit = index - self.half_moves - 1;
            var count: u8 = 0;
            while (index >= limit and index >= 0) {
                if (self.hash_stack.items[@intCast(usize, index)] == self.hash) {
                    count += 1;
                    return true;
                }
                index -= 2;
            }
        }
        return false;
    }

    fn set(self: *Board, piece: Piece, color: Color, sq: u6) void {
        self.hash ^= zobrist.pieces[@enumToInt(color)][@enumToInt(piece)][sq];
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
        self.hash ^= zobrist.pieces[@enumToInt(color)][@enumToInt(piece)][sq];
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

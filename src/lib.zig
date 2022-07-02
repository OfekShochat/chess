pub const movegen = @import("movegen.zig");
pub const Move = movegen.Move;
pub const MoveList = movegen.MoveList;

const board = @import("board.zig");
pub const Board = board.Board;

pub const Square = @import("square.zig").Square;
pub const Color = @import("color.zig").Color;

pub const Piece = @import("piece.zig").Piece;

pub const startfen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

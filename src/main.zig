const std = @import("std");
const bb = @import("bitboard.zig");
const attacks = @import("attacks.zig");
const movegen = @import("movegen.zig");
const Board = @import("board.zig").Board;

const startpos: []const u8 = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

pub fn main() anyerror!void {
    attacks.initializeAttacks();
    var b = try Board.fromFen(startpos);
    var move_list = movegen.MoveList.init();
    movegen.move_gen(&b, &move_list);
    std.log.info("{}", .{move_list});
    std.log.info("{}", .{rootPerft(&b, 3)});
}

fn perft(board: *Board, d: usize) usize {
    if (d == 0) return 1;
    // if (board.isGameOver()) return 0;
    var move_list = movegen.MoveList.init();
    movegen.move_gen(board, &move_list);
    // std.log.info("{}", .{move_list});
    // if (d == 1) {
    //     return move_list.index;
    // }

    var nodes: usize = 0;
    var i: u8 = 0;
    while (i < move_list.index) : (i += 1) {
        var b = board.makemove(move_list.moves[i]) catch continue;
        nodes += perft(&b, d - 1);
    }

    return nodes;
}

fn rootPerft(board: *Board, d: usize) usize {
    if (d == 0) return 1;
    // if (board.isGameOver()) return 0;
    var move_list = movegen.MoveList.init();
    movegen.move_gen(board, &move_list);
    // if (d == 1) {
    //     return move_list.index;
    // }

    var nodes: usize = 0;
    var i: u8 = 0;
    while (i < move_list.index) : (i += 1) {
        var b = board.makemove(move_list.moves[i]) catch continue;
        const r = perft(&b, d - 1);
        nodes += r;
        std.log.info("{}: {}", .{ move_list.moves[i], r });
    }

    return nodes;
}

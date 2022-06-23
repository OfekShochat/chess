const std = @import("std");
const bb = @import("bitboard.zig");
const attacks = @import("attacks.zig");
const movegen = @import("movegen.zig");
const Board = @import("board.zig").Board;

pub fn main() anyerror!void {
    // Note that info level log messages are by default printed only in Debug
    // and ReleaseSafe build modes.
    std.log.info("{}", .{bb.southWest(1)});
    const r = attacks.slidingAttack(1, .north, 0);
    std.log.info("All your codebase are belong to us.", .{});
    bb.display(r);
    const b = try Board.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR");
    var move_list = movegen.MoveList.init();
    movegen.move_gen(b, &move_list);
    std.log.info("{}", .{b});
    std.log.info("{}", .{move_list});
}

fn perft(board: Board, d: usize) usize {
    if (d == 0) return 1;
    if (board.isGameOver()) return 0;
    var move_list = movegen.MoveList.init();
    movegen.gen_moves(board, move_list);
    // if (d == 1) {
    //     return move_list.index;
    // }

    var nodes: usize = 0;
    var i: u8 = 0;
    while (i < move_list.index) : (i += 1) {
        const b = board.makeMove(move_list.moves[i]);
        nodes += perft(b, d - 1);
    }

    return nodes;
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}

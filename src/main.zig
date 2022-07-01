const std = @import("std");
const bb = @import("bitboard.zig");
const attacks = @import("attacks.zig");
const movegen = @import("movegen.zig");
const Board = @import("board.zig").Board;

const startpos: []const u8 = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

pub fn main() anyerror!void {
    attacks.initializeAttacks();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var b = try Board.fromFen(startpos, gpa.allocator());
    defer b.deinit();
    var move_list = movegen.MoveList.init();
    movegen.move_gen(&b, &move_list);
    std.debug.print("{}\n", .{move_list});
    std.debug.print("{}\n", .{rootPerft(&b, 7)});
}

fn perft(board: *Board, d: usize, debug: bool) usize {
    _ = debug;
    if (d == 0) return 1;
    // if (board.isDraw()) return 0;
    var move_list = movegen.MoveList.init();
    movegen.move_gen(board, &move_list);
    if (debug) {
        // std.debug.print("11 {}\n", .{move_list});
    }

    var nodes: usize = 0;
    var i: u8 = 0;
    while (i < move_list.index) : (i += 1) {
        var b = board.makemove(move_list.moves[i]) catch continue;
        nodes += perft(&b, d - 1, false);
        if (debug) {
            // std.debug.print("11 {}: {}\n", .{ move_list.moves[i], b });
        }
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
        const r = perft(&b, d - 1, move_list.moves[i].from == .F2 and move_list.moves[i].to == .G1 and move_list.moves[i].promotion.? == .rook);
        nodes += r;
        std.debug.print("{}: {}\n", .{ move_list.moves[i], r });
    }

    return nodes;
}

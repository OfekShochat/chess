const std = @import("std");
const fields = std.meta.fields;

const Piece = @import("piece.zig").Piece;
const Square = @import("square.zig").Square;
const Color = @import("color.zig").Color;

pub const side = rand64(42);

pub const en_pass = blk: {
    var rng_state: u64 = 13;
    var r = [1]u64{0} ** 64;

    var i: u8 = 8;
    while (i < 16) : (i += 1) {
        r[i] = rand64(rng_state);
    }
    i = 48;
    while (i < 56) : (i += 1) {
        r[i] = rand64(rng_state);
    }

    break :blk r;
};

pub const castles = blk: {
    var rng_state: u64 = 1094795585;
    var r = [1]u64{0} ** 8;

    var i: u8 = 0;
    while (i < 8) : (i += 1) {
        r[i] = rand64(rng_state);
    }

    break :blk r;
};

pub const pieces = blk: {
    @setEvalBranchQuota(1600);

    var rng_state: u64 = 1070372;
    var r = std.mem.zeroes([2][6][64]u64);

    inline for (fields(Color)) |c| {
        inline for (fields(Piece)) |p| {
            var i: u8 = 0;
            while (i < 64) : (i += 1) {
                r[c.value][p.value][i] = rand64(rng_state);
            }
        }
    }

    break :blk r;
};

fn rand64(seed: u64) u64 {
    var state = seed;
    state ^= state >> 12;
    state ^= state << 15;
    state ^= state >> 27;

    return state *% @intCast(u64, 2685821657736338717);
}

const bb = @import("bitboard.zig");
const magics = @import("magics.zig");

pub const rooks = generateAttackTable(4096, magics.rook_shifts, magics.rook_masks, magics.rook_magics, getRookOccupancies);
pub const bishops = generateAttackTable(512, magics.bishop_shifts, magics.bishop_masks, magics.bishop_magics, getBishopOccupancies);
// zig fmt: off
pub const kings = [64]u64{
    0x0000000000000302, 0x0000000000000705, 0x0000000000000e0a, 0x0000000000001c14,
    0x0000000000003828, 0x0000000000007050, 0x000000000000e0a0, 0x000000000000c040,
    0x0000000000030203, 0x0000000000070507, 0x00000000000e0a0e, 0x00000000001c141c,
    0x0000000000382838, 0x0000000000705070, 0x0000000000e0a0e0, 0x0000000000c040c0,
    0x0000000003020300, 0x0000000007050700, 0x000000000e0a0e00, 0x000000001c141c00,
    0x0000000038283800, 0x0000000070507000, 0x00000000e0a0e000, 0x00000000c040c000,
    0x0000000302030000, 0x0000000705070000, 0x0000000e0a0e0000, 0x0000001c141c0000,
    0x0000003828380000, 0x0000007050700000, 0x000000e0a0e00000, 0x000000c040c00000,
    0x0000030203000000, 0x0000070507000000, 0x00000e0a0e000000, 0x00001c141c000000,
    0x0000382838000000, 0x0000705070000000, 0x0000e0a0e0000000, 0x0000c040c0000000,
    0x0003020300000000, 0x0007050700000000, 0x000e0a0e00000000, 0x001c141c00000000,
    0x0038283800000000, 0x0070507000000000, 0x00e0a0e000000000, 0x00c040c000000000,
    0x0302030000000000, 0x0705070000000000, 0x0e0a0e0000000000, 0x1c141c0000000000,
    0x3828380000000000, 0x7050700000000000, 0xe0a0e00000000000, 0xc040c00000000000,
    0x0203000000000000, 0x0507000000000000, 0x0a0e000000000000, 0x141c000000000000,
    0x2838000000000000, 0x5070000000000000, 0xa0e0000000000000, 0x40c0000000000000
};

pub const knights = [64]u64{
    0x0000000000020400, 0x0000000000050800, 0x00000000000a1100, 0x0000000000142200,
    0x0000000000284400, 0x0000000000508800, 0x0000000000a01000, 0x0000000000402000,
    0x0000000002040004, 0x0000000005080008, 0x000000000a110011, 0x0000000014220022,
    0x0000000028440044, 0x0000000050880088, 0x00000000a0100010, 0x0000000040200020,
    0x0000000204000402, 0x0000000508000805, 0x0000000a1100110a, 0x0000001422002214,
    0x0000002844004428, 0x0000005088008850, 0x000000a0100010a0, 0x0000004020002040,
    0x0000020400040200, 0x0000050800080500, 0x00000a1100110a00, 0x0000142200221400,
    0x0000284400442800, 0x0000508800885000, 0x0000a0100010a000, 0x0000402000204000,
    0x0002040004020000, 0x0005080008050000, 0x000a1100110a0000, 0x0014220022140000,
    0x0028440044280000, 0x0050880088500000, 0x00a0100010a00000, 0x0040200020400000,
    0x0204000402000000, 0x0508000805000000, 0x0a1100110a000000, 0x1422002214000000,
    0x2844004428000000, 0x5088008850000000, 0xa0100010a0000000, 0x4020002040000000,
    0x0400040200000000, 0x0800080500000000, 0x1100110a00000000, 0x2200221400000000,
    0x4400442800000000, 0x8800885000000000, 0x100010a000000000, 0x2000204000000000,
    0x0004020000000000, 0x0008050000000000, 0x00110a0000000000, 0x0022140000000000,
    0x0044280000000000, 0x0088500000000000, 0x0010a00000000000, 0x0020400000000000
};
// zig fmt: on

pub fn getBishopOccupancies(sq: u6, occ: u64) u64 {
    return slidingAttack(sq, Direction.SouthEast, occ) |
        slidingAttack(sq, Direction.NorthEast, occ) |
        slidingAttack(sq, Direction.NorthWest, occ) |
        slidingAttack(sq, Direction.SouthWest, occ);
}

pub fn getRookOccupancies(sq: u6, occ: u64) u64 {
    return slidingAttack(sq, Direction.North, occ) |
        slidingAttack(sq, Direction.South, occ) |
        slidingAttack(sq, Direction.West, occ) |
        slidingAttack(sq, Direction.East, occ);
}

pub fn getQueenOccupancies(sq: u6, occ: u64) u64 {
    return getBishopOccupancies(sq, occ) | getRookOccupancies(sq, occ);
}

fn generateAttackTable(comptime n: u16, shifts: [64]u6, masks: [64]u64, piece_magics: [64]u64, attack_gen: fn (u6, u64) u64) [64][n]u64 {
    const std = @import("std");

    var attack_table = std.mem.zeroes([64][n]u64);

    var sq = @intCast(u7, 0);
    while (sq < 64) : (sq += 1) {
        const shift = shifts[sq];
        const entries = @intCast(u64, 1) << @intCast(u6, 64 - @intCast(u7, shift));

        var entry = @intCast(u64, 0);
        while (entry < entries) : (entry += 1) {
            const occ = populateMask(masks[sq], entry);
            const index = (occ *% piece_magics[sq]) >> shift;
            attack_table[sq][index] = attack_gen(sq, occ);
        }
    }
    return attack_table;
}

fn populateMask(mask: u64, index: u64) u64 {
    var res = @intCast(u64, 0);
    var curr_mask = mask;

    var i = @intCast(u7, 0);
    while (curr_mask != 0) : (i += 1) {
        const bit = bb.bsf(curr_mask);

        if (bb.isSet(index, @intCast(u6, i))) {
            res = bb.setBit(res, @intCast(u6, bit));
        }

        curr_mask &= (curr_mask - 1);
    }
    return res;
}

pub const Direction = enum {
    north,
    south,
    east,
    west,
    north_east,
    south_east,
    north_west,
    south_west,
};

pub fn slidingAttack(sq: u6, direction: Direction, occ: u64) u64 {
    var result = @intCast(u64, 0);

    var curr_sq = bb.fromSquare(sq);

    // const std = @import("std");

    while (true) {
        curr_sq = switch (direction) {
            .north => bb.north(curr_sq),
            .south => bb.south(curr_sq),
            .east => bb.east(curr_sq),
            .west => bb.west(curr_sq),
            .north_east => bb.northEast(curr_sq),
            .south_east => bb.southWest(curr_sq),
            .north_west => bb.northWest(curr_sq),
            .south_west => bb.southWest(curr_sq),
        };

        if (curr_sq == 0) {
            return result;
        }

        result |= curr_sq;

        if (occ & curr_sq > 0) {
            return result;
        }
    }
}

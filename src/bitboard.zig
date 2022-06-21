const std = @import("std");
const Rank = @import("rank.zig").Rank;
const File = @import("file.zig").File;

pub fn fromSquare(sq: u6) u64 {
    return @as(u64, 1) << sq;
}

pub fn fromRank(rank: Rank) u64 {
    return @as(u64, 0b11111111) << @enumToInt(rank) * 8;
}

pub fn fromFile(file: File) u64 {
    return @as(u64, 72340172838076673) << @enumToInt(file);
}

pub fn display(bb: u64) void {
    var rank: u6 = 8;
    while (rank > 0) : (rank -= 1) {
        var file: u6 = 0;
        while (file < 8) : (file += 1) {
            if (isSet(bb, fileRankIndex(file, rank))) {
                std.debug.print("X ", .{});
            } else {
                std.debug.print(". ", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn reset(bb: u64) u64 {
    return asm ("blsr %%rdi, %%rax"
        : [ret] "={rax}" (-> u64),
        : [bb] "{rdi}" (bb),
    );
}

pub fn bsf(bb: u64) u6 {
    return @truncate(u6, asm ("tzcnt %%rdi, %%rax"
        : [ret] "={rax}" (-> u8),
        : [val] "{rdi}" (bb),
    ));
}

pub inline fn fileRankIndex(file: u6, rank: u6) u6 {
    return file + 8 * (rank - 1);
}

pub fn setBit(bb: u64, index: u6) u64 {
    return bb | fromSquare(index);
}

pub fn removeBit(bb: u64, index: u6) u64 {
    return bb & ~(@intCast(u64, 1) << index);
}

pub fn isSet(bb: u64, index: u6) bool {
    return 1 & (bb >> index) > 0;
}

pub fn north(val: u64) u64 {
    return val << 8;
}

pub fn south(val: u64) u64 {
    return val >> 8;
}

pub fn east(val: u64) u64 {
    return (val & ~fromFile(File.h)) << 1;
}

pub fn west(val: u64) u64 {
    return (val & ~fromFile(File.a)) >> 1;
}

pub fn northEast(val: u64) u64 {
    return (val & ~fromFile(File.h)) << 9;
}

pub fn northWest(val: u64) u64 {
    return (val & ~fromFile(File.a)) << 7;
}

pub fn southEast(val: u64) u64 {
    return (val & ~fromFile(File.h)) >> 7;
}

pub fn southWest(val: u64) u64 {
    return (val & ~fromFile(File.a)) >> 9;
}

const std = @import("std");
const Rank = @import("rank.zig").Rank;
const File = @import("file.zig").File;
const Color = @import("color.zig").Color;

pub fn fromSquare(sq: u6) u64 {
    return @as(u64, 1) << sq;
}

pub fn fromRank(rank: Rank) u64 {
    return @as(u64, 0b11111111) << @intCast(u6, @enumToInt(rank)) * 8;
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
    // return @truncate(u6, asm ("tzcnt %%rdi, %%rax"
    //     : [ret] "={rax}" (-> u8),
    //     : [val] "{rdi}" (bb),
    // ));
    return @truncate(u6, @ctz(u64, bb));
}

pub inline fn fileRankIndex(file: u6, rank: u6) u6 {
    return file + 8 * (rank - 1);
}

pub fn setAt(bb: u64, index: u6) u64 {
    return bb | fromSquare(index);
}

pub fn removeAt(bb: u64, index: u6) u64 {
    return bb & ~(@intCast(u64, 1) << index);
}

pub fn isSet(bb: u64, index: u6) bool {
    return 1 & (bb >> index) > 0;
}

pub fn north(bb: u64) u64 {
    return bb << 8;
}

pub fn south(bb: u64) u64 {
    return bb >> 8;
}

pub fn east(bb: u64) u64 {
    return (bb & ~fromFile(File.h)) << 1;
}

pub fn west(bb: u64) u64 {
    return (bb & ~fromFile(File.a)) >> 1;
}

pub fn northEast(bb: u64) u64 {
    return (bb & ~fromFile(File.h)) << 9;
}

pub fn northWest(bb: u64) u64 {
    return (bb & ~fromFile(File.a)) << 7;
}

pub fn southEast(bb: u64) u64 {
    return (bb & ~fromFile(File.h)) >> 7;
}

pub fn southWest(bb: u64) u64 {
    return (bb & ~fromFile(File.a)) >> 9;
}

pub fn up(bb: u64, color: Color) u64 {
    return switch (color) {
        .white => north(bb),
        .black => south(bb),
    };
}

pub fn upLeft(bb: u64, color: Color) u64 {
    return switch (color) {
        .white => northWest(bb),
        .black => southEast(bb),
    };
}

pub fn upRight(bb: u64, color: Color) u64 {
    return switch (color) {
        .white => northEast(bb),
        .black => southWest(bb),
    };
}

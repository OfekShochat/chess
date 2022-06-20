const std = @import("std");
const toLower = std.ascii.toLower;

pub const Color = enum {
    white,
    black,

    pub fn fromChar(char: u8) !Color {
        switch (toLower(char)) {
            'w' => return .white,
            'b' => return .black,
            else => return error.InvalidColor,
        }
    }
};

pub const CastleRights = enum(u2) {
    none,
    kingside,
    queenside,
    both,

    pub fn add(self: *CastleRights, other: CastleRights) void {
        const i = @enumToInt(self.*);
        const o = @enumToInt(other);

        self.* = @intToEnum(CastleRights, i | o);
    }
};

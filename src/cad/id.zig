pub fn Id(comptime T: type) type {
    _ = T;
    return struct {
        idx: usize,
        gen: u32,

        const Self = @This();

        pub fn eq(self: Self, other: Self) bool {
            return self.idx == other.idx and self.gen == other.gen;
        }
    };
}

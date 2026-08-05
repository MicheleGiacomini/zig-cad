const p = @import("point.zig");

pub const Segment = struct {
    start: *const p.Point,
    end: *const p.Point,

    pub fn init(
        start: *const p.Point,
        end: *const p.Point,
    ) Segment {
        return .{
            .start = start,
            .end = end,
        };
    }
};

const Point = @import("point.zig").Point;
const Id = @import("id.zig").Id;

pub const Segment = struct {
    start: Id(Point),
    end: Id(Point),

    pub fn init(
        start: Id(Point),
        end: Id(Point),
    ) Segment {
        return .{
            .start = start,
            .end = end,
        };
    }
};

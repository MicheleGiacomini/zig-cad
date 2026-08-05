pub const Point = struct {
    x: f32,
    y: f32,

    pub fn init(x: f32, y: f32) Point {
        return .{
            .x = x,
            .y = y,
        };
    }
};

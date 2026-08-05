pub const Viewport = struct {
    min_x: f32,
    max_x: f32,
    min_y: f32,
    max_y: f32,
    pixel_width: i32,
    pixel_height: i32,

    pub fn init_from_width(
        min_x: f32,
        max_x: f32,
        min_y: f32,
        pixel_width: i32,
        pixel_height: i32,
    ) Viewport {
        const pixel_pitch = (max_x - min_x) / @as(f32, @floatFromInt(pixel_width));
        const max_y = @as(f32, @floatFromInt(pixel_height)) * pixel_pitch + min_y;
        return .{
            .min_x = min_x,
            .max_x = max_x,
            .min_y = min_y,
            .max_y = max_y,
            .pixel_width = pixel_width,
            .pixel_height = pixel_height,
        };
    }
};

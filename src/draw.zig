const rl = @import("raylib");
const cad = @import("cad");

fn convert_to_screen_coord(c: f32, min: f32, max: f32, screen_range: i32) i32 {
    return @round((c - min) / (max - min) * @as(f32, @floatFromInt(screen_range)));
}

fn screen_x(x: f32, v: *const cad.Viewport) i32 {
    return convert_to_screen_coord(x, v.min_x, v.max_x, v.pixel_width);
}

fn screen_y(y: f32, v: *const cad.Viewport) i32 {
    return v.pixel_height - convert_to_screen_coord(y, v.min_y, v.max_y, v.pixel_height);
}

pub fn drawSegment(s: *const cad.Segment, v: *const cad.Viewport, color: rl.Color) void {
    rl.drawLine(
        screen_x(s.start.x, v),
        screen_y(s.start.y, v),
        screen_x(s.end.x, v),
        screen_y(s.end.y, v),
        color,
    );
}

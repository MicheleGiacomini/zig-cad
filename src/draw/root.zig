const rl = @import("raylib");
const cad = @import("cad");

pub const Color = rl.Color;

fn convert_to_screen_coord(c: f32, min: f32, max: f32, screen_range: i32) i32 {
    return @round((c - min) / (max - min) * @as(f32, @floatFromInt(screen_range)));
}

fn screen_x(x: f32, v: *const cad.Viewport) i32 {
    return convert_to_screen_coord(x, v.min_x, v.max_x, v.pixel_width);
}

fn screen_y(y: f32, v: *const cad.Viewport) i32 {
    return v.pixel_height - convert_to_screen_coord(y, v.min_y, v.max_y, v.pixel_height);
}

pub fn segment(start: cad.Point, end: cad.Point, v: *const cad.Viewport, x_offset: i32, y_offset: i32, color: rl.Color) void {
    rl.drawLine(
        screen_x(start.x, v) + x_offset,
        screen_y(start.y, v) + y_offset,
        screen_x(end.x, v) + x_offset,
        screen_y(end.y, v) + y_offset,
        color,
    );
}

pub fn segment_from_point_to_screen_coords(start: cad.Point, end_x: i32, end_y: i32, v: *const cad.Viewport, color: rl.Color) void {
    rl.drawLine(
        screen_x(start.x, v),
        screen_y(start.y, v),
        end_x,
        end_y,
        color,
    );
}

pub fn scene(s: *const cad.Scene, v: *const cad.Viewport, x_offset: i32, y_offset: i32, color: rl.Color) void {
    for (s.segments.items) |sgmt| {
        if (sgmt.isAlive()) {
            if (s.getPoint(sgmt.content.start)) |start| {
                if (s.getPoint(sgmt.content.end)) |end| {
                    segment(start, end, v, x_offset, y_offset, color);
                }
            }
        }
    }
}

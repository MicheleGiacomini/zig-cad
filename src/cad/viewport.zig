const assert = @import("std").debug.assert;

pub const Viewport = struct {
    min_x: f32,
    max_x: f32,
    min_y: f32,
    max_y: f32,
    pixel_width: i32,
    pixel_height: i32,

    fn pixel_pitch(w: f32, px_w: i32) f32 {
        return (w / @as(f32, @floatFromInt(px_w)));
    }

    fn update_max_y(self: *Viewport) void {
        const pp = pixel_pitch(self.width(), self.pixel_width);
        self.max_y = @as(f32, @floatFromInt(self.pixel_height)) * pp + self.min_y;
    }

    /// Init a viewport given pixel dimensions, plus width and min_y.
    /// Expects min_x < max_x.
    pub fn init_from_width(
        min_x: f32,
        max_x: f32,
        min_y: f32,
        pixel_width: i32,
        pixel_height: i32,
    ) Viewport {
        assert(max_x > min_x);

        var self = Viewport{
            .min_x = min_x,
            .max_x = max_x,
            .min_y = min_y,
            .max_y = 0.0,
            .pixel_width = pixel_width,
            .pixel_height = pixel_height,
        };
        self.update_max_y();
        return self;
    }

    pub fn width(self: *const Viewport) f32 {
        return self.max_x - self.min_x;
    }

    pub fn height(self: *const Viewport) f32 {
        return self.max_y - self.min_y;
    }

    /// Zoom the viewport by factor (< 1 zoom in, > 1 zoom out).
    /// Keeps the relative position of the point (x,y) fixed in the viewport.
    /// Expects (x, y) to be in the viewport.
    pub fn zoom(self: *Viewport, factor: f32, x_px: i32, y_px: i32) void {
        const pp = pixel_pitch(self.width(), self.pixel_width);

        const x = self.min_x + @as(f32, @floatFromInt(x_px)) * pp;
        const y = self.max_y - @as(f32, @floatFromInt(y_px)) * pp;

        const new_width = self.width() * factor;
        const new_height = self.height() * factor;

        const norm_x = (x - self.min_x) / self.width();
        const norm_y = (y - self.min_y) / self.height();

        const new_min_x = x - new_width * norm_x;
        const new_max_x = new_min_x + new_width;
        const new_min_y = y - new_height * norm_y;

        self.min_x = new_min_x;
        self.max_x = new_max_x;
        self.min_y = new_min_y;

        self.update_max_y();
    }

    /// Move viewport by given amount of pixels, dx positive to the right, dy positive down.
    pub fn move(self: *Viewport, dx_pixles: f32, dy_pixels: f32) void {
        const pp = pixel_pitch(self.width(), self.pixel_width);
        self.min_x += dx_pixles * pp;
        self.max_x += dx_pixles * pp;
        self.min_y += -dy_pixels * pp;
        self.max_y += -dy_pixels * pp;
    }
};

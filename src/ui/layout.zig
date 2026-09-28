const b = @import("base.zig");
const fs = @import("frame_state/frame_state.zig");
const rl = @import("raylib");

pub const ElementBounds = struct {
    tl: b.ScreenCoords,
    tr: b.ScreenCoords,
    bl: b.ScreenCoords,
    br: b.ScreenCoords,
    width: i32,
    height: i32,
    center: b.ScreenCoords,

    pub fn fromTLSize(tl: b.ScreenCoords, width: i32, height: i32) ElementBounds {
        const c_x = tl.x + @divFloor(width, 2);
        const c_y = tl.y + @divFloor(height, 2);

        return .{
            .tl = tl,
            .tr = .{ .x = tl.x + width, .y = tl.y },
            .bl = .{ .x = tl.x, .y = tl.y - height },
            .br = .{ .x = tl.x + width, .y = tl.y - height },
            .width = width,
            .height = height,
            .center = .{ .x = c_x, .y = c_y },
        };
    }
    pub fn fromCSize(c: b.ScreenCoords, width: i32, height: i32) ElementBounds {
        const tl_x = c.x - @divFloor(width, 2);
        const tl_y = c.x - @divFloor(height, 2);
        return .{
            .tl = .{ .x = tl_x, .y = tl_y },
            .tr = .{ .x = tl_x + width, .y = tl_y },
            .bl = .{ .x = tl_x, .y = tl_y - height },
            .br = .{ .x = tl_x + width, .y = tl_y - height },
            .width = width,
            .height = height,
            .center = c,
        };
    }

    pub fn toRect(self: *const ElementBounds) rl.Rectangle {
        return .{
            .x = @floatFromInt(self.tl.x),
            .y = @floatFromInt(self.tl.y),
            .width = @floatFromInt(self.width),
            .height = @floatFromInt(self.height),
        };
    }
};

pub const Layout = struct {
    toolbar_height: i32,

    pub fn toolBarBounds(self: *const Layout, frame_state: *const fs.FrameState) ElementBounds {
        return ElementBounds.fromTLSize(
            .{ .x = 0, .y = 0 },
            frame_state.window.width,
            self.toolbar_height,
        );
    }

    pub fn viewPortBounds(self: *const Layout, frame_state: *const fs.FrameState) ElementBounds {
        return ElementBounds.fromTLSize(
            .{ .x = 0, .y = self.toolbar_height },
            frame_state.window.width,
            frame_state.window.height - self.toolbar_height,
        );
    }
};

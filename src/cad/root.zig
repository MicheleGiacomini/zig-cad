pub const Point = @import("point.zig").Point;
pub const Segment = @import("line.zig").Segment;
pub const Viewport = @import("viewport.zig").Viewport;
pub const Scene = @import("scene.zig").Scene;
pub const Id = @import("id.zig").Id;

// `zig test` only runs tests reachable from this root. Import every file so
// `zig build test` picks up test blocks written next to the code.
test {
    _ = @import("point.zig");
    _ = @import("line.zig");
    _ = @import("viewport.zig");
    _ = @import("scene.zig");
    _ = @import("id.zig");
}

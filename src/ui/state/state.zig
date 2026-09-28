const cad = @import("cad");
const line_handler = @import("../tool_handlers/line_tool_handler.zig");

pub const State = struct {
    tool_state: ToolState,
    scene: *cad.Scene,
    viewport: *cad.Viewport,

    pub fn init(scene: *cad.Scene, viewport: *cad.Viewport) State {
        return .{
            .scene = scene,
            .viewport = viewport,
            .tool_state = .none,
        };
    }
};

pub const ToolState = union(enum) {
    none,
    line_tool: line_handler.LineToolState,
};

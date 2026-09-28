pub const LineToolState = @import("line_tool_state.zig").LineToolState;
pub const cad = @import("cad");
pub const Command = @import("../commands.zig").Command;
pub const State = @import("../state/state.zig").State;
pub const FrameState = @import("../frame_state/frame_state.zig").FrameState;
pub const draw = @import("draw");

pub fn command_handler(tool_state: *LineToolState, cmd: *const Command, state: *State) void {
    _ = tool_state;
    _ = cmd;
    _ = state;
}

pub fn frame_handler(tool_state: *const LineToolState, state: *FrameState) void {
    switch (tool_state) {
        .start => {},
        .first_point_selected => |p| {
            draw.segment_from_point_to_screen_coords(p, state.mouse_x, state.mouse_y, state.viewPort, draw.Color.white);
        },
    }
}

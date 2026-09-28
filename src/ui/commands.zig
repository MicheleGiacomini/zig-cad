const cad = @import("cad");
const State = @import("state/state.zig").State;
const fs = @import("frame_state/frame_state.zig");
const UISettings = @import("ui_settings.zig").UISettings;
const std = @import("std");

pub const Command = union(enum) {
    select_line_tool,
    select_point: cad.Point,
    cancel,
};

pub fn dispatchCommandToHandler(command: *const Command, state: *State) void {
    switch (state.tool_state) {
        .line_tool => {},
        .none => {
            defaultHandleCommand(command, state);
        },
    }
}

pub fn baseUpdateFrame(state: *State, frame_state: *const fs.FrameState, settings: *const UISettings) void {
    // Zoom
    // zoom is always active
    if (frame_state.scroll_state.is_scrolling_y()) {
        const factor = @exp(@log(settings.zoom_speed) * frame_state.scroll_state.y);
        state.viewport.zoom(factor, frame_state.mouse_position.x, frame_state.mouse_position.y);
    }

    // Pan
    // pan only triggers if there is a right mouse button drag active that has not been
    // consumed by the active tool.
    if (!frame_state.drag_consumed) {
        switch (frame_state.drag_state) {
            .none => {},
            .dragging, .released => |dragging_state| {
                if (dragging_state.button == .right) {
                    state.viewport.move(-dragging_state.delta.dx, -dragging_state.delta.dy);
                }
            },
        }
    }
}

fn defaultHandleCommand(command: *const Command, state: *State) void {
    switch (command) {
        .select_line_tool => {
            state.tool_state = .{ .line_tool = .init() };
        },
        .select_point => {},
        .cancel => {},
    }
}

const std = @import("std");
const fs = @import("frame_state.zig");
const rl = @import("raylib");
const b = @import("../base.zig");
const UISettings = @import("../ui_settings.zig").UISettings;

pub fn updateFrameState(state: *fs.FrameState, settings: *const UISettings) void {
    // calculate new pointer state
    const new_x = rl.getMouseX();
    const new_y = rl.getMouseY();
    const delta_x = new_x - state.mouse_position.x;
    const delta_y = new_y - state.mouse_position.y;
    const current_position: b.ScreenCoords = .{ .x = new_x, .y = new_y };

    // calculate new drag state
    var should_clear_left_down = false;
    var should_clear_middle_down = false;
    var should_clear_right_down = false;

    var new_drag_state: fs.DragState = .none;

    sw: switch (state.drag_state) {
        .none, .released => {
            // Check if we should start a drag.
            // Priority is middle -> left -> right to break ties
            // Any button that was pressed and did not initiate a drag
            // is reset to non-pressed state
            if (isDragging(
                state.mouse_buttons.middle_down_start,
                current_position,
                settings.initiate_drag_distance,
            )) |motion| {
                const new_dragging_state: fs.DraggingState = .{
                    .button = .middle,
                    .drag_start = motion.start,
                    .delta = motion.delta,
                };
                if (rl.isMouseButtonReleased(.middle)) {
                    new_drag_state = .{ .released = new_dragging_state };
                    should_clear_left_down = true;
                    should_clear_right_down = true;
                    break :sw;
                }
                if (rl.isMouseButtonDown(.middle)) {
                    new_drag_state = .{ .dragging = new_dragging_state };
                    should_clear_left_down = true;
                    should_clear_right_down = true;
                    break :sw;
                }
            }
            if (isDragging(
                state.mouse_buttons.left_down_start,
                current_position,
                settings.initiate_drag_distance,
            )) |motion| {
                const new_dragging_state: fs.DraggingState = .{
                    .button = .left,
                    .drag_start = motion.start,
                    .delta = motion.delta,
                };
                if (rl.isMouseButtonReleased(.left)) {
                    new_drag_state = .{ .released = new_dragging_state };
                    should_clear_right_down = true;
                    should_clear_middle_down = true;
                    break :sw;
                }
                if (rl.isMouseButtonDown(.left)) {
                    new_drag_state = .{ .dragging = new_dragging_state };
                    should_clear_right_down = true;
                    should_clear_middle_down = true;
                    break :sw;
                }
            }
            if (isDragging(
                state.mouse_buttons.right_down_start,
                current_position,
                settings.initiate_drag_distance,
            )) |motion| {
                const new_dragging_state: fs.DraggingState = .{
                    .button = .right,
                    .drag_start = motion.start,
                    .delta = motion.delta,
                };
                if (rl.isMouseButtonReleased(.right)) {
                    new_drag_state = .{ .released = new_dragging_state };
                    should_clear_left_down = true;
                    should_clear_middle_down = true;
                    break :sw;
                }
                if (rl.isMouseButtonDown(.right)) {
                    new_drag_state = .{ .dragging = new_dragging_state };
                    should_clear_left_down = true;
                    should_clear_middle_down = true;
                    break :sw;
                }
            }
        },
        .dragging => |dragging_state| {
            const new_dragging_state: fs.DraggingState = .{
                .button = dragging_state.button,
                .delta = .{
                    .dx = delta_x,
                    .dy = delta_y,
                },
                .drag_start = dragging_state.drag_start,
            };
            if (rl.isMouseButtonDown(convertMouseButtonToRL(dragging_state.button))) {
                new_drag_state = .{ .dragging = new_dragging_state };
            } else {
                new_drag_state = .{ .released = new_dragging_state };
            }
            if (dragging_state.button != .left) {
                should_clear_left_down = true;
            }
            if (dragging_state.button != .middle) {
                should_clear_middle_down = true;
            }
            if (dragging_state.button != .right) {
                should_clear_right_down = true;
            }
        },
    }

    // calculate new button state
    // here need to set click state according to what the new drag state
    // If dragging, no button press or releas should register as a separate click
    // and all button different from the one being used by the drag should not
    // even register the press.
    var left_down: ?b.ScreenCoords = null;
    var middle_down: ?b.ScreenCoords = null;
    var right_down: ?b.ScreenCoords = null;

    var left_clicked = false;
    var middle_clicked = false;
    var right_clicked = false;

    if (!should_clear_left_down) {
        if (rl.isMouseButtonPressed(.left)) {
            left_down = .{
                .x = new_x,
                .y = new_y,
            };
        } else if (rl.isMouseButtonReleased(.left) and std.meta.activeTag(new_drag_state) != .released) {
            left_clicked = true;
        } else if (rl.isMouseButtonDown(.left)) {
            left_down = state.mouse_buttons.left_down_start;
        }
    }
    if (!should_clear_middle_down) {
        if (rl.isMouseButtonPressed(.middle)) {
            middle_down = .{
                .x = new_x,
                .y = new_y,
            };
        } else if (rl.isMouseButtonReleased(.middle) and std.meta.activeTag(new_drag_state) != .released) {
            middle_clicked = true;
        } else if (rl.isMouseButtonDown(.middle)) {
            middle_down = state.mouse_buttons.middle_down_start;
        }
    }
    if (!should_clear_right_down) {
        if (rl.isMouseButtonPressed(.right)) {
            right_down = .{
                .x = new_x,
                .y = new_y,
            };
        } else if (rl.isMouseButtonReleased(.right) and std.meta.activeTag(new_drag_state) != .released) {
            right_clicked = true;
        } else if (rl.isMouseButtonDown(.right)) {
            right_down = state.mouse_buttons.right_down_start;
        }
    }

    // calculate new scroll state
    const rl_scroll_state = rl.getMouseWheelMoveV();

    // calculate update drag state
    //
    //
    //
    // update state
    state.mouse_position = .{
        .x = new_x,
        .y = new_y,
        .delta_x = delta_x,
        .delta_y = delta_y,
    };
    state.mouse_buttons = .{
        .left_down_start = left_down,
        .middle_down_start = middle_down,
        .right_down_start = right_down,
        .left_clicked = left_clicked,
        .middle_clicked = middle_clicked,
        .right_clicked = right_clicked,
    };
    state.scroll_state = .{
        .x = rl_scroll_state.x,
        .y = rl_scroll_state.y,
    };
    state.drag_state = new_drag_state;
    state.drag_consumed = false;
    const new_width = rl.getRenderWidth();
    const new_height = rl.getRenderHeight();
    const did_change = state.window.width != new_width or state.window.height != new_height;
    state.window = .{
        .width = rl.getRenderWidth(),
        .height = rl.getRenderHeight(),
        .did_change = did_change,
    };
}

const DragMotion = struct {
    start: b.ScreenCoords,
    delta: b.ScreenDelta,
};

fn isDragging(
    pressed_location: ?b.ScreenCoords,
    current_location: b.ScreenCoords,
    initiate_drag_distance: i32,
) ?DragMotion {
    if (pressed_location) |start| {
        const delta_x = current_location.x - start.x;
        const delta_y = current_location.y - start.y;
        if (delta_x * delta_x + delta_y * delta_y > initiate_drag_distance * initiate_drag_distance) {
            return .{
                .start = start,
                .delta = .{
                    .dx = current_location.x - start.x,
                    .dy = current_location.y - start.y,
                },
            };
        }
    }
    return null;
}

fn convertMouseButtonToRL(button: fs.MouseButton) rl.MouseButton {
    return switch (button) {
        .left => rl.MouseButton.left,
        .middle => rl.MouseButton.middle,
        .right => rl.MouseButton.right,
    };
}

const rl = @import("raylib");
const rg = @import("raygui");
const fs = @import("frame_state/frame_state.zig");

/// Immediate-mode widgets. Call sites should import this module, not raygui.
///
/// Drawing is still raygui. Interaction is FrameState: a click is
/// `left_clicked` (press+release under the drag threshold) with the pointer
/// inside `bounds` on the release frame. Replace a function body later to
/// round corners; keep the signature.
///
/// Stateful raygui controls (toggle, text box, slider) update from Raylib's
/// mouse unless we reconcile. We draw with raygui, then keep or revert that
/// mutation from FrameState. Do not wrap sliders / text boxes until you are
/// ready to own their drag and keyboard.

pub fn contains(bounds: rl.Rectangle, frame_state: *const fs.FrameState) bool {
    return containsPoint(bounds, frame_state.mouse_position.x, frame_state.mouse_position.y);
}

pub fn containsPoint(bounds: rl.Rectangle, x: i32, y: i32) bool {
    const px: f32 = @floatFromInt(x);
    const py: f32 = @floatFromInt(y);
    return px >= bounds.x and py >= bounds.y and px < bounds.x + bounds.width and py < bounds.y + bounds.height;
}

/// Eat clicks (and drags that started here) so chrome does not fall through
/// to the viewport. Call *after* interactive widgets in the same region.
pub fn absorbPointer(bounds: rl.Rectangle, frame_state: *fs.FrameState) void {
    if (contains(bounds, frame_state)) {
        frame_state.consumeClick(null);
    }
    const drag_start = switch (frame_state.drag_state) {
        .dragging, .released => |d| d.drag_start,
        .none => null,
    };
    if (drag_start) |start| {
        if (containsPoint(bounds, start.x, start.y)) {
            frame_state.drag_consumed = true;
        }
    }
}

pub fn button(bounds: rl.Rectangle, text: [:0]const u8, frame_state: *fs.FrameState) bool {
    _ = rg.button(bounds, text);
    return takeLeftClick(bounds, frame_state);
}

pub fn labelButton(bounds: rl.Rectangle, text: [:0]const u8, frame_state: *fs.FrameState) bool {
    _ = rg.labelButton(bounds, text);
    return takeLeftClick(bounds, frame_state);
}

pub fn toggle(bounds: rl.Rectangle, text: [:0]const u8, active: *bool, frame_state: *fs.FrameState) bool {
    const before = active.*;
    _ = rg.toggle(bounds, text, active);
    return keepBoolIfClicked(bounds, frame_state, active, before);
}

pub fn checkBox(bounds: rl.Rectangle, text: [:0]const u8, checked: *bool, frame_state: *fs.FrameState) bool {
    const before = checked.*;
    _ = rg.checkBox(bounds, text, checked);
    return keepBoolIfClicked(bounds, frame_state, checked, before);
}

pub fn label(bounds: rl.Rectangle, text: [:0]const u8) void {
    _ = rg.label(bounds, text);
}

pub fn panel(bounds: rl.Rectangle, text: ?[*:0]const u8) void {
    _ = rg.panel(bounds, text);
}

pub fn groupBox(bounds: rl.Rectangle, text: [:0]const u8) void {
    _ = rg.groupBox(bounds, text);
}

pub fn statusBar(bounds: rl.Rectangle, text: [:0]const u8) void {
    _ = rg.statusBar(bounds, text);
}

fn takeLeftClick(bounds: rl.Rectangle, frame_state: *fs.FrameState) bool {
    if (!frame_state.mouse_buttons.left_clicked) return false;
    if (!contains(bounds, frame_state)) return false;
    frame_state.consumeClick(.left);
    return true;
}

fn keepBoolIfClicked(
    bounds: rl.Rectangle,
    frame_state: *fs.FrameState,
    value: *bool,
    before: bool,
) bool {
    if (takeLeftClick(bounds, frame_state)) {
        if (value.* == before) value.* = !before;
        return true;
    }
    value.* = before;
    return false;
}

test "containsPoint is min-inclusive, max-exclusive" {
    const bounds: rl.Rectangle = .{ .x = 10, .y = 20, .width = 100, .height = 40 };
    try @import("std").testing.expect(containsPoint(bounds, 10, 20));
    try @import("std").testing.expect(containsPoint(bounds, 109, 59));
    try @import("std").testing.expect(!containsPoint(bounds, 110, 20));
    try @import("std").testing.expect(!containsPoint(bounds, 10, 60));
    try @import("std").testing.expect(!containsPoint(bounds, 9, 20));
}

test "takeLeftClick consumes only a left click inside bounds" {
    const bounds: rl.Rectangle = .{ .x = 0, .y = 0, .width = 80, .height = 40 };
    var frame_state = fs.FrameState.init(10, 10, 800, 800);
    frame_state.mouse_buttons.left_clicked = true;

    try @import("std").testing.expect(takeLeftClick(bounds, &frame_state));
    try @import("std").testing.expect(!frame_state.mouse_buttons.left_clicked);

    frame_state.mouse_buttons.left_clicked = true;
    frame_state.mouse_position.x = 200;
    try @import("std").testing.expect(!takeLeftClick(bounds, &frame_state));
    try @import("std").testing.expect(frame_state.mouse_buttons.left_clicked);
}

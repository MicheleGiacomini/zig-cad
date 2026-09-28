const cad = @import("cad");
const std = @import("std");
const ScreenDelta = @import("../base.zig").ScreenDelta;
const ScreenCoords = @import("../base.zig").ScreenCoords;

pub const FrameState = struct {
    mouse_position: MousePositionState,
    mouse_buttons: MouseButtonState,
    drag_state: DragState,
    scroll_state: ScrollState,
    drag_consumed: bool,
    window: WindowState,

    pub fn init(mouse_x: i32, mouse_y: i32, widow_width: i32, window_height: i32) FrameState {
        return .{
            .mouse_position = MousePositionState.init(mouse_x, mouse_y),
            .scroll_state = .{
                .x = 0.0,
                .y = 0.0,
            },
            .mouse_buttons = MouseButtonState.init(),
            .drag_state = .none,
            .drag_consumed = false,
            .window = .{ .width = widow_width, .height = window_height, .did_change = false },
        };
    }

    /// If a given mouse release event should trigger a click in raygui
    pub fn shouldRegisterRayguiClick(self: *const FrameState) bool {
        return std.meta.activeTag(self.drag_state) == DragState.none;
    }

    /// Consumes mouse clicks, if button is null consumes all clicks, otherwise only
    /// the one specified.
    pub fn consumeClick(self: *FrameState, button: ?MouseButton) void {
        if (button) |b| {
            switch (b) {
                .left => {
                    self.mouse_buttons.left_clicked = false;
                },
                .middle => {
                    self.mouse_buttons.middle_clicked = false;
                },
                .right => {
                    self.mouse_buttons.right_clicked = false;
                },
            }
        } else {
            self.mouse_buttons.left_clicked = false;
            self.mouse_buttons.middle_clicked = false;
            self.mouse_buttons.right_clicked = false;
        }
    }
};

pub const WindowState = struct {
    width: i32,
    height: i32,
    did_change: bool,
};

pub const MouseButton = enum {
    left,
    middle,
    right,
};

pub const MousePositionState = struct {
    x: i32,
    y: i32,
    delta_x: i32,
    delta_y: i32,

    pub fn init(x: i32, y: i32) MousePositionState {
        return .{
            .x = x,
            .y = y,
            .delta_x = 0,
            .delta_y = 0,
        };
    }
};

pub const ScrollState = struct {
    x: f32,
    y: f32,

    pub fn is_scrolling(self: *const ScrollState) bool {
        return self.x != 0 or self.y != 0;
    }
    pub fn is_scrolling_x(self: *const ScrollState) bool {
        return self.x != 0;
    }
    pub fn is_scrolling_y(self: *const ScrollState) bool {
        return self.y != 0;
    }
};

pub const MouseButtonState = struct {
    /// Screen coordinets at which the left mouse button was pressed
    left_down_start: ?ScreenCoords,
    /// Screen coordinets at which the middle mouse button was pressed
    middle_down_start: ?ScreenCoords,
    /// Screen coordinets at which the right mouse button was pressed
    right_down_start: ?ScreenCoords,
    /// Should we count the left mouse button as clicked this frame?
    /// = Was released this frame and the distance travelled by the pointer
    /// since when it was pressed is less than the drag threashold
    left_clicked: bool,
    /// Should we count the middle mouse button as clicked this frame?
    /// = Was released this frame and the distance travelled by the pointer
    /// since when it was pressed is less than the drag threashold
    middle_clicked: bool,
    /// Should we count the right mouse button as clicked this frame?
    /// = Was released this frame and the distance travelled by the pointer
    /// since when it was pressed is less than the drag threashold
    right_clicked: bool,

    pub fn init() MouseButtonState {
        return .{
            .left_down_start = null,
            .middle_down_start = null,
            .right_down_start = null,
            .left_clicked = false,
            .right_clicked = false,
            .middle_clicked = false,
        };
    }

    pub fn left_down(self: *const MouseButtonState) bool {
        return self.left_down_start != null;
    }

    pub fn middle_down(self: *const MouseButtonState) bool {
        return self.middle_down_start != null;
    }

    pub fn right_down(self: *const MouseButtonState) bool {
        return self.right_down_start != null;
    }
};

pub const DragState = union(enum) {
    /// The user is currently dragging
    dragging: DraggingState,
    /// The user stopped dragging this frame
    released: DraggingState,
    /// No drag is currently underway
    none,
};

pub const DraggingState = struct {
    /// Start point of the drag
    drag_start: ScreenCoords,
    /// Amount of drag for this frame
    delta: ScreenDelta,
    /// The mouse button being held in the drag
    button: MouseButton,
};

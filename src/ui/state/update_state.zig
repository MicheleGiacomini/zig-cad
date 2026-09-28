const st = @import("state.zig");
const lt = @import("../layout.zig");
const fs = @import("../frame_state/frame_state.zig");

pub fn updateState(state: *st.State, frame_state: *const fs.FrameState, layout: *const lt.Layout) void {
    if (frame_state.window.did_change) {
        const vp_bounds = layout.viewPortBounds(frame_state);
        state.viewport.updateWidthHeight(vp_bounds.width, vp_bounds.height);
    }
}

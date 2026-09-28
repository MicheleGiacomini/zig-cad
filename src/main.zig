// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const rl = @import("raylib");
const cad = @import("cad");
const draw = @import("draw");
const ui = @import("ui");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 800;

    const gpa = std.heap.page_allocator;

    var scene = cad.Scene.init(gpa);

    const p1 = try scene.addPoint(-1, 0);
    const p2 = try scene.addPoint(1, 0);
    const p3 = try scene.addPoint(0, -1);
    const p4 = try scene.addPoint(0, 1);

    _ = try scene.addSegment(p1, p2);
    _ = try scene.addSegment(p3, p4);
    _ = try scene.addSegment(p2, p4);
    _ = try scene.addSegment(p4, p1);
    _ = try scene.addSegment(p1, p3);
    _ = try scene.addSegment(p3, p2);

    var v = cad.Viewport.init_from_width(
        -0.5,
        2,
        -2,
        screenWidth,
        screenHeight,
    );

    rl.setConfigFlags(.{ .window_resizable = true });

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //
    const settings: ui.UISettings = .{
        .initiate_drag_distance = 5,
        .zoom_speed = 1.1,
    };

    const layout: ui.layout.Layout = .{
        .toolbar_height = 50,
    };

    var state = ui.state.State.init(&scene, &v);

    var frame_state = ui.frameState.FrameState.init(
        rl.getMouseX(),
        rl.getMouseY(),
        rl.getRenderWidth(),
        rl.getRenderHeight(),
    );
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        ui.updateFrameState(
            &frame_state,
            &settings,
        );

        ui.commands.baseUpdateFrame(&state, &frame_state, &settings);

        ui.updateState(&state, &frame_state, &layout);

        const vp_bounds = layout.viewPortBounds(&frame_state);

        draw.scene(&scene, &v, vp_bounds.tl.x, vp_bounds.tl.y, .blue);

        draw_toolbar(&layout, &frame_state);

        //----------------------------------------------------------------------------------
    }
}

fn draw_toolbar(layout: *const ui.layout.Layout, frame_state: *ui.frameState.FrameState) void {
    const bar = layout.toolBarBounds(frame_state);
    const bar_rect = bar.toRect();
    rl.drawRectangle(bar.tl.x, bar.tl.y, bar.width, bar.height, .yellow);
    if (ui.widgets.button(.{ .x = 5, .y = 5, .width = 80, .height = 40 }, "Test", frame_state)) {
        std.debug.print("Button pressed", .{});
    }
    ui.widgets.absorbPointer(bar_rect, frame_state);
}

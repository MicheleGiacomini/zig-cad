// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const rl = @import("raylib");
const cad = @import("cad");
const draw = @import("draw.zig");

const points = [_]cad.Point{
    cad.Point.init(-1, 0),
    cad.Point.init(1, 0),
    cad.Point.init(0, -1),
    cad.Point.init(0, 1),
};

const lines = [_]cad.Segment{
    cad.Segment.init(
        &points[0],
        &points[1],
    ),
    cad.Segment.init(
        &points[2],
        &points[3],
    ),
    cad.Segment.init(
        &points[1],
        &points[3],
    ),
    cad.Segment.init(
        &points[3],
        &points[0],
    ),
    cad.Segment.init(
        &points[0],
        &points[2],
    ),
    cad.Segment.init(
        &points[2],
        &points[1],
    ),
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 800;

    const gpa = std.heap.page_allocator;

    var scene = cad.Scene.init(gpa);

    for (lines) |line| {
        try scene.addSegment(line.start, line.end);
    }

    var v = cad.Viewport.init_from_width(
        -0.5,
        2,
        -2,
        screenWidth,
        screenHeight,
    );

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
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

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);

        // zoom

        const mouseWheelMove = rl.getMouseWheelMove();

        if (mouseWheelMove != 0) {
            const mouse_x = rl.getMouseX();
            const mouse_y = rl.getMouseY();

            const zoom_speed = 1.1;

            const factor = @exp(@log(zoom_speed) * mouseWheelMove);

            v.zoom(factor, mouse_x, mouse_y);
        }

        // pan

        if (rl.isMouseButtonPressed(.left) or rl.isMouseButtonDown(.left) or rl.isMouseButtonReleased(.left)) {
            const delta = rl.getMouseDelta();
            v.move(-delta.x, -delta.y);
        }

        draw.drawScene(&scene, &v, .blue);

        //----------------------------------------------------------------------------------
    }
}

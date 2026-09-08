// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const rl = @import("raylib");
const cad = @import("cad");
const draw = @import("draw.zig");

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

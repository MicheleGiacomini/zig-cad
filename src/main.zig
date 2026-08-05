// raylib-zig (c) Nikolas Wipper 2023

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

    const v = cad.Viewport.init_from_width(-2, 2, -2, screenWidth, screenHeight);

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

        for (lines) |l| {
            draw.drawSegment(&l, &v, .black);
        }

        //----------------------------------------------------------------------------------
    }
}

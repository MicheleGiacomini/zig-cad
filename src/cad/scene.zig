const Point = @import("point.zig").Point;
const Segment = @import("line.zig").Segment;
const std = @import("std");

pub const Scene = struct {
    points: std.ArrayList(Point),
    segments: std.ArrayList(Segment),
    allocator: std.mem.Allocator,

    pub fn init(gpa: std.mem.Allocator) Scene {
        const points = std.ArrayList(Point).empty;
        const segments = std.ArrayList(Segment).empty;
        return .{
            .points = points,
            .segments = segments,
            .allocator = gpa,
        };
    }

    pub fn deinit(self: *Scene) void {
        self.points.deinit(self.gpa);
        self.segments.deinit(self.gpa);
    }

    pub fn addPoint(self: *Scene, x: f32, y: f32) void {
        self.points.append(self.gpa, Point.init(x, y));
    }

    pub fn addSegment(self: *Scene, start: *const Point, end: *const Point) !void {
        try self.segments.append(self.allocator, Segment.init(start, end));
    }
};

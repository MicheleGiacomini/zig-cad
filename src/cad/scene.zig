const Point = @import("point.zig").Point;
const Segment = @import("line.zig").Segment;
const std = @import("std");
const Id = @import("id.zig").Id;

fn WithGen(comptime T: type) type {
    return struct {
        content: T,
        gen: u32,

        const Self = @This();

        pub fn isAlive(self: Self) bool {
            return self.gen % 2 == 0;
        }
    };
}

pub const Scene = struct {
    points: std.ArrayList(WithGen(Point)),
    points_freelist: std.ArrayList(usize),
    segments: std.ArrayList(WithGen(Segment)),
    segments_freelist: std.ArrayList(usize),
    allocator: std.mem.Allocator,

    pub fn init(gpa: std.mem.Allocator) Scene {
        const points = std.ArrayList(WithGen(Point)).empty;
        const segments = std.ArrayList(WithGen(Segment)).empty;
        const points_freelist = std.ArrayList(usize).empty;
        const segments_freelist = std.ArrayList(usize).empty;
        return .{
            .points = points,
            .points_freelist = points_freelist,
            .segments = segments,
            .segments_freelist = segments_freelist,
            .allocator = gpa,
        };
    }

    pub fn deinit(self: *Scene) void {
        self.points.deinit(self.allocator);
        self.segments.deinit(self.allocator);
        self.points_freelist.deinit(self.allocator);
        self.segments_freelist.deinit(self.allocator);
    }

    /// Helper to add an item to the list and keep gen and free_list in sync.
    fn addToList(comptime T: type, gpa: std.mem.Allocator, list: *std.ArrayList(WithGen(T)), free_list: *std.ArrayList(usize), item: T) !Id(T) {
        if (free_list.pop()) |first_free| {
            const current_gen = list.items[first_free].gen;
            list.items[first_free] = .{ .content = item, .gen = current_gen + 1 };
            return .{ .idx = first_free, .gen = current_gen + 1 };
        } else {
            try list.append(gpa, .{ .content = item, .gen = 0 });
            return .{ .idx = list.items.len - 1, .gen = 0 };
        }
    }

    /// Helper to remove an item and keep gen and free_list in sync.
    /// Returns true if the item was actually delete, false if it was already dead.
    fn removeFromList(comptime T: type, gpa: std.mem.Allocator, list: *std.ArrayList(WithGen(T)), free_list: *std.ArrayList(usize), idx: Id(T)) !bool {
        if (list.items[idx.idx].isAlive() and list.items[idx.idx].gen == idx.gen) {
            try free_list.append(gpa, idx.idx);
            list.items[idx.idx].gen += 1;
            return true;
        }
        return false;
    }

    pub fn getPoint(self: *const Scene, point_id: Id(Point)) ?Point {
        const p = self.points.items[point_id.idx];
        if (p.gen == point_id.gen and p.isAlive()) {
            return p.content;
        }
        return null;
    }

    pub fn addPoint(self: *Scene, x: f32, y: f32) !Id(Point) {
        return addToList(Point, self.allocator, &self.points, &self.points_freelist, Point.init(x, y));
    }

    pub fn deletePoint(self: *Scene, point_id: Id(Point)) !void {
        const did_delete = try removeFromList(Point, self.allocator, &self.points, &self.points_freelist, point_id);
        if (did_delete) {
            for (self.segments.items, 0..) |*segment, i| {
                if (segment.isAlive() and (segment.content.start.eq(point_id) or segment.content.end.eq(point_id))) {
                    try self.deleteSegment(.{ .idx = i, .gen = segment.gen });
                }
            }
        }
    }

    pub fn addSegment(self: *Scene, start: Id(Point), end: Id(Point)) !Id(Segment) {
        return addToList(Segment, self.allocator, &self.segments, &self.segments_freelist, Segment.init(start, end));
    }

    pub fn deleteSegment(self: *Scene, segment_id: Id(Segment)) !void {
        _ = try removeFromList(Segment, self.allocator, &self.segments, &self.segments_freelist, segment_id);
    }
};

test "addPoint adds points" {
    const gpa = std.testing.allocator;
    var scene = Scene.init(gpa);
    defer scene.deinit();

    const id = try scene.addPoint(1, 1);
    try std.testing.expectEqual(1, scene.points.items.len);
    try std.testing.expectEqualDeep(
        WithGen(Point){ .content = Point.init(1, 1), .gen = 0 },
        scene.points.items[0],
    );
    try std.testing.expectEqualDeep(scene.getPoint(id), Point.init(1, 1));
}

test "deletePoint tombstones correctly" {
    const gpa = std.testing.allocator;
    var scene = Scene.init(gpa);
    defer scene.deinit();

    const id = try scene.addPoint(1, 1);

    try scene.deletePoint(id);
    try std.testing.expectEqual(1, scene.points.items.len);
    try std.testing.expectEqual(1, scene.points_freelist.items.len);
    try std.testing.expectEqualDeep(
        WithGen(Point){ .content = Point.init(1, 1), .gen = 1 },
        scene.points.items[0],
    );
    try std.testing.expectEqualDeep(scene.getPoint(id), null);
}

test "deletePoint cascade deletes Segments" {
    const gpa = std.testing.allocator;
    var scene = Scene.init(gpa);
    defer scene.deinit();

    const p1 = try scene.addPoint(1, 1);
    const p2 = try scene.addPoint(2, 2);
    const p3 = try scene.addPoint(3, 3);
    _ = try scene.addSegment(p1, p2);
    _ = try scene.addSegment(p2, p3);
    _ = try scene.addSegment(p1, p3);

    try scene.deletePoint(p2);

    try std.testing.expectEqual(3, scene.points.items.len);
    try std.testing.expectEqual(1, scene.points_freelist.items.len);
    try std.testing.expectEqualDeep(scene.getPoint(p1), Point.init(1, 1));
    try std.testing.expectEqualDeep(scene.getPoint(p2), null);
    try std.testing.expectEqualDeep(scene.getPoint(p3), Point.init(3, 3));

    try std.testing.expectEqual(3, scene.segments.items.len);
    try std.testing.expectEqual(2, scene.segments_freelist.items.len);
    try std.testing.expectEqualDeep(
        WithGen(Segment){ .content = Segment.init(p1, p2), .gen = 1 },
        scene.segments.items[0],
    );
    try std.testing.expectEqualDeep(
        WithGen(Segment){ .content = Segment.init(p2, p3), .gen = 1 },
        scene.segments.items[1],
    );
    try std.testing.expectEqualDeep(
        WithGen(Segment){ .content = Segment.init(p1, p3), .gen = 0 },
        scene.segments.items[2],
    );
}

test "addSegment adds segments" {
    const gpa = std.testing.allocator;
    var scene = Scene.init(gpa);
    defer scene.deinit();

    const p1 = try scene.addPoint(1, 1);
    const p2 = try scene.addPoint(2, 2);
    _ = try scene.addSegment(p1, p2);

    try std.testing.expectEqual(1, scene.segments.items.len);
    try std.testing.expectEqualDeep(
        WithGen(Segment){ .content = Segment.init(p1, p2), .gen = 0 },
        scene.segments.items[0],
    );
}

test "deleteSegment tombstones correctly" {
    const gpa = std.testing.allocator;
    var scene = Scene.init(gpa);
    defer scene.deinit();

    const p1 = try scene.addPoint(1, 1);
    const p2 = try scene.addPoint(2, 2);
    const id = try scene.addSegment(p1, p2);

    try scene.deleteSegment(id);
    try std.testing.expectEqual(1, scene.segments.items.len);
    try std.testing.expectEqual(1, scene.segments_freelist.items.len);
    try std.testing.expectEqualDeep(
        WithGen(Segment){ .content = Segment.init(p1, p2), .gen = 1 },
        scene.segments.items[0],
    );
    try std.testing.expectEqualDeep(scene.getPoint(p1), Point.init(1, 1));
    try std.testing.expectEqualDeep(scene.getPoint(p2), Point.init(2, 2));
}

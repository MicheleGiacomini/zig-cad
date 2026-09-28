const cad = @import("cad");

pub const LineToolState = union(enum) {
    start,
    first_point_selected: cad.Point,

    pub fn init() LineToolState {
        return .start;
    }
};

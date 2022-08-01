const json = @import("std").json;

pub const IntegerOrString = union(enum) {
    String: []const u8,
    Integer: u64,
};

pub const JsonArrayOrObject = union(enum) {
    Array: json.Array,
    Object: json.ObjectMap,
};

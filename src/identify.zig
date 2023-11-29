const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const testing = std.testing;

pub fn identifyProjectType() !ProjectType {
    var dir = try fs.cwd().openDir(".", .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (mem.eql(u8, entry.name, "build.zig")) {
            return .zig;
        } else if (mem.eql(u8, entry.name, "Cargo.toml")) {
            return .rust;
        } else if (mem.eql(u8, entry.name, "Makefile")) {
            return .make;
        }
    }
    return .unknown;
}

pub const ProjectType = enum {
    zig,
    rust,
    make,
    unknown,
};

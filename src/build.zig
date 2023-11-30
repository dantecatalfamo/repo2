const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const testing = std.testing;

const identify = @import("identify.zig");

pub fn build(allocator: mem.Allocator, project_type: identify.ProjectType, optimize: Optimize) !void {
    switch (project_type) {
        .zig => {
            const optimize_arg = switch (optimize) {
                .debug => "-Doptimize=Debug",
                .release => "-Doptimize=ReleaseSafe",
            };
            var child = std.ChildProcess.init(&.{ "zig", "build", optimize_arg }, allocator);
            const exit = try child.spawnAndWait();
            if (exit.Exited != 0) {
                return error.BuildFail;
            }
        },
        .rust => {
            const args = switch (optimize) {
                .debug => &[_][]const u8{ "cargo", "build" },
                .release => &[_][]const u8{ "cargo", "build", "-r" },
            };
            var child = std.ChildProcess.init(args, allocator);
            const exit = try child.spawnAndWait();
            if (exit.Exited != 0) {
                return error.BuildFailed;
            }
        },
        .make => {
            var buf: [16]u8 = undefined;
            const ncpu = blk: {
                const n = try std.Thread.getCpuCount();
                break :blk try std.fmt.bufPrint(&buf, "{d}", .{ n });
            };
            var child = std.ChildProcess.init(&.{ "make", "-j", ncpu }, allocator);
            const exit = try child.spawnAndWait();
            if (exit.Exited != 0) {
                return error.BuildFailed;
            }
        },
        .unknown => {
            return error.UnknownBuildInstructions;
        }
    }
}

pub const Optimize = enum {
    debug,
    release,
};

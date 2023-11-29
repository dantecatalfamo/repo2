const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const testing = std.testing;

const identify = @import("identify.zig");
const env = @import("env.zig");

pub fn link(project_type: identify.ProjectType) !void {
    const defaults = env.getValues();

    switch (project_type) {
        .zig => {
            var curr_path_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
            const curr_path = try std.fs.cwd().realpath(".", &curr_path_buffer);
            const bin = try fs.cwd().openDir("zig-out/bin", .{ .iterate = true });
            var iter = bin.iterate();
            var old_path_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
            var old_path_alloc = std.heap.FixedBufferAllocator.init(&old_path_buffer);
            var new_path_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
            var new_path_alloc = std.heap.FixedBufferAllocator.init(&new_path_buffer);
            while (try iter.next()) |entry| {
                const old_path = try fs.path.join(old_path_alloc.allocator(), &.{ curr_path, "zig-out/bin", entry.name });
                const new_path = try fs.path.join(new_path_alloc.allocator(), &.{ defaults.bin, entry.name });
                std.debug.print("{s}: ", .{entry.name});
                std.os.symlink(old_path, new_path) catch |err| switch (err) {
                    error.PathAlreadyExists => {
                        var link_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
                        const existing_link = try std.os.readlink(new_path, &link_buffer);
                        std.debug.print("already linked to {s}\n", .{existing_link});
                        continue;
                    },
                    else => {
                        std.debug.print("failed: {s}\n", .{@errorName(err)});
                        return err;
                    },
                };
                std.debug.print("linked\n", .{});
            }
        },
        else => {
            return error.Unimplemented;
        }
    }
}

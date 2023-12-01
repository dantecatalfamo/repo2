const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const testing = std.testing;

const identify = @import("identify.zig");
const env = @import("env.zig");

pub fn link(allocator: mem.Allocator, project_type: identify.ProjectType, message_writer: anytype) !void {

    const defaults = try env.get();

    switch (project_type) {
        .zig => {
            var curr_path_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
            const curr_path = try std.fs.cwd().realpath(".", &curr_path_buffer);
            const zig_bin = try fs.path.join(allocator, &.{ "zig-out", "bin" });
            defer allocator.free(zig_bin);
            const bin = try fs.cwd().openDir(zig_bin, .{ .iterate = true });
            var iter = bin.iterate();
            while (try iter.next()) |entry| {
                const old_path = try fs.path.join(allocator, &.{ curr_path, zig_bin, entry.name });
                defer allocator.free(old_path);
                const new_path = try fs.path.join(allocator, &.{ defaults.bin, entry.name });
                defer allocator.free(new_path);
                std.debug.print("{s}: ", .{entry.name});
                std.os.symlink(old_path, new_path) catch |err| switch (err) {
                    error.PathAlreadyExists => {
                        var link_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
                        const existing_link = try std.os.readlink(new_path, &link_buffer);
                        if (mem.eql(u8, old_path, existing_link)) {
                            try message_writer.print("already linked\n", .{});
                        } else {
                            try message_writer.print("already linked to {s}\n", .{existing_link});
                        }
                        continue;
                    },
                    else => {
                        try message_writer.print("failed: {s}\n", .{@errorName(err)});
                        return err;
                    },
                };
                try message_writer.print("linked\n", .{});
            }
        },
        else => {
            return error.Unimplemented;
        }
    }
}

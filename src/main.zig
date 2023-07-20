const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const meta = std.meta;
const debug = std.debug;
const testing = std.testing;
const cloneUrl = @import("clone.zig").cloneUrl;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var args = std.process.args();
    _ = args.next();
    const command_str = args.next() orelse return error.NoCommand;
    const command = meta.stringToEnum(Command, command_str) orelse return error.InvalidCommand;

    switch (command) {
        .clone => {
            const url = args.next() orelse return error.MissingURL;
            const repo_path = try cloneUrl(allocator, url);
            defer allocator.free(repo_path);
            try stdout.print("{s}\n", .{ repo_path });
        },
        .cd => {

        },
    }
}

const Command = enum {
    clone,
    cd,
};

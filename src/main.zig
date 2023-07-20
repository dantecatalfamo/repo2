const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const meta = std.meta;
const debug = std.debug;
const testing = std.testing;
const cloneUrl = @import("clone.zig").cloneUrl;
const repoCd = @import("cd.zig").repoCd;
const shell_funcs = @embedFile("repo.sh");

const usage_str =
    \\usage: repo <command> [<args>]
    \\
    \\Commands:
    \\  cd      Change to a project directory under ~/src
    \\  clone   Clone a repository into ~/src according to the site, user, and project
    \\  help    Display this help information
    \\  shell   Print shell helper functions for eval
    \\
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdOut().writer();

    var args = std.process.args();
    _ = args.next();
    const command_str = args.next() orelse return error.NoCommand;
    const command = meta.stringToEnum(Command, command_str) orelse {
        try stderr.print(usage_str, .{});
        return error.InvalidCommand;
    };

    const src_root = blk: {
        var path: [std.os.PATH_MAX]u8 = undefined;
        var static_alloc = std.heap.FixedBufferAllocator.init(&path);
        const home_path = std.os.getenv("HOME") orelse return error.NoHome;
        break :blk try fs.path.join(static_alloc.allocator(), &.{ home_path, "src" });
    };

    switch (command) {
        .clone => {
            const url = args.next() orelse return error.MissingURL;
            const repo_path = cloneUrl(allocator, src_root, url) catch |err| switch (err) {
                error.RepoExists => std.os.exit(2),
                else => return err,
            };
            defer allocator.free(repo_path);
            try stdout.print("{s}\n", .{ repo_path });
        },
        .cd => {
            const spec = args.next() orelse return error.MissingSpec;
            const repo_path = try repoCd(allocator, src_root, spec);
            defer allocator.free(repo_path);
            try stdout.print("{s}\n", .{ repo_path });
        },
        .help => {
            try stderr.print(usage_str, .{});
        },
        .shell => {
            try stdout.writeAll(shell_funcs);
        },
    }
}

const Command = enum {
    clone,
    cd,
    help,
    shell,
};

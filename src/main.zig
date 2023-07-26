const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const meta = std.meta;
const debug = std.debug;
const testing = std.testing;
const clone = @import("clone.zig");
const cd = @import("cd.zig");
const shell_funcs = @embedFile("repo.sh");
const env = @import("env.zig");
const new = @import("new.zig");

const usage_str =
    \\Usage: repo <command> [args]
    \\
    \\Commands:
    \\  cd      Change to a project directory under ~/src
    \\  clone   Clone a repository into ~/src according to the site, user, and project
    \\  help    Display this help information
    \\  shell   Print shell helper functions for eval
    \\  env     Print the current default environment values
    \\  ls      List all repo directories
    \\  new     Create a new project directory from a template
    \\
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    var args = std.process.args();
    _ = args.next();
    const command_str = args.next() orelse {
        try stderr.print(usage_str, .{});
        std.os.exit(1);
    };
    const command = meta.stringToEnum(Command, command_str) orelse {
        try stderr.print(usage_str, .{});
        std.os.exit(1);
    };

    const defaults = env.getValues();

    switch (command) {
        .clone => {
            const url = args.next() orelse {
                try clone.cloneUrlUsage(stderr);
                std.os.exit(2);
            };
            try stderr.print("Cloning {s}\n", .{ url });
            const repo_path = clone.cloneUrl(allocator, defaults.root, url) catch |err| switch (err) {
                error.CloneFailed => {
                    try stderr.print("Clone failed\n", .{});
                    std.os.exit(2);
                },
                else => return err,
            };
            defer allocator.free(repo_path);
            try stdout.print("{s}\n", .{ repo_path });
        },
        .cd => {
            const spec = args.next() orelse {
                try stdout.print("{s}\n", .{ defaults.root });
                return;
            };
            const repo_path = cd.repoCd(allocator, defaults.root, spec) catch |err| switch (err) {
                error.NoMatch => {
                    try stderr.print("No matching repositories\n", .{});
                    std.os.exit(2);
                },
                else => return err,
            };
            defer allocator.free(repo_path);
            try stdout.print("{s}\n", .{ repo_path });
        },
        .help => {
            try stderr.print(usage_str, .{});
        },
        .shell => {
            try stdout.writeAll(shell_funcs);
        },
        .env => {
            inline for (std.meta.fields(env.EnvironmentValues)) |field| {
                const upper_str = blk: {
                    var buf: [256]u8 = undefined;
                    break :blk std.ascii.upperString(&buf, field.name);
                };
                try stderr.print("REPO_DEFAULT_{s}={s}\n", .{ upper_str, @field(defaults, field.name) });
            }
        },
        .ls => {
            const dirs = try cd.collectDirs(allocator, defaults.root, 2);
            defer cd.freeCollectDirs(allocator, dirs);
            for (dirs) |dir| {
                try stdout.print("{s}\n", .{ dir[defaults.root.len+1..] });
            }
        },
        .new => {
            const repo_type = blk: {
                const type_str = args.next() orelse "";
                break :blk std.meta.stringToEnum(new.RepoType, type_str) orelse {
                    try new.newRepoUsage(stderr);
                    std.os.exit(2);
                };
            };
            const repo_name = args.next() orelse {
                try new.newRepoUsage(stderr);
                std.os.exit(2);
            };
            const repo_path = try new.newRepo(allocator, defaults.root, repo_type, repo_name);
            defer allocator.free(repo_path);

            try stdout.print("{s}\n", .{ repo_path });
        }
    }
}

const Command = enum {
    clone,
    cd,
    help,
    shell,
    env,
    ls,
    new,
};

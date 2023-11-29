const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const meta = std.meta;
const os = std.os;
const debug = std.debug;
const testing = std.testing;
const build = @import("build.zig");
const clone = @import("clone.zig");
const cd = @import("cd.zig");
const identify = @import("identify.zig");
const link = @import("link.zig");
const shell_funcs = @embedFile("repo.sh");
const env = @import("env.zig");
const new = @import("new.zig");
const root = @import("root.zig");

const usage_str =
    \\Usage: repo <command> [args]
    \\
    \\Commands:
    \\  build   Build project
    \\  cd      Change to a project directory under ~/src
    \\  clone   Clone a repository into ~/src according to the site, user, and project
    \\  help    Display this help information
    \\  shell   Print shell helper functions for eval
    \\  env     Print the current default environment values
    \\  link    Link the build artifacts into the user's bin directory
    \\  ls      List all repo directories
    \\  new     Create a new project directory from a template
    \\  root    Change directory to the project root
    \\  reload  Reload and re-evaluate shell functions
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
        .build => {
            const optimize = blk: {
                const opt = args.next() orelse break :blk build.Optimize.debug;
                if (mem.startsWith(u8, opt, "r")) {
                    break :blk build.Optimize.release;
                }
                break :blk build.Optimize.debug;
            };
            try root.cdRepoRoot();
            const project_type = try identify.identifyProjectType();
            try stderr.print("Building {s} in {s} mode\n", .{ @tagName(project_type), @tagName(optimize) });
            try build.build(allocator, project_type, optimize);
        },
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
        .link => {
            try root.cdRepoRoot();
            const project_type = try identify.identifyProjectType();
            try link.link(project_type);
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
        },
        .root => {
            var path_buffer: [os.PATH_MAX]u8 = undefined;
            const path = root.findRepoRoot(&path_buffer) catch {
                try stderr.print("Cannot find project root\n", .{});
                os.exit(2);
            };
            try stdout.print("{s}\n", .{ path });
        },
    }
}

const Command = enum {
    build,
    clone,
    cd,
    help,
    shell,
    env,
    link,
    ls,
    new,
    root,
};

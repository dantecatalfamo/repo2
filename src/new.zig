const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const process = std.process;
const testing = std.testing;

const getValues = @import("env.zig").getValues;

pub fn newRepo(allocator: mem.Allocator, src_root: []const u8, repo_type: RepoType, repo_name: []const u8) ![]const u8 {
    const defaults = getValues();
    const repo_path = try fs.path.join(allocator, &.{ src_root, defaults.host, defaults.user, repo_name });
    errdefer allocator.free(repo_path);

    try fs.cwd().makePath(repo_path);
    try process.changeCurDir(repo_path);

    var child_git = std.ChildProcess.init(&.{ "git", "init" }, allocator);
    child_git.stdout_behavior = .Ignore;

    const term_git = try child_git.spawnAndWait();
    if (term_git.Exited != 0) {
        return error.RepoInit;
    }

    switch (repo_type) {
        .none => {},
        .rails => {
            // FIXME There should be a way to redirect a child
            // process' stdout to stderr in zig without resorting to a
            // shell process, but I don't know what it is right now
            var child_rails = std.ChildProcess.init(&.{ "sh", "-c", "rails new . 1>&2" }, allocator);
            const term_rails = try child_rails.spawnAndWait();
            if (term_rails.Exited != 0) {
                return error.RailsInit;
            }
        },
        .zig_exe => {
            var child_zig = std.ChildProcess.init(&.{ "zig", "init-exe" }, allocator);
            const term_zig = try child_zig.spawnAndWait();
            if (term_zig.Exited != 0) {
                return error.ZigInit;
            }
        },
        .zig_lib => {
            var child_zig = std.ChildProcess.init(&.{ "zig", "init-lib" }, allocator);
            const term_zig = try child_zig.spawnAndWait();
            if (term_zig.Exited != 0) {
                return error.ZigInit;
            }
        },
    }

    return repo_path;
}

pub fn newRepoUsage(writer: anytype) !void {
    try writer.print("Usage: repo new <type> <name>\n\n", .{});
    try writer.print("Valid repo types:\n", .{});
    inline for (std.meta.fields(RepoType)) |field| {
        try writer.print("  {s}\n", .{ field.name });
    }
}

pub const RepoType = enum {
    rails,
    zig_exe,
    zig_lib,
    none
};

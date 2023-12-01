const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;

pub const EnvironmentValues = struct {
    host: []const u8,
    user: []const u8,
    auth_user: []const u8,
    use_ssh: []const u8,
    root: []const u8,
    bin: []const u8,
};

var environment: ?EnvironmentValues = null;

pub fn init(allocator: mem.Allocator) !void {
    const home_path = std.os.getenv("HOME") orelse "";
    const root = try fs.path.join(allocator, &.{ home_path, "src" });
    errdefer allocator.free(root);
    const bin = try fs.path.join(allocator, &.{ home_path, "bin" });
    errdefer allocator.free(bin);
    environment = .{
        .host = std.os.getenv("REPO_DEFAULT_HOST") orelse "github.com",
        .user = std.os.getenv("REPO_DEFAULT_USER") orelse "dantecatalfamo",
        .auth_user = std.os.getenv("REPO_DEFAULT_AUTH_USER") orelse "git",
        .use_ssh = std.os.getenv("REPO_DEFAULT_USE_SSH") orelse "true",
        .root = std.os.getenv("REPO_DEFAULT_ROOT") orelse root,
        .bin = std.os.getenv("REPO_DEFAULT_BIN") orelse bin,
    };
}

pub fn deinit(allocator: mem.Allocator) void {
    if (environment) |env| {
        allocator.free(env.root);
        allocator.free(env.bin);
    }
    environment = null;
}

pub fn get() !EnvironmentValues {
    if (environment) |env|
        return env;
    return error.EnvironmentNotInitialized;
}

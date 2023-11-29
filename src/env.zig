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

pub fn getValues() EnvironmentValues {
    const root = struct {
        var buf: [std.os.PATH_MAX]u8 = undefined;
        var path: []const u8 = "";
    };

    const bin = struct {
        var buf: [std.os.PATH_MAX]u8 = undefined;
        var path: []const u8 = "";
    };

    const home_path = std.os.getenv("HOME") orelse "";

    root.path = blk: {
        var static_alloc = std.heap.FixedBufferAllocator.init(&root.buf);
        break :blk fs.path.join(static_alloc.allocator(), &.{ home_path, "src" }) catch unreachable;
    };

    bin.path = blk: {
        var static_alloc = std.heap.FixedBufferAllocator.init(&bin.buf);
        break :blk fs.path.join(static_alloc.allocator(), &.{ home_path, "bin" }) catch unreachable;
    };

    return .{
        .host = std.os.getenv("REPO_DEFAULT_HOST") orelse "github.com",
        .user = std.os.getenv("REPO_DEFAULT_USER") orelse "dantecatalfamo",
        .auth_user = std.os.getenv("REPO_DEFAULT_AUTH_USER") orelse "git",
        .use_ssh = std.os.getenv("REPO_DEFAULT_USE_SSH") orelse "true",
        .root = std.os.getenv("REPO_DEFAULT_ROOT") orelse root.path,
        .bin = std.os.getenv("REPO_DEFAULT_BIN") orelse bin.path,
    };
}

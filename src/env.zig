const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;

pub const EnvironmentValues = struct {
    host: []const u8,
    user: []const u8,
    auth_user: []const u8,
    use_ssh: []const u8,
};

pub fn getValues() EnvironmentValues {
    return .{
        .host = std.os.getenv("REPO_DEFAULT_HOST") orelse "github.com",
        .user = std.os.getenv("REPO_DEFAULT_USER") orelse "dantecatalfamo",
        .auth_user = std.os.getenv("REPO_DEFAULT_AUTH_USER") orelse "git",
        .use_ssh = std.os.getenv("REPO_DEFAULT_USE_SSH") orelse "true",
    };
}

const std = @import("std");
const fs = std.fs;
const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const debug = std.debug;
const testing = std.testing;
const Origin = @import("Origin.zig");
const env = @import("env.zig");

pub fn cloneUrl(allocator: mem.Allocator, src_root: []const u8, url: []const u8) ![]const u8 {
    var partial_buf: [4096]u8 = undefined;

    const full_url = blk: {
        if (mem.startsWith(u8, url, "http") or mem.indexOf(u8, url, ":") != null) {
            break :blk url;
        }
        break :blk try urlFromPartial(&partial_buf, url);
    };

    const origin = try parseURL(full_url);

    const repo_paent_path = try fs.path.join(allocator, &.{ src_root, origin.host, origin.user });
    defer allocator.free(repo_paent_path);

    const repo_path = try fs.path.join(allocator, &.{ repo_paent_path, origin.repo });
    errdefer allocator.free(repo_path);

    if (try dirExists(repo_path)) {
        return repo_path;
    }

    try fs.cwd().makePath(repo_paent_path);

    var git_clone = std.ChildProcess.init(&.{ "git", "-C", repo_paent_path, "clone", "--recursive", origin.full_path }, allocator);
    const term = try git_clone.spawnAndWait();
    if (term.Exited != 0) {
        return error.CloneFailed;
    }

    return repo_path;
}

pub fn dirExists(path: []const u8) !bool {
    fs.cwd().access(path, .{}) catch |err| {
        return switch (err) {
            error.FileNotFound => false,
            else => err
        };
    };
    return true;
}

pub fn urlFromPartial(buf: []u8, partial: []const u8) ![]const u8 {
    const defaults = try env.get();
    const use_ssh = mem.eql(u8, defaults.use_ssh, "true");

    if (mem.indexOf(u8, partial, "/")) |_| {
        if (use_ssh) {
            return try fmt.bufPrint(buf, "{s}@{s}:{s}", .{ defaults.auth_user, defaults.host, partial });
        }
        return try fmt.bufPrint(buf, "https://{s}/{s}", .{ defaults.host, partial });
    }
    if (use_ssh) {
        return try fmt.bufPrint(buf, "{s}@{s}:{s}/{s}", .{ defaults.auth_user, defaults.host, defaults.user, partial });
    }
    return try fmt.bufPrint(buf, "https://{s}/{s}/{s}", .{ defaults.host, defaults.user, partial });
}

pub fn parseURL(url: []const u8) !Origin {
    // TODO git:// URLs
    if (mem.startsWith(u8, url, "http")) {
        return try parseHttpUrl(url);
    }
    return try parseSshUrl(url);
}

pub fn parseHttpUrl(url: []const u8) !Origin {
    const uri = try std.Uri.parse(url);

    const host = uri.host orelse return error.MissingHost;
    var path_iter = mem.split(u8, uri.path, "/");
    _ = path_iter.next();
    const user = path_iter.next() orelse return error.UrlTooShort;
    const repo = blk: {
        const s = path_iter.next() orelse return error.UrlTooShort;
        if (mem.endsWith(u8, s, ".git")) {
            break :blk s[0..s.len-".git".len];
        }
        break :blk s;
    };
    const transport = meta.stringToEnum(Origin.Transport, uri.scheme) orelse return error.InvalidTransport;
    const port = uri.port;
    const auth_user = uri.user;
    const auth_pass = uri.password;

    return Origin{
        .full_path = url,
        .host = host,
        .user = user,
        .repo = repo,
        .transport = transport,
        .port = port,
        .branch = null,
        .auth_user = auth_user,
        .auth_pass = auth_pass,
    };
}

pub fn parseSshUrl(url: []const u8) !Origin {
    const schemeless_url = blk: {
        if (mem.startsWith(u8, url, "ssh://")) {
            break :blk url["ssh://".len..];
        }
        break :blk url;
    };
    var iter = mem.tokenizeAny(u8, schemeless_url, "@:/");
    const auth_user = iter.next() orelse return error.InvalidSshUrl;
    const host = iter.next() orelse return error.InvalidSshUrl;
    const user = iter.next() orelse return error.InvalidSshUrl;
    const repo = blk: {
        const s = iter.next() orelse return error.InvalidSshUrl;
        if (mem.endsWith(u8, s, ".git")) {
            break :blk s[0..s.len-".git".len];
        }
        break :blk s;
    };


    return Origin{
        .full_path = url,
        .host = host,
        .user = user,
        .repo = repo,
        .branch = null,
        .transport = Origin.Transport.ssh,
        .port = null,
        .auth_user = auth_user,
        .auth_pass = null,
    };
}

pub fn cloneUrlUsage(writer: anytype) !void {
    const usage =
        \\Usage: repo clone <spec>
        \\
        \\Missing infirmation is filled using environment variables
        \\See `repo env` for details
        \\Where spec can be:
        \\  https://<host>/<user>/<repo>
        \\  <auth_user>@<host>:<user>/<repo>
        \\  <user>/<repo>
        \\  <repo>
        \\
    ;
    try writer.print(usage, .{});
}

test "http url parse" {
    const url = "https://github.com/dantecatalfamo/repo2";
    const origin = try parseURL(url);

    const expected = Origin{
        .full_path = "https://github.com/dantecatalfamo/repo2",
        .host = "github.com",
        .user = "dantecatalfamo",
        .repo = "repo2",
        .transport = Origin.Transport.https,
        .branch = null,
        .port = null,
        .auth_user = null,
        .auth_pass = null,
    };
    try testing.expectEqualDeep(expected, origin);
}

test "ssh url parse" {
    const url = "git@github.com:dantecatalfamo/repo2.git";
    const origin = try parseURL(url);

    const expected = Origin{
        .full_path = "git@github.com:dantecatalfamo/repo2.git",
        .host = "github.com",
        .user = "dantecatalfamo",
        .repo = "repo2",
        .transport = Origin.Transport.ssh,
        .branch = null,
        .port = null,
        .auth_user = "git",
        .auth_pass = null,
    };
    try testing.expectEqualDeep(expected, origin);
}

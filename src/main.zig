const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const meta = std.meta;
const debug = std.debug;
const testing = std.testing;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var args = std.process.args();
    _ = args.next();
    const command = meta.stringToEnum(Command, args.next().?) orelse return error.InvalidCommand;

    switch (command) {
        .clone => {
            try cloneUrl(allocator, args.next() orelse return error.MissingURL);
        },
        .cd => {

        },
    }
}

const Command = enum {
    clone,
    cd,
};

pub fn cloneUrl(allocator: mem.Allocator, url: []const u8) !void {
    const log = std.log.scoped(.clone);
    const stdout = std.io.getStdOut().writer();

    log.debug("url: {s}", .{ url });
    const origin = try parseURL(url);
    log.debug("origin: {any}", .{ origin });

    const home_path = std.os.getenv("HOME") orelse return error.NoHome;

    const repo_paent_path = try fs.path.join(allocator, &.{ home_path, "src", origin.host, origin.user });
    defer allocator.free(repo_paent_path);

    const repo_path = try fs.path.join(allocator, &.{ repo_paent_path, origin.repo });
    defer allocator.free(repo_path);

    if (try dirExists(repo_path)) {
        return error.RepoExists;
    }

    try fs.cwd().makePath(repo_paent_path);
    try std.process.changeCurDir(repo_paent_path);
    var git_clone = std.ChildProcess.init(&.{ "git", "clone", origin.full_path }, allocator);
    const term = try git_clone.spawnAndWait();
    if (term.Exited != 0) {
        return error.CloneFailed;
    }
    try stdout.print("{s}\n", .{ repo_path });
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

pub fn parseURL(url: []const u8) !Origin {
    if (mem.startsWith(u8, url, "http")) {
        return try parseHttpUrl(url);
    }
    // TODO git:// URLs
    return try parseSshUrl(url);
}

test "http url parse" {
    const url = "https://github.com/dantecatalfamo/repo2";
    const origin = try parseURL(url);

    const expected = Origin{
        .full_path = "https://github.com/dantecatalfamo/repo2",
        .host = "github.com",
        .user = "dantecatalfamo",
        .repo = "repo2",
        .transport = Transport.https,
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
        .transport = Transport.ssh,
        .branch = null,
        .port = null,
        .auth_user = "git",
        .auth_pass = null,
    };
    try testing.expectEqualDeep(expected, origin);

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
    const transport = meta.stringToEnum(Transport, uri.scheme) orelse return error.InvalidTransport;
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
        .transport = Transport.ssh,
        .port = null,
        .auth_user = auth_user,
        .auth_pass = null,
    };
}

pub const Origin = struct {
    full_path: []const u8,
    host: []const u8,
    user: []const u8,
    repo: []const u8,
    transport: Transport,
    branch: ?[]const u8,
    port: ?u16,
    auth_user: ?[]const u8,
    auth_pass: ?[]const u8,

    pub fn format(
        self: Origin,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;
        try writer.print("Origin{{\n", .{});
        try writer.print("  .full_path = {s}\n", .{ self.full_path });
        try writer.print("  .host = {s}\n", .{ self.host });
        try writer.print("  .user = {s}\n", .{ self.user });
        try writer.print("  .repo = {s}\n", .{ self.repo });
        try writer.print("  .transport = {s}\n", .{ @tagName(self.transport) });
        try writer.print("  .branch = {?s}\n", .{ self.branch });
        try writer.print("  .port = {?d}\n", .{ self.port });
        try writer.print("  .auth_user = {?s}\n", .{ self.auth_user });
        try writer.print("  .auth_pass = {?s}\n", .{ self.auth_pass });
        try writer.print("}}", .{});
    }
};

pub const Transport = enum {
    http,
    https,
    ssh,
};

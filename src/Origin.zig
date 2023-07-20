const std = @import("std");
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;

const Origin = @This();

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

pub const Transport = enum {
    http,
    https,
    ssh,
};

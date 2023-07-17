const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {

}

pub fn parseURL(origin: []const u8) !Origin {
    const uri = try std.Uri.parse(origin);
    _ = uri;
}

pub const Origin = struct {
    host: []const u8,
    user: []const u8,
    repo: []const u8,
    transport: Transport,
    branch: ?[]const u8,
    port: ?u16,
    auth_user: ?[]const u8,
    auth_pass: ?[]const u8,
};

pub const Transport = enum {
    http,
    https,
    ssh,
};

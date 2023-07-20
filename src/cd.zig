const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const debug = std.debug;
const testing = std.testing;

pub fn repoCd(allocator: mem.Allocator, src_root: []const u8, spec: []const u8) ![]const u8 {
    const all_dirs = try collectDirs(allocator, src_root, 2);
    defer freeCollectDirs(allocator, all_dirs);

    var selected = std.ArrayList([]const u8).init(allocator);
    defer selected.deinit();

    for (all_dirs) |dir| {
        if (mem.indexOf(u8, dir, spec)) |_| {
            try selected.append(dir);
        }
    }

    if (selected.items.len == 0) {
        return error.NoMatch;
    }

    if (selected.items.len > 1) {
        const stderr = std.io.getStdErr().writer();
        for (selected.items, 0..) |sel, idx| {
            try stderr.print("{d}) {s}\n", .{ idx, sel[src_root.len+1..] });
        }
        const idx = try getSelection(selected.items.len-1);
        return try allocator.dupe(u8, selected.items[idx]);
    }

    return try allocator.dupe(u8, selected.items[0]);
}

fn getSelection(max: usize) !usize {
    const stderr = std.io.getStdErr().writer();
    const stdin = std.io.getStdIn().reader();
    var buf: [100]u8 = undefined;
    var buf_stream = std.io.fixedBufferStream(&buf);

    while (true) {
        try stderr.print("Selection [0]: ", .{});
        buf_stream.reset();
        try stdin.streamUntilDelimiter(buf_stream.writer(), '\n', buf.len);

        if (buf_stream.pos == 0) {
            return 0;
        }

        const idx = std.fmt.parseInt(usize, buf[0..buf_stream.pos], 10) catch continue;

        if (idx > max)
            continue;

        return idx;
    }
}

pub fn collectDirs(allocator: mem.Allocator, parent: []const u8, depth: u8) ![][]const u8 {
    var collector = std.ArrayList([]const u8).init(allocator);
    try collectDirsImpl(allocator, parent, depth, &collector);
    var collected = try collector.toOwnedSlice();
    mem.sort([]const u8, collected, {}, strLessThan);
    return collected;
}

fn strLessThan(context: void, lhs: []const u8, rhs: []const u8) bool {
    _ = context;
    return mem.lessThan(u8, lhs, rhs);
}

pub fn freeCollectDirs(allocator: mem.Allocator, dirs: [][]const u8) void {
    for (dirs) |dir| {
        allocator.free(dir);
    }
    allocator.free(dirs);
}

fn collectDirsImpl(allocator: mem.Allocator, parent: []const u8, depth: u8, collector: *std.ArrayList([]const u8)) !void {
    var dir = try fs.cwd().openIterableDir(parent, .{});
    defer dir.close();
    var iter = dir.iterate();
    while(try iter.next()) |entry| {
        if (entry.kind != .directory)
            continue;

        const child_path = blk: {
            var path: [std.os.PATH_MAX]u8 = undefined;
            var static_alloc = std.heap.FixedBufferAllocator.init(&path);
            break :blk try fs.path.join(static_alloc.allocator(), &.{ parent, entry.name });
        };
        if (depth == 0) {
            try collector.append(try allocator.dupe(u8, child_path));
        } else {
            try collectDirsImpl(allocator, child_path, depth - 1, collector);
        }
    }
}

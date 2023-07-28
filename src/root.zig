const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const testing = std.testing;

pub fn cdRepoRoot() !void {
    var path_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
    const path = try findRepoRoot(&path_buffer);
    try os.chdir(path);
}

pub fn findRepoRoot(buffer: []u8) ![]u8 {
    var path_buffer: [fs.MAX_PATH_BYTES]u8 = undefined;
    var dir = fs.cwd();

    while (true) {
        const absolute_path = try dir.realpath(".", &path_buffer);

        dir.access(".git", .{}) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    if (mem.eql(u8, absolute_path, "/")) {
                        return error.NoGitRepo;
                    }

                    var new_dir = try dir.openDir("..", .{});
                    // Can't close fs.cwd() or we get BADF
                    if (dir.fd != fs.cwd().fd) {
                        dir.close();
                    }

                    dir = new_dir;
                    continue;
                },
                else => return err,
            }
        };

        if (dir.fd != fs.cwd().fd) {
            dir.close();
        }

        var out_path = buffer[0..absolute_path.len];
        @memcpy(out_path, absolute_path);

        return out_path;
    }
}

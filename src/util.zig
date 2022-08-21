const std = @import("std");

const stdout = std.io.getStdOut();
const stderr = std.io.getStdErr();
const exit = std.os.exit;

pub fn isSpace(char: u8) bool {
    return char == ' ' or char == '\t' or char == '\n';
}

pub fn isDigit(char: u8) bool {
    return '0' <= char and char <= '9';
}

pub fn getInt(comptime T: type, input: []const T, start: *usize) i32 {
    var end: usize = start.* + 1;
    while (input[end] != 0) : (end += 1) {
        if (!isDigit(input[end])) break;
    }
    const ret = std.fmt.parseInt(i32, input[start.*..end], 10) catch 0;
    start.* = end;
    return ret;
}

pub fn errorAt(input: *const []const u8, loc: usize, string: []const u8) !void {
    try stderr.writer().print("{s}\n", .{input.*});
    {
        var i: usize = 0;
        while (i != loc) : (i += 1) {
            try stderr.writer().print("{c}", .{' '});
        }
    }
    try stderr.writer().print("{s}", .{"^ "});
    try stderr.writer().print("{s}\n", .{string});
    exit(1);
}

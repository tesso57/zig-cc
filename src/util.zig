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
    start.* = end - 1;
    return ret;
}

pub fn isIdent1(p: u8) bool {
    return ('a' <= p and p <= 'z') or ('A' <= p and p <= 'Z') or p == '_';
}

pub fn isIdent2(p: u8) bool {
    return isIdent1(p) or ('0' <= p and p <= '9');
}

pub fn isAlnum(p: u8) bool {
    return isIdent2(p);
}

pub fn errorAt(input: []const u8, loc: usize, string: []const u8) !void {
    try stderr.writer().print("{s}\n", .{input});
    var i: usize = 0;
    while (i != loc) : (i += 1) {
        try stderr.writer().print("{c}", .{' '});
    }
    try stderr.writer().print("{s}", .{"^ "});
    try stderr.writer().print("{s}\n", .{string});
    exit(1);
}

pub fn isEqual(this: []const u8, that: []const u8) bool {
    if (this.len != that.len) return false;
    for (this) |_, i| {
        if (this[i] != that[i]) return false;
    }
    return true;
}

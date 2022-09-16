const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const testing = std.testing;
const mem = std.mem;
const SinglyLinkedList = std.SinglyLinkedList;
const Allocator = mem.Allocator;
const exit = std.os.exit;

const stdout = std.io.getStdOut();
const stderr = std.io.getStdErr();

const parse = @import("./parse.zig");
const codegen = @import("./codegen.zig");

pub fn main() !void {
    if (std.os.argv.len < 2) {
        try stderr.writeAll("引数の個数が正しくありません");
        exit(1);

        return;
    }

    var i: usize = 0;
    while (std.os.argv[1][i] != 0) : (i += 1) {}
    var input: []const u8 = std.os.argv[1][0 .. i + 1];
    const func = try parse.parse(input);
    try codegen.codegen(func);

    return;
}

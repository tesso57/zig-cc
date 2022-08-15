const std = @import("std");
fn countChars(chars: [*:0]u8) usize {
    var i: usize = 0;
    while (true) {
        if (chars[i] == 0) {
            return i;
        }
        i += 1;
    }
}

fn getArgv() i32 {
    const arg1: [*:0]u8 = std.os.argv[1];
    const arg1_unmodifiable_slice: []const u8 = arg1[0..countChars(arg1)];
    const n: i32 = std.fmt.parseInt(i32, arg1_unmodifiable_slice, 10) catch 0;
    return n;
}

pub fn main() !void {
    const argv = getArgv();
    // std.debug.print("{!}", .{argv});
    const stdout = std.io.getStdOut().writer();
    try stdout.print(".intel_syntax noprefix\n", .{});
    try stdout.print(".global main\n", .{});
    try stdout.print("main:\n", .{});
    try stdout.print("   mov rax, {!}\n", .{argv});
    try stdout.print("   ret\n", .{});
}

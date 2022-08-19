const std = @import("std");

pub const ParserError = error{InvalidCharacter};

pub fn Parser() type {
    return struct {
        data: []const u8,
        index: usize = 0,
        allocator: std.mem.Allocator,
        const Self = @This();

        pub fn init(data: []const u8, allocator: std.mem.Allocator) Self {
            return Self{ .data = data, .index = 0, .allocator = allocator };
        }

        fn getInt(self: *Self) i32 {
            if (self.index != 0) {
                self.index += 1;
            }
            const prevIndex = self.index;
            while (self.data[self.index] != 0) : (self.index += 1) {
                if (self.data[self.index] < '0' or self.data[self.index] > '9') break;
            }
            return std.fmt.parseInt(i32, self.data[prevIndex..(self.index)], 10) catch 0;
        }

        fn isEnd(self: *Self) bool {
            return self.data[self.index] != 0;
        }

        fn getTop(self: *Self) u8 {
            return self.data[self.index];
        }

        pub fn parse(self: *Self) ![]u8 {
            var list = std.ArrayList(u8).init(self.allocator);
            defer list.deinit();
            try list.appendSlice(".intel_syntax noprefix\n");
            try list.writer().print(".global main\n", .{});
            try list.writer().print("main:\n", .{});
            try list.writer().print("   mov rax, {!}\n", .{self.getInt()});

            while (self.isEnd()) {
                if (self.getTop() == '+') {
                    try list.writer().print("   add rax, {!}\n", .{self.getInt()});
                    continue;
                }

                if (self.getTop() == '-') {
                    try list.writer().print("   sub rax, {!}\n", .{self.getInt()});
                    continue;
                }

                return ParserError.InvalidCharacter;
            }
            try list.writer().print("   ret\n", .{});
            return list.toOwnedSlice();
        }
    };
}

pub fn main() !void {
    const stdout = std.io.getStdOut();
    const stderr = std.io.getStdErr();
    if (std.os.argv.len < 2) {
        try stderr.writeAll("引数の個数が正しくありません");
        return;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var i: usize = 0;
    while (std.os.argv[1][i] != 0) : (i += 1) {}
    const input: []const u8 = std.os.argv[1][0 .. i + 1];
    var arg = Parser().init(input, allocator);
    const items = try arg.parse();
    defer allocator.free(items);
    try stdout.writer().print("{s}\n", .{items});
    return;
}

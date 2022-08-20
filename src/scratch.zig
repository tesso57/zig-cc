const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const testing = std.testing;
const mem = std.mem;
const SinglyLinkedList = std.SinglyLinkedList;
const Allocator = mem.Allocator;
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

pub const TokenKind = enum {
    TK_RESERVED, // 記号
    TK_NUM, // 整数トークン
    TK_EOF, // 入力の終わりを示すトークン
};

pub const TokenError = error{InvalidCharacter};

pub fn Token() type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            kind: TokenKind,
            next: ?*Node,
            val: i32,
            char: u8,
        };

        allocator: Allocator,

        pub fn consume(node: *Node, op: u8) bool {
            return node.kind != TokenKind.TK_RESERVED or node.char != op;
        }

        pub fn expect(node: *Node, op: u8) !void {
            if (node.kind != TokenKind.TK_RESERVED or node.char != op)
                return ParserError.InvalidCharacter;
        }

        pub fn expectNumber(node: *Node) !i32 {
            if (node.kind != TokenKind.TK_NUM)
                return ParserError.InvalidCharacter;
            const val: i32 = node.val;
            return val;
        }

        pub fn atEof(node: *Node) bool {
            return node.kind == TokenKind.TK_EOF;
        }

        fn newToken(self: Self, kind: TokenKind, current: *Node, char: u8) *Node {
            var node = try self.allocator.create(Node);
            node.kind = kind;
            node.current = current;
            node.char = char;
            current.next = node;
            return &node;
        }

        pub fn tokenize(self: Self, string: []const u8) !void {
            const head = try self.allocator.create(Node);
            var current = head;
            var i: i32 = 0;
            while (string[i] != 0) : (i += 1) {
                var p = string[i];
                if (isSpace(p))
                    continue;

                if (p == '+' or p == '-') {
                    current = newToken(TokenKind.TK_RESERVED, current, p);
                    continue;
                }

                if (isDigit(p)) {
                    current = newToken(TokenKind.TK_RESERVED, current, p);
                    current.?.val = 0;
                }
            }
            newToken(TokenKind.TK_EOF, current, ' ');
        }
    };
}

fn isSpace(char: u8) bool {
    return char == ' ' or char == '\t' or char == '\n';
}

fn isDigit(char: u8) bool {
    return '0' <= char and char <= '9';
}
pub fn main() !void {
    const L = SinglyLinkedList(u32);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = try allocator.alloc(L, 1);
}

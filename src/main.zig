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

const allocator = std.heap.page_allocator;

pub const TokenKind = enum {
    TK_RESERVED, // 記号
    TK_NUM, // 整数トークン
    TK_EOF, // 入力の終わりを示すトークン
};

const Token = struct {
    kind: TokenKind,
    next: ?*Token,
    val: i32,
    pos: usize,
};

var token: ?*Token = null;
var input: []const u8 = undefined;

fn isSpace(char: u8) bool {
    return char == ' ' or char == '\t' or char == '\n';
}

fn isDigit(char: u8) bool {
    return '0' <= char and char <= '9';
}

fn getInt(start: *usize) i32 {
    var end: usize = start.* + 1;
    while (input[end] != 0) : (end += 1) {
        if (!isDigit(input[end])) break;
    }
    const ret = std.fmt.parseInt(i32, input[start.*..end], 10) catch 0;
    start.* = end;
    return ret;
}

fn errorAt(loc: usize, string: []const u8) !void {
    try stderr.writer().print("{s}\n", .{input});
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

fn consume(op: u8) bool {
    if (token.?.kind != TokenKind.TK_RESERVED or input[token.?.pos] != op) {
        return false;
    }
    token = token.?.next;
    return true;
}

fn expect(op: u8) !void {
    if (token.?.kind != TokenKind.TK_RESERVED or input[token.?.pos] != op) {
        try errorAt(token.?.pos, "expect error");
        exit(1);
    }
    token = token.?.next;
}

fn expectNumber() !i32 {
    if (token.?.kind != TokenKind.TK_NUM) {
        try errorAt(token.?.pos, "数ではない");
        exit(1);
    }

    const val = token.?.val;
    token = token.?.next;
    return val;
}

fn atEof() bool {
    return token.?.kind == TokenKind.TK_EOF;
}

fn newToken(kind: TokenKind, cur: *Token, pos: usize) !*Token {
    const tok = try allocator.create(Token);
    tok.kind = kind;
    tok.pos = pos;
    cur.next = tok;
    return tok;
}

fn tokenize(p: *const []const u8) !*Token {
    var head: ?Token = Token{ .kind = TokenKind.TK_RESERVED, .next = null, .val = 0, .pos = 0 };
    var cur = &(head.?);
    var i: usize = 0;
    while (p.*[i] != 0) : (i += 1) {
        if (isSpace(p.*[i]))
            continue;

        if (p.*[i] == '+' or p.*[i] == '-') {
            cur = try newToken(TokenKind.TK_RESERVED, cur, i);
            continue;
        }

        if (isDigit(p.*[i])) {
            cur = try newToken(TokenKind.TK_NUM, cur, i);
            cur.val = getInt(&i);
            i -= 1;
            continue;
        }
        try errorAt(i, "トークナイズできない");
        exit(1);
    }
    _ = try newToken(TokenKind.TK_EOF, cur, 0);
    return head.?.next.?;
}

pub fn main() !void {
    if (std.os.argv.len < 2) {
        try stderr.writeAll("引数の個数が正しくありません");
        exit(1);

        return;
    }

    var i: usize = 0;
    while (std.os.argv[1][i] != 0) : (i += 1) {}
    input = std.os.argv[1][0 .. i + 1];
    token = try tokenize(&input);
    try stdout.writeAll(".intel_syntax noprefix\n");
    try stdout.writeAll(".globl main\n");
    try stdout.writeAll("main:\n");
    try stdout.writer().print("   mov rax, {d}\n", .{try expectNumber()});

    while (!atEof()) {
        if (consume('+')) {
            try stdout.writer().print("   add rax, {d}\n", .{try expectNumber()});
            continue;
        }

        try expect('-');
        try stdout.writer().print("   sub rax, {d}\n", .{try expectNumber()});
    }
    try stdout.writeAll("   ret\n");

    return;
}

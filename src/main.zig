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
    char: u8,
};

var token: ?*Token = null;

fn consume(op: u8) bool {
    if (token.?.kind != TokenKind.TK_RESERVED or token.?.char != op) {
        return false;
    }
    token = token.?.next;
    return true;
}

fn expect(op: u8) !void {
    if (token.?.kind != TokenKind.TK_RESERVED or token.?.char != op) {
        try stderr.writeAll("expect error\n");
        exit(1);
    }
    token = token.?.next;
}

fn expectNumber() !i32 {
    if (token.?.kind != TokenKind.TK_NUM) {
        try stderr.writeAll("数ではない\n");
        exit(1);
    }

    const val = token.?.val;
    token = token.?.next;
    return val;
}

fn atEof() bool {
    return token.?.kind == TokenKind.TK_EOF;
}

fn newToken(kind: TokenKind, cur: *Token, char: u8) !*Token {
    const tok = try allocator.create(Token);
    tok.kind = kind;
    tok.char = char;
    cur.next = tok;
    return tok;
}

fn isSpace(char: u8) bool {
    return char == ' ' or char == '\t' or char == '\n';
}

fn isDigit(char: u8) bool {
    return '0' <= char and char <= '9';
}

fn getInt(p: []const u8, start: *usize) i32 {
    var end = start.* + 1;
    while (p[end] != 0) : (end += 1) {
        if (!isDigit(p[end])) break;
    }
    const ret = std.fmt.parseInt(i32, p[start.*..end], 10) catch 0;
    start.* = end;
    return ret;
}

fn tokenize(p: []const u8) !*Token {
    var head: ?Token = Token{ .kind = TokenKind.TK_RESERVED, .next = null, .val = 0, .char = ' ' };
    var cur = &(head.?);

    var i: usize = 0;
    while (p[i] != 0) : (i += 1) {
        if (isSpace(p[i]))
            continue;

        if (p[i] == '+' or p[i] == '-') {
            cur = try newToken(TokenKind.TK_RESERVED, cur, p[i]);
            continue;
        }

        if (isDigit(p[i])) {
            cur = try newToken(TokenKind.TK_NUM, cur, p[i]);
            cur.val = getInt(p, &i);
            i -= 1;
            continue;
        }

        try stderr.writeAll("トークナイズ失敗\n");
        exit(1);
    }

    _ = try newToken(TokenKind.TK_EOF, cur, '\n');
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
    const input: []const u8 = std.os.argv[1][0 .. i + 1];
    token = try tokenize(input);
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

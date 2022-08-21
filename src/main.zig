const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const testing = std.testing;
const mem = std.mem;
const SinglyLinkedList = std.SinglyLinkedList;
const Allocator = mem.Allocator;
const exit = std.os.exit;

const util = @import("util.zig");
const isDigit = util.isDigit;
const isSpace = util.isSpace;
fn errorAt(loc: usize, string: []const u8) !void {
    try util.errorAt(&input, loc, string);
}
fn getInt(start: *usize) i32 {
    return util.getInt(u8, input, start);
}

const stdout = std.io.getStdOut();
const stderr = std.io.getStdErr();

const allocator = std.heap.page_allocator;

const TokenKind = enum {
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

const NodeKind = enum {
    ND_ADD, // +
    ND_SUB, // -
    ND_MUL, // *
    ND_DIV, // /
    ND_NUM, // 整数
};

const Node = struct { kind: NodeKind, lhs: ?*Node, rhs: ?*Node, val: i32 };

var token: ?*Token = null;
var input: []const u8 = undefined;

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
    }
    token = token.?.next;
}

fn expectNumber() !i32 {
    if (token.?.kind != TokenKind.TK_NUM) {
        try errorAt(token.?.pos, "数ではない");
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

        if (p.*[i] == '+' or p.*[i] == '-' or p.*[i] == '*' or p.*[i] == '/' or p.*[i] == '(' or p.*[i] == ')') {
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
    }
    _ = try newToken(TokenKind.TK_EOF, cur, 0);
    return head.?.next.?;
}

fn newNode(kind: NodeKind, lhs: ?*Node, rhs: ?*Node) !*Node {
    var node = try allocator.create(Node);
    node.kind = kind;
    node.lhs = lhs;
    node.rhs = rhs;
    return node;
}

fn newNodeNum(val: i32) !*Node {
    var node = try allocator.create(Node);
    node.kind = NodeKind.ND_NUM;
    node.val = val;
    return node;
}

fn expr() !*Node {
    var node = try mul();
    while (true) {
        if (consume('+')) {
            node = try newNode(NodeKind.ND_ADD, node, try mul());
        } else if (consume('-')) {
            node = try newNode(NodeKind.ND_SUB, node, try mul());
        } else return node;
    }
}

fn mul() !*Node {
    var node = try primary();
    while (true) {
        if (consume('*')) {
            node = try newNode(NodeKind.ND_MUL, node, try primary());
        } else if (consume('/')) {
            node = try newNode(NodeKind.ND_DIV, node, try primary());
        } else return node;
    }
}

fn primary() anyerror!*Node {
    if (consume('(')) {
        const node = try expr();
        try expect(')');
        return node;
    }

    return newNodeNum(try expectNumber());
}

fn gen(node: *Node) anyerror!void {
    if (node.kind == NodeKind.ND_NUM) {
        try stdout.writer().print("   push {d}\n", .{node.val});
        return;
    }

    try gen(node.lhs.?);
    try gen(node.rhs.?);
    try stdout.writeAll("   pop rdi\n");
    try stdout.writeAll("   pop rax\n");

    switch (node.kind) {
        NodeKind.ND_ADD => {
            try stdout.writeAll("   add rax, rdi\n");
        },
        NodeKind.ND_SUB => {
            try stdout.writeAll("   sub rax, rdi\n");
        },
        NodeKind.ND_MUL => {
            try stdout.writeAll("   imul rax, rdi\n");
        },
        NodeKind.ND_DIV => {
            try stdout.writeAll("   cqo\n");
            try stdout.writeAll("   idiv rdi\n");
        },
        else => unreachable,
    }
    try stdout.writeAll("   push rax\n");
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
    const node = try expr();
    try stdout.writeAll(".intel_syntax noprefix\n");
    try stdout.writeAll(".globl main\n");
    try stdout.writeAll("main:\n");
    try gen(node);
    try stdout.writeAll("   pop rax\n");
    try stdout.writeAll("   ret\n");

    return;
}

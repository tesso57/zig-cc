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
const isEqual = util.isEqual;
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

const Token = struct { kind: TokenKind, next: ?*Token, val: i32, char: []const u8, pos: usize };

const NodeKind = enum {
    ND_ADD, // +
    ND_SUB, // -
    ND_MUL, // *
    ND_DIV, // /
    ND_NUM, // 整数
    ND_EQ, // ==
    ND_NE, // !=
    ND_LT, // <
    ND_LE, // <=
};

const Node = struct { kind: NodeKind, lhs: ?*Node, rhs: ?*Node, val: i32 };

// Global Variables
var token: ?*Token = null;
var input: []const u8 = undefined;

fn consume(op: []const u8) bool {
    if (token.?.kind != TokenKind.TK_RESERVED or !isEqual(token.?.char, op)) {
        return false;
    }
    token = token.?.next;
    return true;
}

fn expect(op: []const u8) !void {
    if (token.?.kind != TokenKind.TK_RESERVED or !isEqual(token.?.char, op)) {
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

fn newToken(kind: TokenKind, cur: *Token, char: []const u8) !*Token {
    const tok = try allocator.create(Token);
    tok.kind = kind;
    tok.char = char;
    tok.pos = 0;
    cur.next = tok;
    return tok;
}

fn tokenize(p: []const u8) !*Token {
    var head: ?Token = Token{ .kind = TokenKind.TK_RESERVED, .next = null, .val = 0, .char = "", .pos = 0 };
    var cur = &(head.?);
    var i: usize = 0;
    while (p[i] != 0) : (i += 1) {
        if (isSpace(p[i]))
            continue;

        if (p[i] == '!' or p[i] == '=') {
            if (p[i + 1] == '=') {
                cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 2]);
                i += 1;
                continue;
            }
        }

        if (p[i] == '>' or p[i] == '<') {
            if (p[i + 1] == '=') {
                cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 2]);
                i += 1;
                continue;
            }
            cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 1]);
            continue;
        }

        if (p[i] == '+' or p[i] == '-' or p[i] == '*' or p[i] == '/' or p[i] == '(' or p[i] == ')') {
            cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 1]);
            continue;
        }

        if (isDigit(p[i])) {
            cur = try newToken(TokenKind.TK_NUM, cur, p[i .. i + 1]);
            cur.val = getInt(&i);
            i -= 1;
            continue;
        }
        try errorAt(i, "トークナイズできない");
    }
    _ = try newToken(TokenKind.TK_EOF, cur, "");
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
    return try equality();
}

fn equality() !*Node {
    var node = try relational();
    while (true) {
        if (consume("==")) {
            node = try newNode(NodeKind.ND_EQ, node, try relational());
        } else if (consume("!=")) {
            node = try newNode(NodeKind.ND_NE, node, try relational());
        } else return node;
    }
}

fn relational() !*Node {
    var node = try add();

    while (true) {
        if (consume("<")) {
            node = try newNode(NodeKind.ND_LT, node, try add());
        } else if (consume("<=")) {
            node = try newNode(NodeKind.ND_LE, node, try add());
        } else if (consume(">")) {
            node = try newNode(NodeKind.ND_LT, try add(), node);
        } else if (consume(">=")) {
            node = try newNode(NodeKind.ND_LE, try add(), node);
        } else return node;
    }
}

fn add() !*Node {
    var node = try mul();
    while (true) {
        if (consume("+")) {
            node = try newNode(NodeKind.ND_ADD, node, try mul());
        } else if (consume("-")) {
            node = try newNode(NodeKind.ND_SUB, node, try mul());
        } else return node;
    }
}

fn mul() !*Node {
    var node = try unary();
    while (true) {
        if (consume("*")) {
            node = try newNode(NodeKind.ND_MUL, node, try unary());
        } else if (consume("/")) {
            node = try newNode(NodeKind.ND_DIV, node, try unary());
        } else return node;
    }
}

fn unary() !*Node {
    if (consume("+"))
        return try primary();

    if (consume("-"))
        return try newNode(NodeKind.ND_SUB, try newNodeNum(0), try primary());

    return try primary();
}

fn primary() anyerror!*Node {
    if (consume("(")) {
        const node = try expr();
        try expect(")");
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
        NodeKind.ND_EQ => {
            try stdout.writeAll("   cmp rax, rdi\n");
            try stdout.writeAll("   sete al\n");
            try stdout.writeAll("   movzb rax, al\n");
        },
        NodeKind.ND_NE => {
            try stdout.writeAll("   cmp rax, rdi\n");
            try stdout.writeAll("   setne al\n");
            try stdout.writeAll("   movzb rax, al\n");
        },
        NodeKind.ND_LT => {
            try stdout.writeAll("   cmp rax, rdi\n");
            try stdout.writeAll("   setl al\n");
            try stdout.writeAll("   movzb rax, al\n");
        },
        NodeKind.ND_LE => {
            try stdout.writeAll("   cmp rax, rdi\n");
            try stdout.writeAll("   setle al\n");
            try stdout.writeAll("   movzb rax, al\n");
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
    token = try tokenize(input);
    const node = try expr();
    try stdout.writeAll(".intel_syntax noprefix\n");
    try stdout.writeAll(".globl main\n");
    try stdout.writeAll("main:\n");
    try gen(node);
    try stdout.writeAll("   pop rax\n");
    try stdout.writeAll("   ret\n");

    return;
}

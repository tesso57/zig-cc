const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const testing = std.testing;
const mem = std.mem;
const SinglyLinkedList = std.SinglyLinkedList;
const Allocator = mem.Allocator;
const exit = std.os.exit;

const allocator = std.heap.page_allocator;

const util = @import("util.zig");
const isDigit = util.isDigit;
const isSpace = util.isSpace;
const isEqual = util.isEqual;

// Global Variables
var token: ?*Token = null;
var input: []const u8 = undefined;

const errorAt = util.errorAt;
const getInt = util.getInt;

const TokenKind = enum {
    TK_RESERVED, // 記号
    TK_NUM, // 整数トークン
    TK_EOF, // 入力の終わりを示すトークン
};

pub const Token = struct { kind: TokenKind, next: ?*Token, val: i32, char: []const u8, pos: usize };

pub const NodeKind = enum {
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

pub const Node = struct { kind: NodeKind, lhs: ?*Node, rhs: ?*Node, val: i32 };

pub fn parse(p: []const u8) !*Node {
    input = p;
    try tokenize(p);
    return try expr();
}

fn newToken(kind: TokenKind, cur: *Token, char: []const u8, pos: usize) !*Token {
    const tok = try allocator.create(Token);
    tok.kind = kind;
    tok.char = char;
    tok.pos = pos;
    cur.next = tok;
    return tok;
}

pub fn tokenize(p: []const u8) !void {
    var head: ?Token = Token{ .kind = TokenKind.TK_RESERVED, .next = null, .val = 0, .char = "", .pos = 0 };
    var cur = &(head.?);
    var i: usize = 0;
    while (p[i] != 0) : (i += 1) {
        if (isSpace(p[i]))
            continue;

        if (p[i] == '!' or p[i] == '=') {
            if (p[i + 1] == '=') {
                cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 2], i);
                i += 1;
                continue;
            }
        }

        if (p[i] == '>' or p[i] == '<') {
            if (p[i + 1] == '=') {
                cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 2], i);
                i += 1;
                continue;
            }
            cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 1], i);
            continue;
        }

        if (p[i] == '+' or p[i] == '-' or p[i] == '*' or p[i] == '/' or p[i] == '(' or p[i] == ')') {
            cur = try newToken(TokenKind.TK_RESERVED, cur, p[i .. i + 1], i);
            continue;
        }

        if (isDigit(p[i])) {
            cur = try newToken(TokenKind.TK_NUM, cur, p[i .. i + 1], i);
            cur.val = getInt(u8, p, &i);
            i -= 1;
            continue;
        }
        try errorAt(p, i, "トークナイズできない");
    }
    _ = try newToken(TokenKind.TK_EOF, cur, "", i);
    token = head.?.next.?;
}

fn consume(op: []const u8) bool {
    if (token.?.kind != TokenKind.TK_RESERVED or !isEqual(token.?.char, op)) {
        return false;
    }
    token = token.?.next;
    return true;
}

fn expect(op: []const u8) !void {
    if (token.?.kind != TokenKind.TK_RESERVED or !isEqual(token.?.char, op)) {
        try errorAt(input, token.?.pos, "expect error");
    }
    token = token.?.next;
}

fn expectNumber() !i32 {
    if (token.?.kind != TokenKind.TK_NUM) {
        try errorAt(input, token.?.pos, "数ではない");
    }

    const val = token.?.val;
    token = token.?.next;
    return val;
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

pub fn expr() !*Node {
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

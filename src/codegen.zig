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
const Node = parse.Node;
const NodeKind = parse.NodeKind;

var label: u32 = 0;

pub fn codegen(node: *Node) anyerror!void {
    var cur: ?*Node = node;
    try stdout.writeAll(".intel_syntax noprefix\n");
    try stdout.writeAll(".globl main\n");
    try stdout.writeAll("main:\n");

    // プロローグ
    // 変数26個分の領域を確保する
    try stdout.writeAll("   push rbp\n");
    try stdout.writeAll("   mov rbp, rsp\n");
    try stdout.writeAll("   sub rsp, 208\n");

    while (cur.?.kind != NodeKind.ND_EOF) : (cur = cur.?.next.?) {
        try gen(cur.?);
    }
    try stdout.writeAll("   pop rax\n");

    try stdout.writeAll("   mov rsp, rbp\n");
    try stdout.writeAll("   pop rbp\n");
    try stdout.writeAll("   ret\n");
}

fn genLval(node: *Node) !void {
    if (node.kind != NodeKind.ND_LVAR)
        try stderr.writeAll("代入の左辺値が変数ではありません");
    try stdout.writeAll("   mov rax, rbp\n");
    try stdout.writer().print("   sub rax, {d}\n", .{node.offset});
    try stdout.writeAll("   push rax\n");
}

fn gen(node: *Node) anyerror!void {
    switch (node.kind) {
        NodeKind.ND_NUM => {
            try stdout.writer().print("   push {d}\n", .{node.val});
            return;
        },
        NodeKind.ND_LVAR => {
            try genLval(node);
            try stdout.writeAll("   pop rax\n");
            try stdout.writeAll("   mov rax, [rax]\n");
            try stdout.writeAll("   push rax\n");
            return;
        },
        NodeKind.ND_ASSIGN => {
            try genLval(node.lhs.?);
            try gen(node.rhs.?);
            try stdout.writeAll("   pop rdi\n");
            try stdout.writeAll("   pop rax\n");
            try stdout.writeAll("   mov [rax], rdi\n");
            try stdout.writeAll("   push rdi\n");
            return;
        },
        NodeKind.ND_RETURN => {
            try gen(node.lhs.?);
            try stdout.writeAll("   pop rax\n");
            try stdout.writeAll("   mov rsp, rbp\n");
            try stdout.writeAll("   pop rbp\n");
            try stdout.writeAll("   ret\n");
            return;
        },
        NodeKind.ND_IF => {
            const now = label;
            label += 1;
            try gen(node.lhs.?);
            try stdout.writeAll("   pop rax\n");
            try stdout.writeAll("   cmp rax, 0\n");
            try stdout.writer().print("   je .Lend{d}\n", .{now});
            try gen(node.rhs.?);
            try stdout.writer().print(".Lend{d}:\n", .{now});
            return;
        },
        else => {},
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

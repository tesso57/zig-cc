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

pub fn codegen(node: *Node) anyerror!void {
    try stdout.writeAll(".intel_syntax noprefix\n");
    try stdout.writeAll(".globl main\n");
    try stdout.writeAll("main:\n");

    try gen(node);

    try stdout.writeAll("   pop rax\n");
    try stdout.writeAll("   ret\n");
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

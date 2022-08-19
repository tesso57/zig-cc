const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

const main = @import("./main.zig");
const Parser = main.Parser;
const ParserError = main.ParserError;

test "invalid character" {
    const test_allocator = std.testing.allocator;
    _ = Parser().init("1+1\n", test_allocator).parse() catch |err| {
        try expect(err == ParserError.InvalidCharacter);
    };
}

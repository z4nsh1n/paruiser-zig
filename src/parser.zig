const std = @import("std");
const lex = @import("lexer.zig");

const ParseError = error{
    UnknownToken,
};


fn panic(msg: []const u8, filename: []const u8, linenr: i32, function_name: []const u8) void {
    std.debug.print("{s}\n\t{s}:{d} -- {s}(...)\n", .{ msg, filename, linenr, function_name });
    std.debug.assert(false);
}

const Operator = enum {
    ADD,
    SUB,
    MUL,
    DIV,
};

const ast = union(enum) {
    // PROG: *ast
    // END: void,
    I32: i32,
    F32: f32,
    String: []const u8,
    Expr: struct { op: Operator, left: *const ast, right: *const ast },
    Stmts: []ast,
    END: void,
};

pub fn print(a: *const ast) void {
    switch (a.*) {
        .I32 => |v| {
            std.debug.print("I32({d}) ", .{v});
        },
        .F32 => |v| {
            std.debug.print("F32({d}) ", .{v});
        },
        .Expr => |v| {
            std.debug.print("({any} ", .{v.op});
            print(v.left);
            print(v.right);
            std.debug.print(")\n", .{});
        },
        .END => {
            std.debug.print("END", .{});
        },
        else => {},
    }
}

pub fn parse_num(alloc: std.mem.Allocator, tokens: []lex.LexerToken, token_idx: *usize) !*ast {
    const tok = tokens[token_idx.*];
    const a = try alloc.create(ast);
    switch (tok) {
        .float => |v| a.* = ast{ .F32 = v },
        .int => |v| a.* = ast{ .I32 = v },
        else => {
            const s = @src();
            panic("Not a numb", s.file, s.line, s.fn_name);
        },
    }
    token_idx.* += 1;
    return a;
}


pub fn parse_term(alloc: std.mem.Allocator, tokens: []lex.LexerToken, token_idx: *usize) !*ast {
    var left = try parse_expr(alloc, tokens, token_idx);
    var a = left;
    while (switch (tokens[token_idx.*]) {
        .eof => false,
        .add => true,
        .sub => true,
        else => false,
    } ) {
        left = opp: switch (tokens[token_idx.*]) {
            .add => {
                token_idx.* += 1;
                a = try alloc.create(ast);
                a.* = .{
                    .Expr = .{.op = .ADD, .left = left, .right = try parse_expr(alloc, tokens, token_idx)}
                };
                break :opp a;
            },
            .sub => {
                token_idx.* += 1;
                a = try alloc.create(ast);
                a.* = .{
                    .Expr = .{.op = .SUB, .left = left, .right = try parse_expr(alloc, tokens, token_idx)}
                };
                break :opp a;

        },
            else => {return ParseError.UnknownToken;},
        };
    }
    return left;
}
pub fn parse_expr(alloc: std.mem.Allocator, tokens: []lex.LexerToken, token_idx: *usize) !*ast {
    var left = try parse_num(alloc, tokens, token_idx);
    var a = left;
    while (switch (tokens[token_idx.*]) {
        .eof => false,
        .mul => true,
        .div => true,
        else => false,
    } ) {
        left = opp: switch (tokens[token_idx.*]) {
            .mul => {
                token_idx.* += 1;
                a = try alloc.create(ast);
                a.* = .{
                    .Expr = .{.op = .MUL, .left = left, .right = try parse_num(alloc, tokens, token_idx)}
                };
                break :opp a;
            },
            .div => {
                token_idx.* += 1;
                a = try alloc.create(ast);
                a.* = .{
                    .Expr = .{.op = .DIV, .left = left, .right = try parse_num(alloc, tokens, token_idx)}
                };
                break :opp a;

        },
            else => {return ParseError.UnknownToken;},
        };
    }
    return left;
}
pub fn run(alloc: std.mem.Allocator, lex_tokens: []lex.LexerToken) !*ast {
    var token_idx: usize = 0;
    var a: *ast = try alloc.create(ast);
    a.* = ast{.END = {}};
    while (switch (lex_tokens[token_idx]) {
        .eof => false,
        else => true,
    }) {
        std.debug.print("idx: {d}\n", .{token_idx});
        a = try parse_term(alloc, lex_tokens, &token_idx);
    }
    return a;
}

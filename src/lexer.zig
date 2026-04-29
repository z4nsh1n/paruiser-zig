const std = @import("std");

pub const LexerToken = union(enum) {
    float: f32,
    // string: []const u8,
    int: i32,
    // operator: []const u8,
    add: void,
    sub: void,
    mul: void,
    div: void,
    unknown: bool,
};

fn panic(msg: []const u8, filename: []const u8, linenr: i32, function_name: []const u8) void {
    std.debug.print("{s}\n\t{s}:{d} -- {s}(...)\n", .{ msg, filename, linenr, function_name });
    std.debug.assert(false);
}

pub fn print(tokens: []LexerToken) void {
    for (tokens) |t| {
        switch (t) {
            .add => {
                std.debug.print("ADD\n", .{});
            },
            .sub => {
                std.debug.print("SUB\n", .{});
            },
            .mul => {
                std.debug.print("MUL\n", .{});
            },
            .div => {
                std.debug.print("DIV\n", .{});
            },
            .int => |v| {
                std.debug.print("{d}\n", .{v});
            },
            .float => |v| {
                std.debug.print("{d}\n", .{v});
            },
            .unknown => {
                break;
            },
        }
    }
}
pub fn run(alloc: std.mem.Allocator, data: []const u8) ![]LexerToken {
    var index: usize = 0;
    var token_index: usize = 0;
    const tokens = try alloc.create([1024]LexerToken);
    for (tokens) |*t| {
        t.* = LexerToken{ .unknown = true };
    }

    while (index < data.len) : (index += 1) {
        if (std.ascii.isWhitespace(data[index])) continue;

        switch (data[index]) {
            '0'...'9' => {
                var i = index;
                while (i < data.len and std.ascii.isDigit(data[i])) : (i += 1) {}
                const n = try std.fmt.parseInt(i32, data[index..i], 10);
                if (i < data.len and data[i] == '.') {
                    i += 1;
                    while (i < data.len and std.ascii.isDigit(data[i])) : (i += 1) {}
                    const f = try std.fmt.parseFloat(f32, data[index..i]);
                    tokens[token_index] = LexerToken{ .float = f };
                } else {
                    tokens[token_index] = LexerToken{ .int = n };
                }
                index = i - 1;
                token_index += 1;
            },
            '+', '*', '-', '/' => |o| {
                switch (o) {
                    '+' => {
                        tokens[token_index] = LexerToken{ .add = {} };
                        token_index += 1;
                    },
                    '-' => {
                        tokens[token_index] = LexerToken{ .sub = {} };
                        token_index += 1;
                    },
                    '*' => {
                        tokens[token_index] = LexerToken{ .mul = {} };
                        token_index += 1;
                    },
                    '/' => {
                        tokens[token_index] = LexerToken{ .div = {} };
                        token_index += 1;
                    },
                    else => {
                        const s = @src();
                        panic("TODO: operator", s.file, s.line, s.fn_name);
                    },
                }
            },
            else => |t| {
                const s = @src();
                const msg = try std.fmt.allocPrint(alloc, "UNKNOWN TOKEN '{c}'\n", .{t});
                panic(msg, s.file, s.line, s.fn_name);
            },
        }
    }
    return tokens;
}

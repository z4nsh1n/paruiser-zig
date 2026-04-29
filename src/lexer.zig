const std = @import("std");

pub const LexerToken = union (enum) {
    float: f32,
    // string: []const u8,
    int: i32,
    operator: []const u8,
    unknown: bool,
};

pub fn print(tokens:[]LexerToken) void {
    for (tokens) |t| {
            switch (t) {
                .int => |v|{
                    std.debug.print("{d}\n", .{v});
                },
                .float => {},
                .operator => {},
                .unknown => {break;}
            }
        }
}
pub fn run(alloc: std.mem.Allocator, data: []const u8) ![]LexerToken {
    var index:usize = 0;
    var token_index:usize = 0;
    const tokens = try alloc.create([1024]LexerToken);
    for (tokens) |*t| {
        t.* = LexerToken{.unknown = true};
    }

    while (index < data.len) : (index+=1) {
        switch (data[index]) {
            '0'...'9' =>  {
                var i = index;
                while (i < data.len and std.ascii.isDigit(data[i])) : (i+=1) {}
                const n = try std.fmt.parseInt(i32, data[index..i], 10);
                tokens[token_index] = LexerToken{.int = n};
                index = i;
                token_index += 1;
            },
            else => {}
        }

    }
    return tokens;
    // const s = @src();
    // std.debug.panic("TODO: {s}:{d} -- {s}()\ndata: {any}",
    //    . {
    //     s.file,
    //     s.line,
    //     s.fn_name,
    //     data});
}

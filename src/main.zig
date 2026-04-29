const std = @import("std");
const Io = std.Io;

const ep = @import("expr_parser.zig");
const lex = @import("lexer.zig");

pub fn main(init: std.process.Init) !void {
    var write_buffer: [1024]u8 = undefined;
    var read_buffer: [1024]u8 = undefined;

    var stdout_writer: std.Io.File.Writer = .init(.stdout(), init.io, &write_buffer);
    
    var wiface = &stdout_writer.interface;

    var stdin_reader: std.Io.File.Reader = .init( .stdin(), init.io, &read_buffer);

    var riface = &stdin_reader.interface;

    repl: while (true) {
        var buffer:[512]u8 = undefined;
        var bwriter = std.Io.Writer.fixed(&buffer);
        try wiface.print("> ", .{});
        try wiface.flush();
        const l  = try riface.streamDelimiter(&bwriter, '\n');
        // _ = try riface.discardRemaining();
        _ = try riface.discardShort(1);

        // try wiface.print("{s}\n", .{buffer[0..l]});
        // try wiface.flush();
        if (std.mem.eql(u8, "/quit", buffer[0..l])){
            break :repl;
        }

        
        const tokens  = try lex.run(init.arena.allocator(), buffer[0..l]);
        lex.print(tokens);
    }
    //
    // const ast = ep.parse(tokens);
    // _ = ast;
    // _ = init;
}

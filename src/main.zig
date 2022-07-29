const std = @import("std");

const io_parser = @import("./io_parser.zig");
const ParseError = io_parser.ParseError;
const JsonPayload = io_parser.JsonPayload;

pub fn main() !void {
    const stderr = std.io.getStdErr().writer();
    const stdin = std.io.getStdIn().reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var allocator = arena.allocator();
    defer _ = arena.deinit();

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();

    // Server Loop
    while (true) {
        // Try to read from standard input
        stdin.readUntilDelimiterArrayList(&buffer, 0, 4.294967e9) catch |err| // TODO: Is there a way to not limit the max length?
            if (err != error.EndOfStream) return err; // Ignore EndOfStream errors, only propagate the rest.

        // If we did read from stdin, but the amount of bytes read was 0 then don't parse the data 
        if (buffer.items.len == 0) continue;

        var maybe_payload: ?JsonPayload = io_parser.parse(buffer.items, &parser) catch |err| switch (err) {
            ParseError.NoContentLength => blk: {
                try stderr.writeAll("Malformed payload: no `Content-Length` header found!");
                break :blk null;
            },
            ParseError.MalformedJSON => blk: { 
                try stderr.writeAll("Malformed payload: invalid JSON string!");
                break :blk null;
            },
            else => return err,
        };

        if (maybe_payload) |_| {
            // check the type of payload received
        }
    }
}

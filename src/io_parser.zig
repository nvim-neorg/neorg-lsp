const std = @import("std");

pub const ParseError = error{
    NoContentLength,
    EncodingIsNotUtf8,
    NoJSON,
    MalformedJSON,

    InvalidParameterType,
    InvalidIDType,
};

pub const JsonPayload = struct {
    ContentLength: usize,
    ContentType: []const u8 = "application/vscode-jsonrpc; charset=utf-8",
    Json: std.json.ValueTree,
};

pub fn parse(allocator: std.mem.Allocator, stdin: std.fs.File.Reader, parser: *std.json.Parser) !?JsonPayload {
    var payload: JsonPayload = .{
        .ContentLength = undefined,
        .Json = undefined,
    };

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var has_content_length = false;
    var has_json = false;

    while (!has_content_length or !has_json) {
        stdin.readUntilDelimiterArrayList(&buffer, '\n', comptime std.math.maxInt(usize)) catch |err|
            if (err != error.EndOfStream) return err;

        const content = buffer.items;

        // An empty line is just `\r`, which has a length of one.
        if (content.len <= 1) continue;

        _ = try file.write(content);

        if (std.mem.startsWith(u8, content, "Content-Length: ")) {
            payload.ContentLength = try std.fmt.parseInt(usize, content["Content-Length: ".len .. content.len - 1], 10);
            has_content_length = true;
        }
        else if (std.mem.startsWith(u8, content, "Content-Type: ")) payload.ContentType = content["Content-Type: ".len .. content.len - 1]
        else { // Imagine trusting the Content-Length lol let's just ignore it here
            has_json = true;
            payload.Json = parser.parse(content) catch return ParseError.MalformedJSON;
        }
    }

    if (!has_content_length) return ParseError.NoContentLength;
    if (!has_json) return ParseError.NoJSON;

    return payload;
}

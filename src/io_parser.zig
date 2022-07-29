const std = @import("std");

pub const ParseError = error{
    NoContentLength,
    EncodingIsNotUtf8,
    MalformedJSON,
};

pub const ParseResult = union(enum) {
    Empty,
    ContentLength: usize,
    ContentType: []const u8,
    Json: std.json.ValueTree,
};

pub const JsonPayload = struct {
    ContentLength: usize,
    ContentType: []const u8 = "application/vscode-jsonrpc; charset=utf-8",
    Json: std.json.ValueTree,
};

pub fn parse(content: []const u8, parser: *std.json.Parser) !JsonPayload {
    var payload: JsonPayload = .{
        .ContentLength = undefined,
        .Json = undefined,
    };

    var has_content_length: bool = false;
    var it = std.mem.split(u8, content, "\r\n");

    while (it.next()) |line| {
        if (line.len <= 1) continue;

        if (std.mem.startsWith(u8, line, "Content-Length: ")) {
            payload.ContentLength = try std.fmt.parseInt(u8, line["Content-Length: ".len..], 10);
            has_content_length = true;
        }
        // TODO: Perform parsing on the content type?
        else if (std.mem.startsWith(u8, line, "Content-Type: ")) payload.ContentType = line["Content-Type: ".len..]
        else payload.Json = parser.parse(line) catch return ParseError.MalformedJSON;
    }

    if (!has_content_length) return ParseError.NoContentLength;

    return payload;
}

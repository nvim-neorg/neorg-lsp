const std = @import("std");

const io_parser = @import("./io_parser.zig");
const ParseError = io_parser.ParseError;
const JsonPayload = io_parser.JsonPayload;

const utils = @import("./utils.zig");

// TODO: Move all of this stuff to a new file

const MessageType = union(enum) {
    Request: struct {
        id: i64,
        method: []const u8,
        params: ?utils.JsonArrayOrObject,
    },
    Response: u64,
    Notification: void,
};

fn parse_payload(payload: JsonPayload) ParseError!?void {
    const anymethod = payload.Json.root.Object.get("method") orelse return null;

    switch (anymethod) {
        .String => |method| {
            if (payload.Json.root.Object.get("id")) |anyid| { // We are dealing with a request
                var id: i64 = switch (anyid) {
                    .Integer => |int| int,
                    .String => |string| std.fmt.parseInt(i64, string, 10) catch return ParseError.MalformedJSON,
                    else => return ParseError.InvalidIDType,
                };

                const req: MessageType = .{ .Request = .{
                    .id = id,
                    .method = method,
                    .params = if (payload.Json.root.Object.get("params")) |params| switch (params) {
                        .Array => |array| utils.JsonArrayOrObject{
                            .Array = array,
                        },
                        .Object => |object| utils.JsonArrayOrObject{ .Object = object },
                        .Null => null,
                        else => return ParseError.InvalidParameterType,
                    } else null,
                } };

                parse_request(req);
            }
        },
        else => unreachable,
    }
}

fn parse_request(request: MessageType) void {
    if (request != MessageType.Request) unreachable;

    // TODO
}

// End of TODO

pub fn main() !void {
    const stderr = std.io.getStdErr().writer();
    const stdin = std.io.getStdIn().reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var allocator = arena.allocator();
    defer _ = arena.deinit();

    var parser = std.json.Parser.init(allocator, true);
    defer parser.deinit();

    // Server Loop
    while (true) {
        var maybe_payload: ?JsonPayload = io_parser.parse(allocator, stdin, &parser) catch |err| switch (err) {
            ParseError.NoContentLength => blk: {
                try stderr.writeAll("Malformed payload: no `Content-Length` header found!");
                break :blk null;
            },
            ParseError.NoJSON => blk: {
                try stderr.writeAll("Malformed payload: no JSON content present!");
                break :blk null;
            },
            ParseError.MalformedJSON => blk: {
                try stderr.writeAll("Malformed payload: invalid JSON string!");
                break :blk null;
            },
            else => return err,
        };

        if (maybe_payload) |payload| {
            // check the type of payload received
            _ = try parse_payload(payload);
        }
    }
}

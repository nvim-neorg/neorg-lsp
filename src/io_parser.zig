const std = @import("std");

const TokenType = enum {
    HeaderName,
    HeaderDelimiter,
    HeaderContent,

    CarriageReturn,
    LineFeed,

    Content,
};

const Token = struct {
    type: TokenType,
    content: std.ArrayList(u8),

    pub fn deinit(self: *Token) void {
        self.content.deinit();
    }
};

fn tokenizeInput(allocator: std.mem.Allocator, token_buffer: *std.ArrayList(Token), input: std.fs.File.Reader) !bool {
    token_buffer.shrinkAndFree(0);

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var current_token_type = TokenType.HeaderName;
    var parse_content = false;

    while (true) {
        var next = input.readByte() catch break;

        if (parse_content) {
            try buffer.append(next);
            continue;
        }

        switch (next) {
            ':' => { // HACK: Zig doesn't have captures/closures, so we have to copy paste the code for now
                try token_buffer.append(Token{
                    .type = current_token_type,
                    .content = try buffer.clone(),
                });

                current_token_type = TokenType.HeaderDelimiter;

                buffer.shrinkAndFree(0);
                try buffer.append(next);
            },
            '\r' => {
                try token_buffer.append(Token{
                    .type = current_token_type,
                    .content = try buffer.clone(),
                });

                current_token_type = TokenType.CarriageReturn;

                buffer.shrinkAndFree(0);
                try buffer.append(next);
            },
            '\n' => {
                try token_buffer.append(Token{
                    .type = current_token_type,
                    .content = try buffer.clone(),
                });

                current_token_type = TokenType.LineFeed;

                buffer.shrinkAndFree(0);
                try buffer.append(next);
            },
            '{' => parse_content = true,
            else => switch (current_token_type) {
                .HeaderDelimiter => {
                    try token_buffer.append(Token{
                        .type = current_token_type,
                        .content = try buffer.clone(),
                    });

                    current_token_type = TokenType.HeaderContent;

                    buffer.shrinkAndFree(0);
                    try buffer.append(next);
                },
                .LineFeed => {
                    try token_buffer.append(Token{
                        .type = current_token_type,
                        .content = try buffer.clone(),
                    });

                    current_token_type = TokenType.HeaderName;

                    buffer.shrinkAndFree(0);
                    try buffer.append(next);
                },
                else => try buffer.append(next),
            },
        }
    }

    if (buffer.items.len > 0) {
        try token_buffer.append(Token{
            .type = TokenType.Content,
            .content = try buffer.clone(),
        });
    }

    return token_buffer.items.len > 0;
}

pub fn parse(allocator: std.mem.Allocator, stdin: std.fs.File.Reader, _: *std.json.Parser) !void {
    var buffer = std.ArrayList(Token).init(allocator);
    defer {
        for (buffer.items) |*token| token.deinit();
        buffer.deinit();
    }

    while (true) {
        for (buffer.items) |*token| token.deinit();

        if (!try tokenizeInput(allocator, &buffer, stdin)) continue;

        // TODO: Perform error checking on the tokenized input
        for (buffer.items) |token| {
            std.debug.print("{any} :: ", .{token.type});
        }
    }
}

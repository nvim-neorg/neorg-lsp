# \[WIP\] Neorg LSP Server

This repository hosts the official LSP implementation for the Neorg file format.

## Features

Currently? None 😂.

First I must implement a working request/response handler, and also a basic Neorg parser in zig.

## FAQ

### Why not treesitter for the parser?

Mostly implementation convenience. To my knowledge there are no _solid_ TS bindings for zig, apart from the usual
C bindings (which we could make wrappers on top of).

I just want an LSP server up and running, we can work on futureproofing after the first working prototype is released.
Besides, we don't need all the precision of the treesitter parser - we only need to parse a select few constructs within
Neorg in order to provide solid completions and code actions.

After a prototype is created, we might want to start work on good bindings for Zig and start work on integrating the LSP
with the TS parser.

### Why Zig?

You're probably screaming that it's not Rust right now :p, but I personally prefer Zig due to less developer friction.
I can whip up programs in no time, and I really enjoy many of the syntactical constructs that Zig provides.

Besides, [zls](https://github.com/zigtools/zls) has proven that LSPs written in Zig can be _fast_, like _**really** fast_.
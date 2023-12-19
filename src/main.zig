const std = @import("std");
const config = @import("comps/config.zig");
const argsParser = @import("libs/argsParser.zig");
const client = @import("comps/client.zig");
const server = @import("comps/server.zig");

pub fn main() u8 {
    run() catch |err| {
        std.debug.print("{any}\n", .{err});
        return 1;
    };
    return 0;
}

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const ally = gpa.allocator();

    const args = try config.parseArgs(ally);
    defer args.deinit();

    var opt = args.options;
    if (opt.help) {
        config.help() catch {};
    } else {
        if (args.count < 1) {
            opt.mode = .show;
        }
        try switch (opt.mode) {
            .s, .server => server.run(&opt),
            else => client.run(opt),
        };
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

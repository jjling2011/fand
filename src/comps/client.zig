const std = @import("std");
const config = @import("config.zig");
const utils = @import("utils.zig");

const empty_cmd = utils.Command{};

fn sendCmd(s: std.net.Stream, cmd: utils.Command) !void {
    try utils.writeJson(s, cmd);
    var buf: [config.BUFF_SIZE]u8 = undefined;
    const msg = try utils.readMsg(s, &buf);
    std.debug.print("{s}\n", .{msg});
}

fn monitor(s: std.net.Stream, interval: u16) !void {
    var delay: u64 = interval;
    delay *= std.time.ns_per_s;
    while (true) {
        try sendCmd(s, empty_cmd);
        std.time.sleep(delay);
    }
}

pub fn run(options: config.Options) !void {
    var stream = try std.net.connectUnixSocket(options.uds);
    defer stream.close();

    (switch (options.mode) {
        .show => sendCmd(stream, empty_cmd),
        .m, .monitor => monitor(stream, options.interval),
        else => sendCmd(stream, utils.Command.init(options)),
    }) catch |err| switch (err) {
        std.os.ReadError.BrokenPipe => return,
        else => return err,
    };
}

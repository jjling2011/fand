pub const app_name = "fand";
pub const version = "1.0.0";
pub const BUFF_SIZE = 4 * 1024;
pub const HIGH = 65;
pub const LOW = 50;
pub const PIN = 22;
pub const GPIO_CHIP_NO = "0";
pub const THERMAL_FILE = "/sys/class/thermal/thermal_zone0/temp";

const std = @import("std");
const argsParser = @import("../libs/argsParser.zig");

pub inline fn getAppName() []const u8 {
    const name = app_name ++ " v" ++ version;
    return name[0..name.len];
}

pub fn help() !void {
    try argsParser.printHelp(Options, getAppName(), std.io.getStdOut().writer());
}

pub fn parseArgs(
    allocator: std.mem.Allocator,
) !argsParser.ParseArgsResult(Options, null) {
    return try argsParser.parseForCurrentProcess(Options, allocator, .print);
}

pub const Options = struct {
    uds: []const u8 = "/tmp/fand.sock",
    gpio: u8 = PIN,
    high: ?u8 = null,
    low: ?u8 = null,
    mode: enum { server, client, monitor, s, c, m, show } = .client,
    fan: ?enum { on, off } = null,
    interval: u16 = 5,
    help: bool = false,

    pub fn normalize(self: *Options) void {
        if (self.high == null) self.high = HIGH;
        if (self.low == null) self.low = LOW;
        if (self.fan == null) self.fan = .off;
    }

    // This declares short-hand options for single hyphen
    pub const shorthands = .{
        .u = "uds",
        .g = "gpio",
        .h = "help",
        .m = "mode",
        .i = "interval",
    };

    pub const meta = .{ .option_docs = .{
        .uds = "unix domain socket path. e.g. /tmp/fand.sock",
        .gpio = "(server only) GPIO pin number",
        .high = "turn fan on at {high} temperature",
        .low = "turn fan off at {low} temperature",
        .mode = "mode={(s)erver, (c)lient, (m)onitor, show}",
        .fan = "fan={on, off}",
        .interval = "detect cpu temperature interval in seconds",
        .help = "show this help information",
    } };
};

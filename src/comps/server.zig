const std = @import("std");
const config = @import("config.zig");
const utils = @import("utils.zig");
const dateTime = @import("../libs/datetime.zig");
const timezones = @import("../libs/timezones.zig");

const gpiod = @cImport({
    @cInclude("gpiod.h");
});

var is_closing = false;

pub fn run(options: *config.Options) !void {
    const name = config.getAppName();
    const uid = std.os.linux.geteuid();
    if (uid != 0) {
        std.debug.print("{s} server mode require root priviledge!\n", .{name});
    } else {
        options.normalize();
        const thread = try std.Thread.spawn(.{}, daemon, .{options});
        try startServer(options);
        is_closing = true;
        thread.join();
    }
    std.debug.print("{s} server stopped.\n", .{name});
}

fn daemon(options: *config.Options) void {
    const pin = options.gpio;
    var temp: u32 = 0;
    while (true) {
        temp = getCurTemp() catch 0;
        if (temp > options.high.? or req_pin_on) {
            req_pin_on = false;
            // this function will wait until holdPinOn returns
            _ = gpiod.gpiod_ctxless_set_value(config.GPIO_CHIP_NO, pin, -1, false, null, holdPinOn, @ptrCast(options));
        } else {
            sleep(options.interval);
        }
        req_pin_off = false;
    }
}

fn sleep(interval: u32) void {
    var now = std.time.timestamp();
    const due = now + interval;
    while (now < due and !req_pin_on and !req_pin_off) {
        now = std.time.timestamp();
        std.time.sleep(std.time.ns_per_s * 2);
    }
}

fn holdPinOn(np: ?*anyopaque) callconv(.C) void {
    const p = np orelse return;
    var options: *config.Options = @ptrCast(@alignCast(p));
    var temp: u32 = options.high.?;
    while (!req_pin_off and temp > options.low.?) {
        temp = getCurTemp() catch 0;
        sleep(options.interval);
    }
}

fn listen(server: *std.net.StreamServer, uds: []const u8) !void {
    const addr = try std.net.Address.initUnix(uds);

    std.os.unlink(uds) catch {};
    std.debug.print("listening: {s}\n", .{uds});
    try server.listen(addr);

    var buf = [_]u8{0} ** 108;
    _ = try std.fmt.bufPrint(&buf, "{s}", .{uds});
    _ = std.os.linux.chmod(buf[0..uds.len :0].ptr, 0o666);
}

fn startServer(options: *config.Options) !void {
    var server = std.net.StreamServer.init(.{});
    defer server.deinit();
    try listen(&server, options.uds);
    while (server.accept()) |conn| {
        _ = try std.Thread.spawn(.{}, handleConnWrapper, .{ conn.stream, options });
    } else |err| return err;
}

fn handleConnWrapper(stream: std.net.Stream, options: *config.Options) void {
    defer std.net.Stream.close(stream);
    var buf: [config.BUFF_SIZE]u8 = undefined;
    handle(stream, &buf, options) catch |err| {
        std.debug.print("handle conn error: {any}\n", .{err});
    };
}

fn handle(stream: std.net.Stream, buf: []u8, options: *config.Options) !void {
    while (utils.readJson(stream, buf)) |cmd| {
        const msg = try exec(cmd, options, buf);
        try utils.writeMsg(stream, msg);
    } else |err| switch (err) {
        std.os.ReadError.BrokenPipe => return,
        else => return err,
    }
}

fn getCurTemp() !u32 {
    const file = try std.fs.openFileAbsolute(config.THERMAL_FILE, .{});
    defer file.close();

    var buf: [20]u8 = undefined;
    const len = try file.readAll(&buf);

    var sum: u32 = 0;
    for (buf[0..len]) |c| {
        switch (c) {
            '0'...'9' => sum = sum * 10 + c - '0',
            else => break,
        }
    }
    return sum / 1000;
}

var req_pin_on = false;
var req_pin_off = false;

fn exec(cmd: utils.Command, options: *config.Options, buf: []u8) ![]u8 {
    const opt = options;
    const pin = opt.gpio;
    if (cmd.on) |on| {
        req_pin_on = on;
        req_pin_off = !on;
        std.time.sleep(std.time.ns_per_s * 3);
    }
    if (cmd.high) |high| {
        opt.high = high;
    }
    if (cmd.low) |low| {
        opt.low = low;
    }
    if (opt.high.? < opt.low.?) {
        const t = opt.low.?;
        opt.low = opt.high.?;
        opt.high = t;
    }

    var date_buf: [100]u8 = undefined;
    const temp = getCurTemp() catch 0;
    const dt_str = dateTime.Datetime.now().shiftTimezone(&timezones.Asia.Shanghai).formatISO8601Buf(&date_buf, false) catch "[date error]";
    const fan = if (readPin(pin) or req_pin_on) "ON" else "OFF";
    return try std.fmt.bufPrint(buf, "{s} Temp({any}-{any}): {d} Pin({any}): {s}", .{ dt_str, opt.low, opt.high, temp, opt.gpio, fan });
}

fn readPin(num: u8) bool {
    const v = gpiod.gpiod_ctxless_get_value("0", num, false, null);
    // off: 0, on: -1
    return v != 0;
}

fn listAllChips() !void {
    const iter = gpiod.gpiod_chip_iter_new();
    if (iter == null) {
        std.debug.print("iter is null", .{});
        return;
    }
    defer gpiod.gpiod_chip_iter_free(iter);
    while (gpiod.gpiod_chip_iter_next(iter)) |chip| {
        std.debug.print("chip: {s} [{s}] ({d} lines)\n", .{
            gpiod.gpiod_chip_name(chip),
            gpiod.gpiod_chip_label(chip),
            gpiod.gpiod_chip_num_lines(chip),
        });
    }
    std.debug.print("done\n", .{});
}

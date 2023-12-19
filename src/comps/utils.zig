const std = @import("std");
const config = @import("config.zig");

pub const Command = struct {
    high: ?u8 = null,
    low: ?u8 = null,
    on: ?bool = null,

    pub fn init(options: config.Options) Command {
        return Command{
            .high = options.high,
            .low = options.low,
            .on = if (options.fan) |state| state == .on else null,
        };
    }

    pub fn copy(src: *const Command) Command {
        return Command{
            .high = src.high,
            .low = src.low,
            .on = src.on,
        };
    }
};

pub fn readMsg(stream: std.net.Stream, buf: []u8) ![]u8 {
    const len = try readLength(stream);
    if (len < 1) {
        return std.os.ReadError.BrokenPipe;
    }

    const n = try stream.readAtLeast(buf, len);
    if (n != len) {
        return std.os.ReadError.BrokenPipe;
    }
    return buf[0..n];
}

pub fn readJson(stream: std.net.Stream, buf: []u8) !Command {
    const len = try readLength(stream);
    if (len < 1) {
        return std.os.ReadError.BrokenPipe;
    }

    const n = try stream.readAtLeast(buf, len);
    if (n != len) {
        return std.os.ReadError.BrokenPipe;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ally = gpa.allocator();
    const tcmd = try std.json.parseFromSlice(Command, ally, buf[0..len], .{});
    defer tcmd.deinit();
    return Command.copy(&tcmd.value);
}

pub fn writeMsg(stream: std.net.Stream, buf: []u8) !void {
    try writeLength(stream, buf.len);
    try stream.writeAll(buf);
}

pub fn writeJson(stream: std.net.Stream, cmd: Command) !void {
    var buf: [config.BUFF_SIZE]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(cmd, .{}, string.writer());

    const len = string.items.len;
    // std.debug.print("cmd: {s}\n", .{buf[0..len]});
    try writeLength(stream, len);
    try stream.writeAll(buf[0..len]);
}

pub fn readLength(stream: std.net.Stream) !usize {
    var buf = [2]u8{ 0, 0 };
    const n = try stream.readAll(&buf);
    if (n < 2) return 0;
    var s: usize = buf[1];
    s *= 256;
    s += buf[0];
    return s;
}

pub fn writeLength(stream: std.net.Stream, n: usize) !void {
    var buf = [2]u8{ @intCast(@mod(n, 256)), @intCast(n / 256) };
    try stream.writeAll(&buf);
}

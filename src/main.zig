const std = @import("std");

// Force enable all logs even in ReleaseFast
pub const std_options: @import("std").Options = .{ .log_level = std.log.Level.debug };

// Config
const measures = 4 * 1024; // Number of measurements to do
const iterations = 16 * 1024; // Number of iteration per measure

const Format = enum {
    fixed,
    prefix,
    sqlite4,
    uleb128,
    vint64,
    vu128,
};

fn Impl(TargetType: type, comptime format: Format) type {
    switch (format) {
        .fixed => return @import("fixed.zig").fixed(TargetType),
        .prefix => return @import("prefix.zig").prefix(u8, TargetType),
        .sqlite4 => return @import("sqlite4.zig").sqlite4(TargetType),
        .uleb128 => return @import("uleb128.zig").uleb128(TargetType),
        .vint64 => return @import("vint64.zig").vint64(TargetType),
        .vu128 => return @import("vu128.zig").vu128(TargetType),
    }
}

fn implDesc(format: Format) []const u8 {
    return switch (format) {
        .fixed => "Fixed: fixed size read/write",
        .prefix => "Prefix: u8 prefix announcing size",
        .sqlite4 => "[SQLite4](https://sqlite.org/src4/doc/trunk/www/varint.wiki)",
        .uleb128 => "[ULEB128](https://en.wikipedia.org/wiki/LEB128)",
        .vint64 => "[vint64](https://github.com/iqlusioninc/veriform/tree/develop/rust/vint64/)",
        .vu128 => "[vu128](https://john-millikin.com/vu128-efficient-variable-length-integers)",
    };
}

const Stats = struct {
    min: f64,
    max: f64,
    median: f64,
    avg: f64,
    stddev: f64,
};

fn computeStats(inputs: []f64) Stats {
    var result: Stats = undefined;

    std.mem.sort(f64, inputs, {}, std.sort.asc(f64));
    result.min = inputs[0];
    result.max = inputs[inputs.len - 1];
    result.median = inputs[@intFromFloat(@as(f64, @floatFromInt(inputs.len)) * 0.50)];

    var accu: f64 = 0;
    for (0..inputs.len) |index| {
        accu += inputs[index];
    }
    result.avg = accu / @as(f64, @floatFromInt(inputs.len));
    accu = 0;
    for (0..inputs.len) |index| {
        const finput = inputs[index];
        const dev = finput - result.avg;
        accu += dev * dev;
    }
    result.stddev = std.math.sqrt(accu / @as(f64, @floatFromInt(inputs.len)));

    return result;
}

fn bench(T: type, comptime format: Format, ouput_dir: std.fs.Dir, readme: std.io.AnyWriter) !void {
    var timer = try std.time.Timer.start();
    var buffer = std.mem.zeroes([64]u8);
    var plot = try ouput_dir.createFile(try std.fmt.bufPrint(&buffer, "{s}.txt", .{@tagName(format)}), .{});
    defer plot.close();

    // Column headers
    try plot.writer().print("{s: >8}\t{s: >8}\t{s: >8}", .{
        "val", "bit", "bytes",
    });
    try plot.writer().print("\t{s: >8}\t{s: >8}\t{s: >8}\t{s: >8}\t{s: >8}", .{
        "enc_min", "enc_med", "enc_avg", "enc_sdev", "enc_max",
    });
    try plot.writer().print("\t{s: >8}\t{s: >8}\t{s: >8}\t{s: >8}\t{s: >8}\n", .{
        "dec_min", "dec_med", "dec_avg", "dec_sdev", "dec_max",
    });

    var total_byte_size: u64 = 0;
    var total_enc_time: f64 = 0;
    var total_dec_time: f64 = 0;
    for (0..65) |bit| {
        const PowType = std.meta.Int(.unsigned, @bitSizeOf(T) + 1);
        const val: T = @intCast(std.math.pow(PowType, 2, bit) - 1);
        var enc_times: [measures]f64 = undefined;
        var dec_times: [measures]f64 = undefined;

        buffer = std.mem.zeroes([64]u8);
        for (0..2) |warmup| {
            for (0..measures) |measure| {
                {
                    timer.reset();
                    for (0..iterations) |_| {
                        const res = Impl(T, format).encode(&buffer, val);
                        std.mem.doNotOptimizeAway(res);
                    }
                    enc_times[measure] = @as(f64, @floatFromInt(timer.read())) / iterations;
                }
                {
                    timer.reset();
                    for (0..iterations) |_| {
                        const res = Impl(T, format).decode(&buffer);
                        std.mem.doNotOptimizeAway(res);
                    }
                    dec_times[measure] = @as(f64, @floatFromInt(timer.read())) / iterations;
                }
                if (warmup == 0 and measure > (measures / 100)) {
                    break;
                }
            }
        }

        const byte_size: usize = Impl(T, format).encode(&buffer, val);
        const encoded = buffer[0..byte_size];
        const enc_stats = computeStats(&enc_times);
        const dec_stats = computeStats(&dec_times);
        std.log.info("{s} 2^{}-1: {}B, {d:.3}ns/enc, {d:.3}ns/dec, {x:0>2}", .{ @tagName(format), bit, byte_size, enc_stats.avg, dec_stats.avg, encoded });

        total_byte_size += byte_size;
        total_enc_time += enc_stats.avg;
        total_dec_time += dec_stats.avg;

        const val_str = try std.fmt.bufPrint(&buffer, "2^{}-1", .{bit});
        try plot.writer().print("{s: >8}\t{: >8}\t{: >8}", .{
            val_str, bit, byte_size,
        });
        try plot.writer().print("\t{d: >8.4}\t{d: >8.4}\t{d: >8.4}\t{d: >8.4}\t{d: >8.4}", .{
            enc_stats.min, enc_stats.median, enc_stats.avg, enc_stats.stddev, enc_stats.max,
        });
        try plot.writer().print("\t{d: >8.4}\t{d: >8.4}\t{d: >8.4}\t{d: >8.4}\t{d: >8.4}\n", .{
            dec_stats.min, dec_stats.median, dec_stats.avg, dec_stats.stddev, dec_stats.max,
        });
    }

    std.log.info("{s} summary {d:.3}B, {d:.3}ns/enc, {d:.3}ns/dec", .{ @tagName(format), @as(f64, @floatFromInt(total_byte_size)) / 65, total_enc_time / 65, total_dec_time / 65 });
    try readme.print("| {s: <80}|{d: >12.4} |{d: >12.4} |{d: >12.4} |\n", .{ implDesc(format), @as(f64, @floatFromInt(total_byte_size)) / 65, total_enc_time / 65, total_dec_time / 65 });
}

pub fn main() !void {
    var results_dir = try std.fs.cwd().makeOpenPath("results", .{});
    var readme = try results_dir.createFile("summary.txt", .{});
    defer readme.close();

    try readme.writer().writeAll("| Format                                                                          |     Size(B) |  Encode(ns) |  Decode(ns) |\n");
    try readme.writer().writeAll("| ------------------------------------------------------------------------------- | ----------- | ----------- | ----------- |\n");

    const unsigneds = std.meta.fields(Format);
    inline for (unsigneds) |unsigned| {
        try bench(u64, @enumFromInt(unsigned.value), results_dir, readme.writer().any());
    }
}

test {
    _ = @import("fixed.zig");
    _ = @import("prefix.zig");
    _ = @import("sqlite4.zig");
    _ = @import("uleb128.zig");
    _ = @import("vint64.zig");
    _ = @import("vu128.zig");
}

// Based on https://github.com/iqlusioninc/veriform/tree/develop/rust/vint64/

const std = @import("std");
const common = @import("common.zig");

pub fn VInt64(comptime T: type) type {
    if (@typeInfo(T) != .Int) {
        @compileError("Using vint64 on non-int type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.signedness != .unsigned) {
        @compileError("Using vint64 on non-unsigned type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits > 64) {
        @compileError("Using vint64 on type too big: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits <= 8) {
        @compileError("Using vint64 on type too small: " ++ @typeName(T));
    }
    return struct {
        pub fn encode(buff: [*]u8, raw: T) usize {
            const bitsize = @bitSizeOf(T);
            const threshold = bitsize - 8;
            const bits = bitsize - @clz(raw | 1);
            if (bits > threshold) {
                buff[0] = 0;
                common.writePtr(T, buff + 1, std.mem.nativeToLittle(T, raw));
                return 9;
            } else {
                const LengthType = std.meta.Int(.unsigned, std.math.log2(@bitSizeOf(T)) - 1);
                const length: LengthType = @intCast(1 + (bits - 1) / 7);
                const encoded = (raw << 1 | 1) << (length - 1);
                common.writePtr(T, buff, std.mem.nativeToLittle(T, encoded));
                return length;
            }
        }

        pub fn decode(buff: [*]const u8) struct { val: T, len: usize } {
            const prefix_byte = buff[0];
            if (prefix_byte == 0) {
                return .{
                    .val = std.mem.littleToNative(T, common.readPtr(T, buff + 1)),
                    .len = 9,
                };
            } else {
                const trailing_zeroes = @ctz(prefix_byte);
                const length = trailing_zeroes + 1;
                var result: T = undefined;
                const read_ptr = true;
                if (read_ptr) {
                    result = std.mem.littleToNative(T, common.readPtrMasked(T, length, buff));
                } else {
                    result = std.mem.littleToNative(T, common.read(T, length, buff));
                }
                result >>= length;
                return .{
                    .val = result,
                    .len = length,
                };
            }
        }
    };
}

test "conformant" {
    // These are some of the tests in https://github.com/iqlusioninc/veriform/blob/develop/rust/vint64/src/lib.rs
    try common.testRoundtrip(u64, VInt64(u64), 0, "\x01");
    try common.testRoundtrip(u64, VInt64(u64), 0x0f0f, "\x3e\x3c");
    try common.testRoundtrip(u64, VInt64(u64), 0x0f0f_f0f0, "\x08\x0f\xff\xf0");
    try common.testRoundtrip(u64, VInt64(u64), 0x0f0f_f0f0_0f0f, "\xc0\x87\x07\x78\xf8\x87\x07");
    try common.testRoundtrip(u64, VInt64(u64), 0x0f0f_f0f0_0f0f_f0f0, "\x00\xf0\xf0\x0f\x0f\xf0\xf0\x0f\x0f");
    try common.testRoundtrip(u64, VInt64(u64), std.math.maxInt(u64), "\x00\xff\xff\xff\xff\xff\xff\xff\xff");
}

test "u32" {
    try common.testRoundtrip(u32, VInt64(u32), 0, "\x01");
}

test "u16" {
    try common.testRoundtrip(u16, VInt64(u16), 0, "\x01");
}

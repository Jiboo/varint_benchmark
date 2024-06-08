// Baseline for benchmark memcpy and native to little conversion

const std = @import("std");
const common = @import("common.zig");

pub fn Fixed(comptime T: type) type {
    return struct {
        const SIZE = @sizeOf(T);

        pub fn encode(buff: [*]u8, raw: T) usize {
            common.writePtr(T, buff, raw);
            return SIZE;
        }

        pub fn decode(buff: [*]const u8) struct { val: T, len: usize } {
            return .{
                .val = std.mem.littleToNative(T, common.readPtr(T, buff)),
                .len = SIZE,
            };
        }
    };
}

test "u128" {
    try common.testRoundtrip(u128, Fixed(u128), 0x00000000000000000000000000000000, "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00");
    try common.testRoundtrip(u128, Fixed(u128), 0x0123456789ABCDEF0123456789ABCDEF, "\xEF\xCD\xAB\x89\x67\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
}

test "u64" {
    try common.testRoundtrip(u64, Fixed(u64), 0x0000000000000000, "\x00\x00\x00\x00\x00\x00\x00\x00");
    try common.testRoundtrip(u64, Fixed(u64), 0x0123456789ABCDEF, "\xEF\xCD\xAB\x89\x67\x45\x23\x01");
}

test "u32" {
    try common.testRoundtrip(u32, Fixed(u32), 0x00000000, "\x00\x00\x00\x00");
    try common.testRoundtrip(u32, Fixed(u32), 0x01234567, "\x67\x45\x23\x01");
}

test "u16" {
    try common.testRoundtrip(u16, Fixed(u16), 0x0000, "\x00\x00");
    try common.testRoundtrip(u16, Fixed(u16), 0x0123, "\x23\x01");
}

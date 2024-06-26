// Slightly modified https://john-millikin.com/vu128-efficient-variable-length-integers
// Marker depends on source/target types, so for encoding:
// - u128, aka vu128 marker is 0xF0, and 16 byte max
// - u64, aka vu64, marker is 0xF8, and 8 byte max
// - etc

const std = @import("std");
const common = @import("common.zig");

pub fn VU128(comptime T: type) type {
    if (@typeInfo(T) != .Int) {
        @compileError("Using vu128 on non-int type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.signedness != .unsigned) {
        @compileError("Using vu128 on non-unsigned type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits > 128) {
        @compileError("Using vu128 on type too small: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits <= 8) {
        @compileError("Using vu128 on type too small: " ++ @typeName(T));
    }
    return struct {
        const MAX_SIZE = @sizeOf(T);
        const MASK = MAX_SIZE - 1;
        const MARKER = 0xFF - MASK;

        pub fn encode(buff: [*]u8, raw: T) usize {
            if (raw < MARKER) {
                buff[0] = @intCast(raw);
                return 1;
            }
            const byte_size = @as(u8, @intCast(common.relevantBytes(T, raw)));
            buff[0] = MARKER | (byte_size - 1);
            common.writePtr(T, buff + 1, std.mem.nativeToLittle(T, raw));
            return byte_size + 1;
        }

        pub fn decode(buff: [*]const u8) struct { val: T, len: usize } {
            const marker_byte = buff[0];
            if (marker_byte < MARKER) {
                return .{ .val = @intCast(marker_byte), .len = 1 };
            }
            const byte_size = (marker_byte & MASK) + 1;
            const read_ptr = true;
            return .{
                .val = std.mem.littleToNative(T, if (read_ptr) common.readPtrMasked(T, byte_size, buff + 1) else common.read(T, byte_size, buff + 1)),
                .len = byte_size + 1,
            };
        }
    };
}

test "u128" {
    try common.testRoundtrip(u128, VU128(u128), 0, "\x00");
    try common.testRoundtrip(u128, VU128(u128), 0xEF, "\xEF");
    try common.testRoundtrip(u128, VU128(u128), 0xF0, "\xF0\xF0");
    try common.testRoundtrip(u128, VU128(u128), 0xFF, "\xF0\xFF");
    try common.testRoundtrip(u128, VU128(u128), 0x0123, "\xF1\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x012345, "\xF2\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x01234567, "\xF3\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789, "\xF4\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789AB, "\xF5\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCD, "\xF6\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF, "\xF7\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF01, "\xF8\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF0123, "\xF9\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF012345, "\xFA\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF01234567, "\xFB\x67\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF0123456789, "\xFC\x89\x67\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF0123456789AB, "\xFD\xAB\x89\x67\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF0123456789ABCD, "\xFE\xCD\xAB\x89\x67\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u128, VU128(u128), 0x0123456789ABCDEF0123456789ABCDEF, "\xFF\xEF\xCD\xAB\x89\x67\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
}

test "u64" {
    try common.testRoundtrip(u64, VU128(u64), 0, "\x00");
    try common.testRoundtrip(u64, VU128(u64), 0xF7, "\xF7");
    try common.testRoundtrip(u64, VU128(u64), 0xF8, "\xF8\xF8");
    try common.testRoundtrip(u64, VU128(u64), 0xFF, "\xF8\xFF");
    try common.testRoundtrip(u64, VU128(u64), 0x0123, "\xF9\x23\x01");
    try common.testRoundtrip(u64, VU128(u64), 0x012345, "\xFA\x45\x23\x01");
    try common.testRoundtrip(u64, VU128(u64), 0x01234567, "\xFB\x67\x45\x23\x01");
    try common.testRoundtrip(u64, VU128(u64), 0x0123456789, "\xFC\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u64, VU128(u64), 0x0123456789AB, "\xFD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u64, VU128(u64), 0x0123456789ABCD, "\xFE\xCD\xAB\x89\x67\x45\x23\x01");
    try common.testRoundtrip(u64, VU128(u64), 0x0123456789ABCDEF, "\xFF\xEF\xCD\xAB\x89\x67\x45\x23\x01");
}

test "u32" {
    try common.testRoundtrip(u32, VU128(u32), 0, "\x00");
    try common.testRoundtrip(u32, VU128(u32), 0xFB, "\xFB");
    try common.testRoundtrip(u32, VU128(u32), 0xFC, "\xFC\xFC");
    try common.testRoundtrip(u32, VU128(u32), 0xFF, "\xFC\xFF");
    try common.testRoundtrip(u32, VU128(u32), 0x0123, "\xFD\x23\x01");
    try common.testRoundtrip(u32, VU128(u32), 0x012345, "\xFE\x45\x23\x01");
    try common.testRoundtrip(u32, VU128(u32), 0x01234567, "\xFF\x67\x45\x23\x01");
}

test "u16" {
    try common.testRoundtrip(u16, VU128(u16), 0, "\x00");
    try common.testRoundtrip(u16, VU128(u16), 0xFD, "\xFD");
    try common.testRoundtrip(u16, VU128(u16), 0xFE, "\xFE\xFE");
    try common.testRoundtrip(u16, VU128(u16), 0xFF, "\xFE\xFF");
    try common.testRoundtrip(u16, VU128(u16), 0x0123, "\xFF\x23\x01");
}

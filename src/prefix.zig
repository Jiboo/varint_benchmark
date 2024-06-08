// This is a stupid format where there's a prefix byte indicating length in buffer

const std = @import("std");
const common = @import("common.zig");

pub fn Prefix(PrefixType: type, ValueType: type) type {
    if (@typeInfo(ValueType) != .Int) {
        @compileError("Using prefix on non-int value type: " ++ @typeName(ValueType));
    }
    if (@typeInfo(ValueType).Int.signedness != .unsigned) {
        @compileError("Using prefix on non-unsigned value type: " ++ @typeName(ValueType));
    }
    if (@typeInfo(ValueType).Int.bits > 128) {
        @compileError("Using prefix on value type too big: " ++ @typeName(ValueType));
    }
    if (@typeInfo(ValueType).Int.bits <= 8) {
        @compileError("Using prefix on value type too small: " ++ @typeName(ValueType));
    }
    if (@typeInfo(ValueType) != .Int) {
        @compileError("Using prefix on non-int prefix type: " ++ @typeName(PrefixType));
    }
    if (@typeInfo(ValueType).Int.signedness != .unsigned) {
        @compileError("Using prefix on non-unsigned prefix type: " ++ @typeName(PrefixType));
    }
    if (@typeInfo(ValueType).Int.bits > 128) {
        @compileError("Using prefix on prefix type too big: " ++ @typeName(PrefixType));
    }
    return struct {
        const PREFIX_SIZE = @sizeOf(PrefixType);
        const VALUE_SIZE = @sizeOf(ValueType);

        pub fn encode(buff: [*]u8, raw: ValueType) usize {
            const byte_size = @as(PrefixType, @intCast(common.relevantBytes(ValueType, raw)));
            common.writePtr(PrefixType, buff, std.mem.nativeToLittle(PrefixType, byte_size));
            common.writePtr(ValueType, buff + PREFIX_SIZE, std.mem.nativeToLittle(ValueType, raw));
            return PREFIX_SIZE + byte_size;
        }

        pub fn decode(buff: [*]const u8) struct { val: ValueType, len: usize } {
            const byte_size: u8 = @intCast(std.mem.littleToNative(PrefixType, common.readPtr(PrefixType, buff)));
            var result: ValueType = undefined;
            const ptr_read = true;
            if (ptr_read) {
                result = std.mem.littleToNative(ValueType, common.readPtrMasked(ValueType, byte_size, buff + PREFIX_SIZE));
            } else {
                result = std.mem.littleToNative(ValueType, common.read(ValueType, byte_size, buff + PREFIX_SIZE));
            }
            return .{
                .val = result,
                .len = PREFIX_SIZE + byte_size,
            };
        }
    };
}

test "prefix sizes" {
    try common.testRoundtrip(u64, Prefix(u8, u64), 0, "\x01\x00");
    try common.testRoundtrip(u64, Prefix(u8, u64), 0xFF, "\x01\xFF");
    try common.testRoundtrip(u64, Prefix(u8, u64), 0x1FF, "\x02\xFF\x01");

    try common.testRoundtrip(u64, Prefix(u16, u64), 0, "\x01\x00\x00");
    try common.testRoundtrip(u64, Prefix(u16, u64), 0xFF, "\x01\x00\xFF");
    try common.testRoundtrip(u64, Prefix(u16, u64), 0x1FF, "\x02\x00\xFF\x01");

    try common.testRoundtrip(u64, Prefix(u32, u64), 0, "\x01\x00\x00\x00\x00");
    try common.testRoundtrip(u64, Prefix(u32, u64), 0xFF, "\x01\x00\x00\x00\xFF");
    try common.testRoundtrip(u64, Prefix(u32, u64), 0x1FF, "\x02\x00\x00\x00\xFF\x01");
}

test "u32" {
    try common.testRoundtrip(u32, Prefix(u8, u32), 0, "\x01\x00");
    try common.testRoundtrip(u32, Prefix(u8, u32), 0xFF, "\x01\xFF");
    try common.testRoundtrip(u32, Prefix(u8, u32), 0x1FF, "\x02\xFF\x01");
}

test "u16" {
    try common.testRoundtrip(u16, Prefix(u8, u16), 0, "\x01\x00");
    try common.testRoundtrip(u16, Prefix(u8, u16), 0xFF, "\x01\xFF");
    try common.testRoundtrip(u16, Prefix(u8, u16), 0x1FF, "\x02\xFF\x01");
}

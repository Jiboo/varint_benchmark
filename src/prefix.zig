// This is a stupid format where there's a prefix byte indicating length in buffer

const std = @import("std");
const common = @import("common.zig");

pub fn prefix(PrefixType: type, ValueType: type) type {
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
            const byte_size = @as(PrefixType, @intCast(common.relevant_bytes(ValueType, raw)));
            common.write_ptr(PrefixType, buff, std.mem.nativeToLittle(PrefixType, byte_size));
            common.write_ptr(ValueType, buff + PREFIX_SIZE, std.mem.nativeToLittle(ValueType, raw));
            return PREFIX_SIZE + byte_size;
        }

        pub fn decode(buff: [*]const u8) struct { val: ValueType, len: usize } {
            const byte_size: u8 = @intCast(std.mem.littleToNative(PrefixType, common.read_ptr(PrefixType, buff)));
            var result: ValueType = undefined;
            const ptr_read = true;
            if (ptr_read) {
                result = std.mem.littleToNative(ValueType, common.read_ptr_masked(ValueType, byte_size, buff + PREFIX_SIZE));
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

fn test_encdec(PrefixType: type, ValueType: type, expected_val: ValueType, expected_enc: []const u8) !void {
    var enc: [9]u8 = undefined;
    try std.testing.expectEqual(expected_enc.len, prefix(PrefixType, ValueType).encode(&enc, expected_val));
    try std.testing.expectEqualSlices(u8, expected_enc, enc[0..expected_enc.len]);

    const decode_res = prefix(PrefixType, ValueType).decode(&enc);
    try std.testing.expectEqual(expected_enc.len, decode_res.len);
    try std.testing.expectEqual(expected_val, decode_res.val);
}

test "prefix sizes" {
    try test_encdec(u8, u64, 0, "\x01\x00");
    try test_encdec(u8, u64, 0xFF, "\x01\xFF");
    try test_encdec(u8, u64, 0x1FF, "\x02\xFF\x01");

    try test_encdec(u16, u64, 0, "\x01\x00\x00");
    try test_encdec(u16, u64, 0xFF, "\x01\x00\xFF");
    try test_encdec(u16, u64, 0x1FF, "\x02\x00\xFF\x01");

    try test_encdec(u32, u64, 0, "\x01\x00\x00\x00\x00");
    try test_encdec(u32, u64, 0xFF, "\x01\x00\x00\x00\xFF");
    try test_encdec(u32, u64, 0x1FF, "\x02\x00\x00\x00\xFF\x01");
}

test "u32" {
    try test_encdec(u8, u32, 0, "\x01\x00");
    try test_encdec(u8, u32, 0xFF, "\x01\xFF");
    try test_encdec(u8, u32, 0x1FF, "\x02\xFF\x01");
}

test "u16" {
    try test_encdec(u8, u16, 0, "\x01\x00");
    try test_encdec(u8, u16, 0xFF, "\x01\xFF");
    try test_encdec(u8, u16, 0x1FF, "\x02\xFF\x01");
}

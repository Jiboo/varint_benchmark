// https://en.wikipedia.org/wiki/LEB128

const std = @import("std");

pub fn uleb128(comptime T: type) type {
    if (@typeInfo(T) != .Int) {
        @compileError("Using uleb128 on non-int type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.signedness != .unsigned) {
        @compileError("Using uleb128 on non-unsigned type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits > 128) {
        @compileError("Using uleb128 on type too big: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits <= 8) {
        @compileError("Using uleb128 on type too small: " ++ @typeName(T));
    }
    return struct {
        pub fn encode(buff: [*]u8, raw: T) usize {
            var offset: u8 = 0;
            var value = raw;
            while (true) {
                const byte: u8 = @truncate(value & 0x7f);
                value >>= 7;
                if (value != 0) {
                    buff[offset] = byte | 0x80;
                    offset += 1;
                } else {
                    buff[offset] = byte;
                    offset += 1;
                    break;
                }
            }
            return offset;
        }

        pub fn decode(buff: [*]const u8) struct { val: T, len: usize } {
            var result: T = 0;
            var offset: std.math.Log2Int(T) = 0;
            while (true) {
                const byte: T = buff[offset];
                result |= (byte & 0x7f) << (offset * 7);
                if ((byte & 0x80) == 0)
                    break;
                offset += 1;
            }
            return .{
                .val = result,
                .len = offset + 1,
            };
        }
    };
}

fn test_encdec(comptime T: type, expected_val: T, expected_enc: []const u8) !void {
    var enc: [17]u8 = undefined;
    try std.testing.expectEqual(expected_enc.len, uleb128(T).encode(&enc, expected_val));
    try std.testing.expectEqualSlices(u8, expected_enc, enc[0..expected_enc.len]);

    const decode_res = uleb128(T).decode(&enc);
    try std.testing.expectEqual(expected_enc.len, decode_res.len);
    try std.testing.expectEqual(expected_val, decode_res.val);
}

test "conformant" {
    try test_encdec(u64, 0, "\x00");
    try test_encdec(u64, 0x01, "\x01");
    try test_encdec(u64, 0x7f, "\x7f");
    try test_encdec(u64, 0x80, "\x80\x01");
    try test_encdec(u32, 0x80, "\x80\x01");
    try test_encdec(u16, 0x80, "\x80\x01");
    try test_encdec(u64, 0x8000000000000000, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x01");
}

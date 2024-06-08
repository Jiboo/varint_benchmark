// Baseline for benchmark memcpy and native to little conversion

const std = @import("std");
const common = @import("common.zig");

pub fn fixed(comptime T: type) type {
    return struct {
        const SIZE = @sizeOf(T);

        pub fn encode(buff: [*]u8, raw: T) usize {
            common.write_ptr(T, buff, raw);
            return SIZE;
        }

        pub fn decode(buff: [*]const u8) struct { val: T, len: usize } {
            return .{
                .val = std.mem.littleToNative(T, common.read_ptr(T, buff)),
                .len = SIZE,
            };
        }
    };
}

fn test_encdec(comptime T: type, expected_val: T, expected_enc: []const u8) !void {
    var enc: [17]u8 = undefined;
    try std.testing.expectEqual(expected_enc.len, fixed(T).encode(&enc, expected_val));
    try std.testing.expectEqualSlices(u8, expected_enc, enc[0..expected_enc.len]);

    const decode_res = fixed(T).decode(&enc);
    try std.testing.expectEqual(expected_enc.len, decode_res.len);
    try std.testing.expectEqual(expected_val, decode_res.val);
}

test "u128" {
    try test_encdec(u128, 0x00000000000000000000000000000000, "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00");
    try test_encdec(u128, 0x0123456789ABCDEF0123456789ABCDEF, "\xEF\xCD\xAB\x89\x67\x45\x23\x01\xEF\xCD\xAB\x89\x67\x45\x23\x01");
}

test "u64" {
    try test_encdec(u64, 0x0000000000000000, "\x00\x00\x00\x00\x00\x00\x00\x00");
    try test_encdec(u64, 0x0123456789ABCDEF, "\xEF\xCD\xAB\x89\x67\x45\x23\x01");
}

test "u32" {
    try test_encdec(u32, 0x00000000, "\x00\x00\x00\x00");
    try test_encdec(u32, 0x01234567, "\x67\x45\x23\x01");
}

test "u16" {
    try test_encdec(u16, 0x0000, "\x00\x00");
    try test_encdec(u16, 0x0123, "\x23\x01");
}

const std = @import("std");

pub fn relevant_bytes(T: type, val: T) usize {
    const insignificant_bytes = @clz(val | 1) / 8;
    return @sizeOf(T) - insignificant_bytes;
}

pub fn write_ptr(T: type, buff: [*]u8, raw: T) void {
    const dst: *align(1) T = @ptrCast(buff);
    dst.* = raw;
}

pub fn read_ptr(T: type, buff: [*]const u8) T {
    const src: *align(1) const T = @ptrCast(buff);
    return src.*;
}

pub fn read_ptr_masked(T: type, expected_bytes: u8, buff: [*]const u8) T {
    const MAX_BYTE_COUNT = @sizeOf(T);
    const raw = read_ptr(T, buff);

    // Old generic version, too much cycles
    //if (expected_bytes == MAX_BYTE_COUNT) {
    //    return raw;
    //}
    //const TShiftType = std.meta.Int(.unsigned, std.math.log2_int(usize, @bitSizeOf(T)));
    //const used = 8 * @as(TShiftType, @intCast(expected_bytes));
    //const MaskShiftType = std.meta.Int(.unsigned, @bitSizeOf(T) + 1);
    //const mask: T = @intCast((@as(MaskShiftType, 1) << used) - 1);
    //return raw & mask;

    if (MAX_BYTE_COUNT == 16) {
        const mask: T = switch (expected_bytes) {
            1 => 0xFF,
            2 => 0xFFFF,
            3 => 0xFFFFFF,
            4 => 0xFFFFFFFF,
            5 => 0xFFFFFFFFFF,
            6 => 0xFFFFFFFFFFFF,
            7 => 0xFFFFFFFFFFFFFF,
            8 => 0xFFFFFFFFFFFFFFFF,
            9 => 0xFFFFFFFFFFFFFFFFFF,
            10 => 0xFFFFFFFFFFFFFFFFFFFF,
            11 => 0xFFFFFFFFFFFFFFFFFFFFFF,
            12 => 0xFFFFFFFFFFFFFFFFFFFFFFFF,
            13 => 0xFFFFFFFFFFFFFFFFFFFFFFFFFF,
            14 => 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
            15 => 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
            16 => 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
            else => unreachable,
        };
        return raw & mask;
    } else if (MAX_BYTE_COUNT == 8) {
        const mask: T = switch (expected_bytes) {
            1 => 0xFF,
            2 => 0xFFFF,
            3 => 0xFFFFFF,
            4 => 0xFFFFFFFF,
            5 => 0xFFFFFFFFFF,
            6 => 0xFFFFFFFFFFFF,
            7 => 0xFFFFFFFFFFFFFF,
            8 => 0xFFFFFFFFFFFFFFFF,
            else => unreachable,
        };
        return raw & mask;
    } else if (MAX_BYTE_COUNT == 4) {
        const mask: T = switch (expected_bytes) {
            1 => 0xFF,
            2 => 0xFFFF,
            3 => 0xFFFFFF,
            4 => 0xFFFFFFFF,
            else => unreachable,
        };
        return raw & mask;
    } else if (MAX_BYTE_COUNT == 2) {
        const mask: T = switch (expected_bytes) {
            1 => 0xFF,
            2 => 0xFFFF,
            else => unreachable,
        };
        return raw & mask;
    }
    unreachable;
}

pub fn write(T: type, byte_size: usize, buff: [*]u8, raw: T) void {
    const MAX_BYTE_COUNT = @sizeOf(T);
    if (MAX_BYTE_COUNT == 16) {
        switch (byte_size) {
            16 => std.mem.copyForwards(u8, buff[0..16], std.mem.asBytes(&raw)[0..16]),
            15 => std.mem.copyForwards(u8, buff[0..15], std.mem.asBytes(&raw)[0..15]),
            14 => std.mem.copyForwards(u8, buff[0..14], std.mem.asBytes(&raw)[0..14]),
            13 => std.mem.copyForwards(u8, buff[0..13], std.mem.asBytes(&raw)[0..13]),
            12 => std.mem.copyForwards(u8, buff[0..12], std.mem.asBytes(&raw)[0..12]),
            11 => std.mem.copyForwards(u8, buff[0..11], std.mem.asBytes(&raw)[0..11]),
            10 => std.mem.copyForwards(u8, buff[0..10], std.mem.asBytes(&raw)[0..10]),
            9 => std.mem.copyForwards(u8, buff[0..9], std.mem.asBytes(&raw)[0..9]),
            8 => std.mem.copyForwards(u8, buff[0..8], std.mem.asBytes(&raw)[0..8]),
            7 => std.mem.copyForwards(u8, buff[0..7], std.mem.asBytes(&raw)[0..7]),
            6 => std.mem.copyForwards(u8, buff[0..6], std.mem.asBytes(&raw)[0..6]),
            5 => std.mem.copyForwards(u8, buff[0..5], std.mem.asBytes(&raw)[0..5]),
            4 => std.mem.copyForwards(u8, buff[0..4], std.mem.asBytes(&raw)[0..4]),
            3 => std.mem.copyForwards(u8, buff[0..3], std.mem.asBytes(&raw)[0..3]),
            2 => std.mem.copyForwards(u8, buff[0..2], std.mem.asBytes(&raw)[0..2]),
            1 => std.mem.copyForwards(u8, buff[0..1], std.mem.asBytes(&raw)[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 8) {
        switch (byte_size) {
            8 => std.mem.copyForwards(u8, buff[0..8], std.mem.asBytes(&raw)[0..8]),
            7 => std.mem.copyForwards(u8, buff[0..7], std.mem.asBytes(&raw)[0..7]),
            6 => std.mem.copyForwards(u8, buff[0..6], std.mem.asBytes(&raw)[0..6]),
            5 => std.mem.copyForwards(u8, buff[0..5], std.mem.asBytes(&raw)[0..5]),
            4 => std.mem.copyForwards(u8, buff[0..4], std.mem.asBytes(&raw)[0..4]),
            3 => std.mem.copyForwards(u8, buff[0..3], std.mem.asBytes(&raw)[0..3]),
            2 => std.mem.copyForwards(u8, buff[0..2], std.mem.asBytes(&raw)[0..2]),
            1 => std.mem.copyForwards(u8, buff[0..1], std.mem.asBytes(&raw)[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 4) {
        switch (byte_size) {
            4 => std.mem.copyForwards(u8, buff[0..4], std.mem.asBytes(&raw)[0..4]),
            3 => std.mem.copyForwards(u8, buff[0..3], std.mem.asBytes(&raw)[0..3]),
            2 => std.mem.copyForwards(u8, buff[0..2], std.mem.asBytes(&raw)[0..2]),
            1 => std.mem.copyForwards(u8, buff[0..1], std.mem.asBytes(&raw)[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 2) {
        switch (byte_size) {
            2 => std.mem.copyForwards(u8, buff[0..2], std.mem.asBytes(&raw)[0..2]),
            1 => std.mem.copyForwards(u8, buff[0..1], std.mem.asBytes(&raw)[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 1) {
        std.mem.copyForwards(u8, buff[0..1], std.mem.asBytes(&raw)[0..1]);
    } else {
        unreachable;
    }
}

pub fn read(T: type, byte_size: usize, buff: [*]const u8) T {
    const MAX_BYTE_COUNT = @sizeOf(T);
    var result: T = 0;
    if (MAX_BYTE_COUNT == 16) {
        switch (byte_size) {
            16 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..16], buff[0..16]),
            15 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..15], buff[0..15]),
            14 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..14], buff[0..14]),
            13 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..13], buff[0..13]),
            12 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..12], buff[0..12]),
            11 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..11], buff[0..11]),
            10 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..10], buff[0..10]),
            9 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..9], buff[0..9]),
            8 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..8], buff[0..8]),
            7 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..7], buff[0..7]),
            6 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..6], buff[0..6]),
            5 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..5], buff[0..5]),
            4 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..4], buff[0..4]),
            3 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..3], buff[0..3]),
            2 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..2], buff[0..2]),
            1 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..1], buff[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 8) {
        switch (byte_size) {
            8 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..8], buff[0..8]),
            7 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..7], buff[0..7]),
            6 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..6], buff[0..6]),
            5 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..5], buff[0..5]),
            4 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..4], buff[0..4]),
            3 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..3], buff[0..3]),
            2 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..2], buff[0..2]),
            1 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..1], buff[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 4) {
        switch (byte_size) {
            4 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..4], buff[0..4]),
            3 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..3], buff[0..3]),
            2 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..2], buff[0..2]),
            1 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..1], buff[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 2) {
        switch (byte_size) {
            2 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..2], buff[0..2]),
            1 => std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..1], buff[0..1]),
            else => unreachable,
        }
    } else if (MAX_BYTE_COUNT == 1) {
        std.mem.copyForwards(u8, std.mem.asBytes(&result)[0..1], buff[0..1]);
    } else {
        unreachable;
    }
    return result;
}

// Based on https://sqlite.org/src4/doc/trunk/www/varint.wiki

const std = @import("std");
const common = @import("common.zig");

pub fn SQLite4(comptime T: type) type {
    if (@typeInfo(T) != .Int) {
        @compileError("Using sqlite4 on non-int type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.signedness != .unsigned) {
        @compileError("Using sqlite4 on non-unsigned type: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits > 64) {
        @compileError("Using sqlite4 on type too big: " ++ @typeName(T));
    }
    if (@typeInfo(T).Int.bits <= 8) {
        @compileError("Using sqlite4 on type too small: " ++ @typeName(T));
    }
    return struct {
        pub fn encode(A: [*]u8, V: T) usize {
            switch (V) {
                0...240 => {
                    A[0] = @truncate(V);
                    return 1;
                },
                241...2287 => {
                    A[0] = @truncate((V - 240) / 256 + 241);
                    A[1] = @truncate((V - 240) % 256);
                    return 2;
                },
                2288...67823 => {
                    A[0] = 249;
                    A[1] = @truncate((V - 2288) / 256);
                    A[2] = @truncate((V - 2288) % 256);
                    return 3;
                },
                67824...16777215 => {
                    A[0] = 250;
                    std.mem.copyForwards(u8, A[1..4], std.mem.asBytes(&std.mem.nativeToBig(u24, @truncate(V)))[0..3]);
                    return 4;
                },
                16777216...4294967295 => {
                    A[0] = 251;
                    std.mem.copyForwards(u8, A[1..5], std.mem.asBytes(&std.mem.nativeToBig(u32, @truncate(V)))[0..4]);
                    return 5;
                },
                4294967296...1099511627775 => {
                    A[0] = 252;
                    std.mem.copyForwards(u8, A[1..6], std.mem.asBytes(&std.mem.nativeToBig(u40, @truncate(V)))[0..5]);
                    return 6;
                },
                1099511627776...281474976710655 => {
                    A[0] = 253;
                    std.mem.copyForwards(u8, A[1..7], std.mem.asBytes(&std.mem.nativeToBig(u48, @truncate(V)))[0..6]);
                    return 7;
                },
                281474976710656...72057594037927935 => {
                    A[0] = 254;
                    std.mem.copyForwards(u8, A[1..8], std.mem.asBytes(&std.mem.nativeToBig(u56, @truncate(V)))[0..7]);
                    return 8;
                },
                else => {
                    A[0] = 255;
                    std.mem.copyForwards(u8, A[1..9], std.mem.asBytes(&std.mem.nativeToBig(u64, @truncate(V)))[0..8]);
                    return 9;
                },
            }
        }

        pub fn decode(A: [*]const u8) struct { val: T, len: usize } {
            const A0: u8 = A[0];
            switch (A0) {
                0...240 => {
                    return .{
                        .val = A0,
                        .len = 1,
                    };
                },
                241...248 => {
                    return .{
                        .val = 240 + 256 * @as(T, A0 - 241) + A[1],
                        .len = 2,
                    };
                },
                249 => {
                    return .{
                        .val = 2288 + 256 * @as(T, A[1]) + A[2],
                        .len = 3,
                    };
                },
                250 => {
                    var result: u24 = 0;
                    var slice = std.mem.asBytes(&result);
                    std.mem.copyForwards(u8, slice[0..3], A[1..4]);
                    return .{
                        .val = std.mem.bigToNative(u24, result),
                        .len = 4,
                    };
                },
                251 => {
                    var result: u32 = 0;
                    var slice = std.mem.asBytes(&result);
                    std.mem.copyForwards(u8, slice[0..4], A[1..5]);
                    return .{
                        .val = std.mem.bigToNative(u32, result),
                        .len = 5,
                    };
                },
                252 => {
                    var result: u40 = 0;
                    var slice = std.mem.asBytes(&result);
                    std.mem.copyForwards(u8, slice[0..5], A[1..6]);
                    return .{
                        .val = std.mem.bigToNative(u40, result),
                        .len = 6,
                    };
                },
                253 => {
                    var result: u48 = 0;
                    var slice = std.mem.asBytes(&result);
                    std.mem.copyForwards(u8, slice[0..6], A[1..7]);
                    return .{
                        .val = std.mem.bigToNative(u48, result),
                        .len = 7,
                    };
                },
                254 => {
                    var result: u56 = 0;
                    var slice = std.mem.asBytes(&result);
                    std.mem.copyForwards(u8, slice[0..7], A[1..8]);
                    return .{
                        .val = std.mem.bigToNative(u56, result),
                        .len = 8,
                    };
                },
                255 => {
                    var result: u64 = 0;
                    var slice = std.mem.asBytes(&result);
                    std.mem.copyForwards(u8, slice[0..8], A[1..9]);
                    return .{
                        .val = std.mem.bigToNative(u64, result),
                        .len = 9,
                    };
                },
            }
        }
    };
}

test "conformant" {
    // From https://github.com/mohae/sqlite4-varint-bench/blob/master/bench_test.go
    try common.testRoundtrip(u64, SQLite4(u64), 0, "\x00");
    try common.testRoundtrip(u64, SQLite4(u64), 240, "\xF0");
    try common.testRoundtrip(u64, SQLite4(u64), 241, "\xF1\x01");
    try common.testRoundtrip(u64, SQLite4(u64), 2287, "\xF8\xFF");
    try common.testRoundtrip(u64, SQLite4(u64), 2288, "\xF9\x00\x00");
    try common.testRoundtrip(u64, SQLite4(u64), 67823, "\xF9\xFF\xFF");
    try common.testRoundtrip(u64, SQLite4(u64), 67824, "\xFA\x01\x08\xF0");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 24) - 1, "\xFA\xFF\xFF\xFF");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 24) - 0, "\xFB\x01\x00\x00\x00");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 32) - 1, "\xFB\xFF\xFF\xFF\xFF");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 32) - 0, "\xFC\x01\x00\x00\x00\x00");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 40) - 1, "\xFC\xFF\xFF\xFF\xFF\xFF");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 40) - 0, "\xFD\x01\x00\x00\x00\x00\x00");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 48) - 1, "\xFD\xFF\xFF\xFF\xFF\xFF\xFF");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 48) - 0, "\xFE\x01\x00\x00\x00\x00\x00\x00");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 56) - 1, "\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xFF");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 56) - 0, "\xFF\x01\x00\x00\x00\x00\x00\x00\x00");
    try common.testRoundtrip(u64, SQLite4(u64), (1 << 64) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF");
}

test "u32" {
    // TODO
    // try test_encdec(u32, 0, "\x00");
}

test "u16" {
    // TODO
    // try test_encdec(u16, 0, "\x00");
}

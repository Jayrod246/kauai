// This file exports the functions necessary for c++ code to interact with zig.

const io = @import("std").io;
const k = @import("kauai");

// Standard Kauai decompression
pub export fn ZigDecompress(pvSrc: *anyopaque, cbSrc: u32, pvDst: *anyopaque, cbDst: u32, pcbDst: *u32) bool {
    return decompress(.Kauai, .{ pvSrc, cbSrc, pvDst, cbDst, pcbDst });
}

// Kauai2 variant
pub export fn ZigDecompress2(pvSrc: *anyopaque, cbSrc: u32, pvDst: *anyopaque, cbDst: u32, pcbDst: ?*u32) bool {
    return decompress(.Kauai2, .{ pvSrc, cbSrc, pvDst, cbDst, pcbDst });
}

inline fn decompress(comptime codec: k.compress.Codec, args: anytype) bool {
    const f = struct {
        inline fn f(pvSrc: *anyopaque, cbSrc: u32, pvDst: *anyopaque, cbDst: u32, pcbDst: ?*u32) bool {
            _ = pcbDst;
            var src = io.fixedBufferStream(@as([*]const u8, @ptrCast(pvSrc))[0..@intCast(cbSrc)]);
            const dst = @as([*]u8, @ptrCast(pvDst))[0..@intCast(cbDst)];

            src.reader().skipBytes(1, .{}) catch return false;
            k.compress.decompress(src.reader()).unpack(codec, dst) catch return false;

            return true;
        }
    }.f;

    return @call(.always_inline, f, args);
}

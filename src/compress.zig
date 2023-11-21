const std = @import("std");
const io = std.io;

pub const Codec = enum {
    Kauai,
    Kauai2,
};

pub fn Decompress(comptime ReaderType: type) type {
    return struct {
        const Self = @This();
        const BitReader = io.BitReader(.little, ReaderType);

        pub const Error = ReaderType.Error ||
            error{CorruptedData};
        pub const Reader = io.FixedBufferStream([]u8).Reader;
        source: ReaderType,

        fn init(source: ReaderType) Self {
            return .{
                .source = source,
            };
        }

        pub fn readHeader(self: Self) Error!struct { codec: Codec, uncompressed_size: usize } {
            const header = try self.source.readBytesNoEof(9);
            const tag = std.meta.stringToEnum(enum { KCDC, KCD2 }, header[0..4]) orelse return error.CorruptedData;
            const uncompressed_size = std.mem.readIntBig(u32, header[4..8]);
            const codec: Codec = switch (tag) {
                .KCDC => .Kauai,
                .KCD2 => .Kauai2,
            };
            return .{ .codec = codec, .uncompressed_size = uncompressed_size };
        }

        pub fn unpack(self: Self, codec: Codec, dest_slice: []u8) !void {
            try (&switch (codec) {
                .Kauai => unpack1,
                .Kauai2 => unpack2,
            })(self.source, dest_slice);
        }

        fn unpack1(r: ReaderType, output: []u8) !void {
            var source = io.bitReader(.little, r);
            var pos: usize = 0;

            outer_loop: while (true) {
                var count_ones = countOnes(&source, 4);
                if (count_ones.limit_or_eof and count_ones.count < 4) return error.CorruptedData;

                // Performing a copy assumes at least 1 byte to be copied,
                // so add 1
                var end = pos + 1;

                const relative_pos = switch (count_ones.count) {
                    0 => {
                        const byte_literal = try source.readBitsNoEof(u8, 8);
                        output[pos] = byte_literal;
                        pos += 1;
                        continue;
                    },
                    // These are positions relative to pos
                    1 => try source.readBitsNoEof(usize, 6) + 0x01,
                    2 => try source.readBitsNoEof(usize, 9) + 0x41,
                    3 => try source.readBitsNoEof(usize, 12) + 0x0241,
                    4 => blk: {
                        const n = try source.readBitsNoEof(usize, 20);

                        if (n == 0xFFFFF) // Detect the EOF signature
                            break :outer_loop;

                        // Performing a copy assumes at least 1 byte, except for
                        // this case, where it's at least 2, so add 1
                        end += 1;

                        break :blk n + 0x1241;
                    },
                    else => unreachable,
                };

                count_ones = countOnes(&source, 12);
                if (count_ones.limit_or_eof and count_ones.count < 12) {
                    return error.CorruptedData;
                }

                end += try source.readBitsNoEof(usize, count_ones.count) + (@as(usize, 1) << count_ones.count);

                for (output[pos..end], output[pos - relative_pos .. end - relative_pos]) |*d, s| d.* = s;
                pos = end;
            }
        }

        fn unpack2(r: ReaderType, output: []u8) !void {
            var source = io.bitReader(.little, r);
            var pos: usize = 0;

            while (true) {
                var count_ones = countOnes(&source, 20);
                if (count_ones.limit_or_eof) {
                    if (count_ones.count < 20) {
                        return error.CorruptedData;
                    } else {
                        break;
                    }
                }

                var end = pos + try source.readBitsNoEof(usize, count_ones.count) + (@as(usize, 1) << count_ones.count);

                count_ones = countOnes(&source, 4);
                if (count_ones.limit_or_eof and count_ones.count < 4) return error.CorruptedData;

                const relative_pos = switch (count_ones.count) {
                    // This means we are copying a stream of literals
                    0 => {
                        // If we have alignment then we can just read
                        if (source.bit_count == 0) {
                            _ = try source.read(output[pos..end]);
                        } else {
                            // Not byte aligned, so calculate bit_offset
                            const remaining_bits = source.bit_count;
                            const bit_offset = 8 - @as(usize, remaining_bits);

                            // and read a partial byte, enough to get us into alignment
                            var the_last_byte = try source.readBitsNoEof(u8, remaining_bits);
                            _ = try source.read(output[pos..(end - 1)]);

                            // Read the remaining half of the partial byte and append
                            the_last_byte |= try source.readBitsNoEof(u8, bit_offset) << remaining_bits;
                            output[end - 1] = the_last_byte;
                        }
                        pos = end;
                        continue;
                    },
                    // These are positions relative to pos
                    1 => try source.readBitsNoEof(usize, 6) + 0x01,
                    2 => try source.readBitsNoEof(usize, 9) + 0x41,
                    3 => try source.readBitsNoEof(usize, 12) + 0x0241,
                    4 => blk: {
                        // Performing a copy assumes at least 1 byte, except for
                        // this case, where it's at least 2, so add 1
                        end += 1;
                        break :blk try source.readBitsNoEof(usize, 20) + 0x1241;
                    },
                    else => unreachable,
                };
                // Performing a copy assumes at least 1 byte to be copied,
                // so add 1
                end += 1;

                for (output[pos..end], output[pos - relative_pos .. end - relative_pos]) |*d, s| d.* = s;
                pos = end;
            }
        }

        const CountOnes = struct { count: u5, limit_or_eof: bool };

        inline fn countOnes(source: *BitReader, limit: u5) CountOnes {
            std.debug.assert(limit > 0);

            var count: u5 = 0;
            while (true) {
                const bit = source.readBitsNoEof(u1, 1) catch return .{ .count = count, .limit_or_eof = true };
                if (bit == 0) return .{ .count = count, .limit_or_eof = false };
                count += 1;
                if (count >= limit) return .{ .count = count, .limit_or_eof = true };
            }
        }
    };
}

pub fn decompress(reader: anytype) Decompress(@TypeOf(reader)) {
    return Decompress(@TypeOf(reader)).init(reader);
}

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const link_libcpp = b.option(bool, "libcpp", "Enable linking with libcpp. Default: false") orelse false;

    const audioman_dep = b.dependency("audioman", .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "kauai",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = .{ .path = "src/kauai-glue.zig" },
    });
    lib.root_module.sanitize_c = false;

    if (link_libcpp) {
        lib.defineCMacro("KAUAI_LINK_LIBCPP", null);
        lib.linkLibCpp();
    }

    lib.linkLibrary(audioman_dep.artifact("audioman"));
    lib.installLibraryHeaders(audioman_dep.artifact("audioman"));

    lib.addIncludePath(.{ .path = "kauai/src" });
    lib.installHeadersDirectory("kauai/src", "");
    lib.addCSourceFiles(.{ .files = kauai_sources, .flags = kauai_cflags });
    lib.linkSystemLibrary("user32");
    lib.linkSystemLibrary("gdi32");
    lib.linkSystemLibrary("msvfw32");
    lib.linkSystemLibrary("mpr");
    lib.linkSystemLibrary("comdlg32");
    lib.linkSystemLibrary("avifil32");

    const kauai_mod = b.addModule("kauai", .{
        .root_source_file = .{ .path = "src/kauai.zig" },
        .sanitize_c = false,
    });
    lib.root_module.addImport("kauai", kauai_mod);

    b.installArtifact(lib);
}

const kauai_cflags: []const []const u8 = &.{
    "-w",
    "-DLITTLE_ENDIAN",
    "-DWIN",
    "-DSTRICT",
    "-fms-extensions",
    "-fno-rtti",
    "-fno-exceptions",
};

const kauai_sources: []const []const u8 = &.{
    "kauai/src/no-libcpp.cpp",
    "kauai/src/appb.cpp",
    "kauai/src/base.cpp",
    "kauai/src/chcm.cpp",
    "kauai/src/chse.cpp",
    "kauai/src/chunk.cpp",
    "kauai/src/clip.cpp",
    "kauai/src/clok.cpp",
    "kauai/src/cmd.cpp",
    "kauai/src/codec.cpp",
    "kauai/src/codkauai.cpp",
    "kauai/src/crf.cpp",
    "kauai/src/ctl.cpp",
    "kauai/src/cursor.cpp",
    "kauai/src/dlg.cpp",
    "kauai/src/docb.cpp",
    "kauai/src/file.cpp",
    "kauai/src/gfx.cpp",
    "kauai/src/gob.cpp",
    "kauai/src/groups.cpp",
    "kauai/src/groups2.cpp",
    "kauai/src/kidhelp.cpp",
    "kauai/src/kidspace.cpp",
    "kauai/src/kidworld.cpp",
    "kauai/src/lex.cpp",
    "kauai/src/mbmp.cpp",
    "kauai/src/mbmpgui.cpp",
    "kauai/src/midi.cpp",
    "kauai/src/mididev.cpp",
    "kauai/src/mididev2.cpp",
    "kauai/src/mssio.cpp",
    "kauai/src/pic.cpp",
    "kauai/src/region.cpp",
    "kauai/src/rtxt.cpp",
    "kauai/src/rtxt2.cpp",
    "kauai/src/scrcom.cpp",
    "kauai/src/scrcomg.cpp",
    "kauai/src/screxe.cpp",
    "kauai/src/screxeg.cpp",
    "kauai/src/sndam.cpp",
    "kauai/src/sndm.cpp",
    "kauai/src/spell.cpp",
    "kauai/src/stream.cpp",
    "kauai/src/text.cpp",
    "kauai/src/textdoc.cpp",
    "kauai/src/util.cpp",
    "kauai/src/utilcopy.cpp",
    "kauai/src/utilerro.cpp",
    "kauai/src/utilglob.cpp",
    "kauai/src/utilint.cpp",
    "kauai/src/utilmem.cpp",
    "kauai/src/utilrnd.cpp",
    "kauai/src/utilstr.cpp",
    "kauai/src/video.cpp",
    "kauai/src/appbwin.cpp",
    "kauai/src/dlgwin.cpp",
    "kauai/src/filewin.cpp",
    "kauai/src/fniwin.cpp",
    "kauai/src/gfxwin.cpp",
    "kauai/src/memwin.cpp",
    "kauai/src/menuwin.cpp",
    "kauai/src/picwin.cpp",
    "kauai/src/gobwin.cpp",
    "kauai/src/stub.cpp",
};

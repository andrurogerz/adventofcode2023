const std = @import("std");

fn generateTargetsFor(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
    subdir: []const u8) void {

    const exe = b.addExecutable(.{
        .name = subdir,
        .root_source_file = .{ .path = b.fmt("{s}/main.zig", .{subdir}) },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(
        b.fmt("run_{s}", .{subdir}),
        b.fmt("Run {s}", .{subdir}));
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = b.fmt("{s}/main.zig", .{subdir}) },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step(
        b.fmt("test_{s}", .{subdir}),
        b.fmt("Run {s} unit tests", .{subdir}));
    test_step.dependOn(&run_unit_tests.step);
}

pub fn build(b: *std.Build) !void {

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // Enumerate all "dayN" subdirs and generate targets for each.
    var iter_dir = try std.fs.cwd().openIterableDir(".", .{ .no_follow = true } );
    defer iter_dir.close();

    var it = iter_dir.iterate();
    while (try it.next()) |dirent| {
        if (dirent.kind != .directory) {
            continue;
        }

        if (!std.mem.eql(u8, "day", dirent.name[0..3])) {
            continue;
        }

        var subdir = iter_dir.dir.openDir(dirent.name, .{ .no_follow = true }) catch continue;
        defer subdir.close();

        subdir.access("main.zig", .{ .mode = .read_only }) catch continue;

        generateTargetsFor(b, target, optimize, dirent.name);
    }
}

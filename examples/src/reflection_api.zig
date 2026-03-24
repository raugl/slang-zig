// NOTE: This needs a lot more work to translate the cpp version. After this is done
// `reflection_api.cpp` should be deleted.

// Reflection API Example Program
// ==============================
//
// This file provides the application code for the `reflection-api` example.
// This example uses the Slang reflection API to travserse the structure
// of the parameters of a Slang program and their types.
//
// This program is a companion Slang reflection API documentation:
// https://shader-slang.org/slang/user-guide/compiling.html

const std = @import("std");
const slang = @import("root.zig");

// Configuration
// -------------
//
// For simplicity, this example uses a hard-coded list of shader programs
// to compile, each represented as the name of a `.slang` file, along with
// a hard-coded list of targets to compile and reflect the programs for.

const source_file_names = [_][*:0]const u8{
    "raster-simple.slang",
    "compute-simple.slang",
};

const targets = [_]TargetDesc{
    .{ .format = .dxil, .name = "sm_6_0" },
    .{ .format = .spirv, .name = "sm_6_0" },
};

const TargetDesc = struct {
    format: slang.CompileTarget,
    profile: [*:0]const u8,
};

fn compileAndReflectProgram(gpa: std.mem.Allocator, session: *slang.ISession, source_file_name: [*:0]const u8) !void {
    beginObject();
    defer endObject();
    printComment("program");

    key("file name");
    printQuotedString(source_file_name);

    const source_file_path = resolveResource(source_file_name);
    const module = session.loadModule(source_file_path, null) orelse return error.LoadModuleFailed;
    defer module.release();

    var components_to_link: std.ArrayList(*slang.IComponentType) = .empty;
    defer components_to_link.deinit(gpa);

    // Variable decls
    key("global constants");

    beginArray();
    var childern = module.getModuleReflection().getChildern();
    while (childern.next()) |decl| {
        if (decl.asVariable()) |var_decl| {
            if (var_decl.findModifier(.@"const") and var_decl.findModifier(.static)) {
                element();
                printVariable(var_decl);
            }
        }
    }
    endArray();

    // Finding Entry Points
    key("defined entry points");
    const defined_entry_point_count = module.getDefinedEntryPointCount();

    beginArray();
    for (0..defined_entry_point_count) |i| {
        const entry_point = try module.getDefinedEntryPoint(i);
        defer entry_point.release();

        element();
        beginObject();
        key("name");
        printQuotedString(entry_point.getFunctionReflection().getName());
        endObject();

        try components_to_link.append(gpa, @ptrCast(entry_point));
    }
    endArray();

    // Composing and Linking
    const composed = try session.createCompositeComponentType(components_to_link.items, null);
    defer composed.release();

    const program = try composed.link(null);
    defer program.release();

    key("layouts");
    var failed = false;

    beginArray();
    for (targets, 0..) |target, target_index| {
        element();

        // Getting the Program Layout
        const program_layout = program.getLayout(target_index, null) orelse {
            failed = true;
            continue;
        };
        try collectEntryPointMetadata(program, target_index, defined_entry_point_count);
        printProgramLayout(program_layout, target.format);
    }
    endArray();

    if (failed) return error.ProgramGetLayoutFailed;
}

fn compileAndReflectPrograms(gpa: std.mem.Allocator, session: *slang.ISession) !void {
    beginArray();
    for (source_file_names) |file_name| {
        element();
        try compileAndReflectProgram(gpa, session, file_name);
    }
    endArray();
}

fn printVariable() void {
    //
}

fn printComment(str: [*:0]const u8) void {}
fn printQuotedString(str: [*:0]const u8) void {}
fn key(name: []const u8) void {}
fn beginArray() void {}
fn endArray() void {}
fn beginObject() void {}
fn endObject() void {}
fn element() void {}

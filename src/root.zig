const std = @import("std");
const builtin = @import("builtin");
const log = std.log.scoped(.slang);

// TODO: Fixup all type reflection returned types (optionals, errors etc)
// TODO: Copy over all the doc comments from slang
// TODO: Create tests for struct sizes and enum tags by reflecting this zig module, generating the
// c++ code that accesses the appropriate tags/sizeofs, maybe with some name conversion overrides
// for edge cases, and pass them back to zig via FFI. Write the actual assertion tests on the zig
// side, and write a build step for compiling and linking the c++ file and register it as a
// dependency of the test step.

const log_diagnostics = @import("options").log_diagnostics;
threadlocal var diagnostics_blob: *IBlob = @ptrFromInt(0x8);

fn getDiagnosticsPtr(out_diagnostics: ?**IBlob) ?**IBlob {
    return switch (log_diagnostics) {
        .always, .only_for_null => out_diagnostics orelse &diagnostics_blob,
        .never => out_diagnostics,
    };
}

fn logDiagnostics(diagnostics: ?**IBlob, out_diagnostics: ?**IBlob) void {
    if (log_diagnostics != .never and out_diagnostics == null and @intFromPtr(diagnostics_blob) != 0x8) {
        log.err("{s}", .{diagnostics_blob.getBuffer()});
        diagnostics_blob.release();
        diagnostics_blob = @ptrFromInt(0x8);
    } else if (log_diagnostics == .always) {
        log.err("{s}", .{diagnostics.?.*.getBuffer()});
    }
}

pub const Severity = enum(i32) {
    disabled = 0,
    note,
    warning,
    @"error",
    fatal,
    internal,
};

pub const DiagnosticFlags = packed struct(i32) {
    verbose_paths: bool = false,
    treat_warnings_as_errors: bool = false,
};

pub const BindableResourceType = enum(i32) {
    non_bindable = 0,
    texture,
    sampler,
    uniform_buffer,
    storage_buffer,
};

pub const CompileTarget = enum(i32) {
    unknown,
    none,
    glsl,
    glsl_vulkan_deprecated,
    glsl_vulkan_one_desc_deprecated,
    hlsl,
    spirv,
    spirv_asm,
    dxbc,
    dxbc_asm,
    dxil,
    dxil_asm,
    c_source,
    cpp_source,
    host_executable,
    shader_shared_library,
    shader_host_callable,
    cuda_source,
    ptx,
    cuda_object_code,
    object_code,
    host_cpp_source,
    host_host_callable,
    cpp_pytorch_bindings,
    metal,
    metal_lib,
    metal_lib_asm,
    host_shared_library,
    wgsl,
    wgsl_spirv_asm,
    wgsl_spirv,
    host_vm,
};

pub const ContainerFormat = enum(i32) {
    none = 0,
    slang_module,
};

pub const PassThrough = enum(i32) {
    none = 0,
    fxc,
    dxc,
    glslang,
    spirv_dis,
    clang,
    visual_studio,
    gcc,
    generic_c_cpp,
    nvrtc,
    llvm,
    spirv_opt,
    metal,
    tint,
    spirv_link,
};

pub const ArchiveType = enum(i32) {
    undefined = 0,
    zip,
    riff,
    riff_deflate,
    riff_lz4,
};

pub const CompileFlags = packed struct(u32) {
    _pad0: u3 = 0,
    no_mangling: bool = false,
    no_codegen: bool = false,
    obfuscate: bool = false,
};

pub const TargetFlags = packed struct(u32) {
    _pad0: u4 = 0,
    parameter_blocks_use_register_spaces: bool = false,
    _pad1: u3 = 0,
    generate_whole_program: bool = false,
    dump_ir: bool = false,
    generate_spirv_directly: bool = false,
    _pad2: u21 = 0,

    pub const default = CompileFlags{ .generate_spirv_directly = true };
};

pub const FloatingPointMode = enum(i32) {
    default = 0,
    fast,
    precise,
};

pub const FpDenormalMode = enum(u32) {
    any = 0,
    preserve,
    ftz,
};

pub const LineDirectiveMode = enum(i32) {
    default = 0,
    none,
    standard,
    glsl,
    source_map,
};

pub const SourceLanguage = enum(i32) {
    unknown = 0,
    slang,
    hlsl,
    glsl,
    c,
    cpp,
    cuda,
    spirv,
    metal,
    wgsl,
};

pub const ProfileID = enum(i32) {
    unknown = 0,
    _,
};

pub const CapabilityID = enum(i32) {
    unknown = 0,
    _,
};

pub const MatrixLayoutMode = enum(u32) {
    unknown = 0,
    row_major,
    column_major,
};

pub const Stage = enum(i32) {
    none = 0,
    vertex,
    hull,
    domain,
    geometry,
    fragment,
    compute,
    ray_generation,
    intersection,
    any_hit,
    closest_hit,
    miss,
    callable,
    mesh,
    amplification,
    dispatch,

    pub const pixel = Stage.fragment;
};

pub const DebugInfoLevel = enum(i32) {
    none = 0,
    minimal,
    standard,
    maximal,
};

pub const DebugInfoFormat = enum(i32) {
    default = 0,
    c7,
    pdb,
    stabs,
    coff,
    dwarf,
};

pub const OptimizationLevel = enum(i32) {
    none = 0,
    default,
    high,
    maximal,
};

pub const EmitSpirvMethod = enum(i32) {
    default = 0,
    via_glsl,
    directly,
};

pub const CompilerOptionName = enum(i32) {
    /// Macro name then macro value
    macro_define,
    dep_file,
    entry_point_name,
    specialize,
    help,
    help_style,
    include,
    language,
    matrix_layout_column,
    matrix_layout_row,
    zero_initialize,
    ignore_capabilities,
    restrictive_capability_check,
    module_name,
    output,
    profile,
    stage,
    target,
    version,
    /// "all" or comma separated list of warnings
    warnings_as_errors,
    /// Comma separated list of warning codes or names
    disable_warnings,
    /// Warning code or name
    enable_warning,
    /// Warning code or name
    disable_warning,
    dump_warning_diagnostics,
    input_files_remain,
    emit_ir,
    report_downstream_time,
    report_perf_benchmark,
    report_checkpoint_intermediates,
    skip_spirv_validation,
    source_embed_style,
    source_embed_name,
    source_embed_language,
    disable_short_circuit,
    minimum_slang_optimization,
    disable_non_essential_validations,
    disable_source_map,
    unscoped_enum,
    /// Preserve all resource parameters in the output code
    preserve_parameters,

    capability,
    default_image_format_unknown,
    disable_dynamic_dispatch,
    disable_specialization,
    floating_point_mode,
    debug_information,
    line_directive_mode,
    optimization,
    obfuscate,

    vulkan_bind_shift,
    vulkan_bind_globals,
    vulkan_invert_y,
    vulkan_use_dx_position_w,
    vulkan_use_entry_point_name,
    vulkan_use_gl_layout,
    vulkan_emit_reflection,

    glsl_force_scalar_layout,
    enable_effect_annotations,

    /// Will be deprecated
    emit_spirv_via_glsl,
    /// Will be deprecated
    emit_spirv_directly,
    /// Json path
    spirv_core_grammar_json,
    /// When set, will not issue an error when the linked program has unresolved extern function symbols
    incomplete_library,

    compiler_path,
    default_downstream_compiler,
    downstream_args,
    pass_through,

    dump_repro,
    dump_repro_on_error,
    extract_repro,
    load_repro,
    load_repro_directory,
    repro_fallback_directory,

    dump_ast,
    dump_intermediate_prefix,
    dump_intermediates,
    dump_ir,
    dump_ir_ids,
    preprocessor_output,
    output_includes,
    repro_file_system,
    serial_ir_deprecated_and_removed,
    skip_code_gen,
    validate_ir,
    verbose_paths,
    verify_debug_serial_ir,
    /// no_code_gen
    unused1,

    file_system,
    heterogeneous,
    no_mangle,
    no_hlsl_binding,
    no_hlsl_pack_constant_buffer_elements,
    validate_uniformity,
    allow_glsl,
    enable_experimental_passes,
    bindless_space_index,
    archive_type,
    compile_core_module,
    doc,

    /// Deprecated
    ir_compression,
    load_core_module,
    reference_module,
    save_core_module,
    save_core_module_bin_source,
    track_liveness,
    /// Enable loop inversion optimization
    loop_inversion,

    /// Deprecated
    parameter_blocks_use_register_spaces,
    language_version,
    /// Additional type conformance to link, in the format of
    /// "<TypeName>:<IInterfaceName>[=<sequentialId>]", for example "Impl:IFoo=3" or "Impl:IFoo"
    type_conformance,
    enable_experimental_dynamic_dispatch,
    emit_reflection_json,

    /// count_of_parsable_options
    unused2,

    // used in parsed options only.
    debug_information_format,
    vulkan_bind_shift_all,
    generate_whole_program,
    /// When set, will only load precompiled modules if it is up-to-date with its source
    use_up_to_date_binary_module,
    embed_downstream_ir,
    force_dx_layout,

    /// Add this new option to the end of the list to avoid breaking ABI as much as possible.
    /// Setting of emit_spirv_directly or emit_spirv_via_glsl will turn into this option internally
    emit_spirv_method,
    save_glsl_module_bin_source,
    skip_downstream_linking,
    dump_module,

    /// Print serialized module version and name
    get_module_info,
    /// Print the min and max module versions this compiler supports
    get_supported_module_versions,
    emit_separate_debug,

    denormal_mode_fp16,
    denormal_mode_fp32,
    denormal_mode_fp64,
    use_msvc_style_bitfield_packing,
    force_c_layout,
};

pub const CompilerOptionValueKind = enum(i32) {
    int,
    string,
};

pub const CompilerOptionValue = extern struct {
    kind: CompilerOptionValueKind = .int,
    int_value_0: i32 = 0,
    int_value_1: i32 = 0,
    string_value_0: ?[*:0]const u8 = null,
    string_value_1: ?[*:0]const u8 = null,
};

pub const CompilerOptionEntry = extern struct {
    name: CompilerOptionName,
    value: CompilerOptionValue,

    pub const matrix_layout_column = makeBoolConstructor(.matrix_layout_column);
    pub const matrix_layout_row = makeBoolConstructor(.matrix_layout_row);
    pub const zero_initialize = makeBoolConstructor(.zero_initialize);
    pub const ignore_capabilities = makeBoolConstructor(.ignore_capabilities);
    pub const restrictive_capability_check = makeBoolConstructor(.restrictive_capability_check);
    pub const emit_ir = makeBoolConstructor(.emit_ir);
    pub const report_downstream_time = makeBoolConstructor(.report_downstream_time);
    pub const report_perf_benchmark = makeBoolConstructor(.report_perf_benchmark);
    pub const report_checkpoint_intermediates = makeBoolConstructor(.report_checkpoint_intermediates);
    pub const skip_spirv_validation = makeBoolConstructor(.skip_spirv_validation);
    pub const disable_short_circuit = makeBoolConstructor(.disable_short_circuit);
    pub const minimum_slang_optimization = makeBoolConstructor(.minimum_slang_optimization);
    pub const disable_non_essential_validations = makeBoolConstructor(.disable_non_essential_validations);
    pub const disable_source_map = makeBoolConstructor(.disable_source_map);
    pub const unscoped_enum = makeBoolConstructor(.unscoped_enum);
    pub const preserve_parameters = makeBoolConstructor(.preserve_parameters);
    pub const default_image_format_unknown = makeBoolConstructor(.default_image_format_unknown);
    pub const disable_dynamic_dispatch = makeBoolConstructor(.disable_dynamic_dispatch);
    pub const disable_specialization = makeBoolConstructor(.disable_specialization);
    pub const obfuscate = makeBoolConstructor(.obfuscate);
    pub const vulkan_invert_y = makeBoolConstructor(.vulkan_invert_y);
    pub const vulkan_use_dx_position_w = makeBoolConstructor(.vulkan_use_dx_position_w);
    pub const vulkan_use_entry_point_name = makeBoolConstructor(.vulkan_use_entry_point_name);
    pub const vulkan_use_gl_layout = makeBoolConstructor(.vulkan_use_gl_layout);
    pub const vulkan_emit_reflection = makeBoolConstructor(.vulkan_emit_reflection);
    pub const glsl_force_scalar_layout = makeBoolConstructor(.glsl_force_scalar_layout);
    pub const enable_effect_annotations = makeBoolConstructor(.enable_effect_annotations);
    pub const emit_spirv_via_glsl = makeBoolConstructor(.emit_spirv_via_glsl);
    pub const emit_spirv_directly = makeBoolConstructor(.emit_spirv_directly);
    pub const incomplete_library = makeBoolConstructor(.incomplete_library);
    pub const dump_intermediates = makeBoolConstructor(.dump_intermediates);
    pub const dump_ir = makeBoolConstructor(.dump_ir);
    pub const skip_code_gen = makeBoolConstructor(.skip_code_gen);
    pub const validate_ir = makeBoolConstructor(.validate_ir);
    pub const loop_inversion = makeBoolConstructor(.loop_inversion);
    pub const enable_experimental_dynamic_dispatch = makeBoolConstructor(.enable_experimental_dynamic_dispatch);
    pub const emit_reflection_json = makeBoolConstructor(.emit_reflection_json);
    pub const generate_whole_program = makeBoolConstructor(.generate_whole_program);
    pub const use_up_to_date_binary_module = makeBoolConstructor(.use_up_to_date_binary_module);
    pub const embed_downstream_ir = makeBoolConstructor(.embed_downstream_ir);
    pub const force_dx_layout = makeBoolConstructor(.force_dx_layout);
    pub const skip_downstream_linking = makeBoolConstructor(.skip_downstream_linking);
    pub const use_msvc_style_bitfield_packing = makeBoolConstructor(.use_msvc_style_bitfield_packing);
    pub const emit_separate_debug = makeBoolConstructor(.emit_separate_debug);
    pub const force_c_layout = makeBoolConstructor(.force_c_layout);

    pub const include = makeStringConstructor(.include);
    pub const module_name = makeStringConstructor(.module_name);
    pub const warnings_as_errors = makeStringConstructor(.warnings_as_errors);
    pub const disable_warnings = makeStringConstructor(.disable_warnings);
    pub const enable_warning = makeStringConstructor(.enable_warning);
    pub const disable_warning = makeStringConstructor(.disable_warning);
    pub const spirv_core_grammar_json = makeStringConstructor(.spirv_core_grammar_json);
    pub const type_conformance = makeStringConstructor(.type_conformance);

    pub const profile = makeEnumConstructor(.profile, ProfileID);
    pub const stage = makeEnumConstructor(.stage, Stage);
    pub const target = makeEnumConstructor(.target, CompileTarget);
    pub const capability = makeEnumConstructor(.capability, CapabilityID);
    pub const floating_point_mode = makeEnumConstructor(.floating_point_mode, FloatingPointMode);
    pub const debug_information = makeEnumConstructor(.debug_information, DebugInfoLevel);
    pub const line_directive_mode = makeEnumConstructor(.line_directive_mode, LineDirectiveMode);
    pub const optimization = makeEnumConstructor(.optimization, OptimizationLevel);
    pub const language_version = makeEnumConstructor(.language_version, LanguageVersion);
    pub const debug_information_format = makeEnumConstructor(.debug_information_format, DebugInfoFormat);
    pub const emit_spirv_method = makeEnumConstructor(.emit_spirv_method, EmitSpirvMethod);
    // TODO: surely the rest of options must also have types

    pub fn macro_define(name: [*:0]const u8, value: [*:0]const u8) CompilerOptionEntry {
        return CompilerOptionEntry{
            .name = .macro_define,
            .value = .{ .kind = .string, .string_value_0 = name, .string_value_1 = value },
        };
    }

    pub fn downstream_arg(downstream_compiler_name: [*:0]const u8, argument_list: [*:0]const u8) CompilerOptionEntry {
        return CompilerOptionEntry{
            .name = .downstream_args,
            .value = .{ .kind = .string, .string_value_0 = downstream_compiler_name, .string_value_1 = argument_list },
        };
    }

    pub fn vulkan_bind_shift(set: u24, kind: u8, shift: u32) CompilerOptionEntry {
        const value0 = @as(u32, @intCast(set)) | @as(u32, @intCast(kind)) << 24;
        return CompilerOptionEntry{
            .name = .vulkan_bind_shift,
            .value = .{ .kind = .int, .int_value_0 = @intCast(value0), .int_value_1 = @intCast(shift) },
        };
    }

    pub fn vulkan_bind_globals(index: u32, set: u32) CompilerOptionEntry {
        return CompilerOptionEntry{
            .name = .vulkan_bind_globals,
            .value = .{ .kind = .int, .int_value_0 = @intCast(index), .int_value_1 = @intCast(set) },
        };
    }

    pub fn vulkan_bind_shift_all(index: u32, shift: u32) CompilerOptionEntry {
        return CompilerOptionEntry{
            .name = .vulkan_bind_shift_all,
            .value = .{ .kind = .int, .int_value_0 = @intCast(index), .int_value_1 = @intCast(shift) },
        };
    }

    fn makeBoolConstructor(comptime name: CompilerOptionName) fn (bool) CompilerOptionEntry {
        return struct {
            fn constructor(arg: bool) CompilerOptionEntry {
                return CompilerOptionEntry{ .name = name, .value = .{ .kind = .int, .int_value_0 = @intFromBool(arg) } };
            }
        }.constructor;
    }

    fn makeEnumConstructor(comptime name: CompilerOptionName, comptime T: type) fn (T) CompilerOptionEntry {
        return struct {
            fn constructor(arg: T) CompilerOptionEntry {
                return CompilerOptionEntry{ .name = name, .value = .{ .kind = .int, .int_value_0 = @intFromEnum(arg) } };
            }
        }.constructor;
    }

    fn makeStringConstructor(comptime name: CompilerOptionName) fn ([*:0]const u8) CompilerOptionEntry {
        return struct {
            fn constructor(arg: [*:0]const u8) CompilerOptionEntry {
                return CompilerOptionEntry{ .name = name, .value = .{ .kind = .string, .string_value_0 = arg } };
            }
        }.constructor;
    }
};

/// A result code for a Slang API operation.
///
/// This type is generally compatible with the Windows API `HRESULT` type. In particular, negative
/// values indicate failure results, while zero or positive results indicate success.
///
/// In general, Slang APIs always return a zero result on success, unless documented otherwise.
/// Strictly speaking a negative value indicates an error, a positive (or 0) value indicates
/// success. This can be tested for with the macros SLANG_SUCCEEDED(x) or SLANG_FAILED(x).
///
/// It can represent if the call was successful or not. It can also specify in an extensible manner
/// what facility produced the result (as the integral 'facility') as well as what caused it (as an
/// integral 'code'). Under the covers SlangResult is represented as a int32_t.
///
/// SlangResult is designed to be compatible with COM HRESULT.
///
/// It's layout in bits is as follows
///
/// Severity | Facility | Code
/// ---------|----------|-----
/// 31       |    30-16 | 15-0
///
/// Severity - 1 fail, 0 is success - as SlangResult is signed 32 bits, means negative number
/// indicates failure. Facility is where the error originated from. Code is the code specific to the
/// facility.
///
/// Result codes have the following styles,
/// 1) SLANG_name
/// 2) SLANG_s_f_name
/// 3) SLANG_s_name
///
/// where s is S for success, E for error
/// f is the short version of the facility name
///
/// Style 1 is reserved for SLANG_OK and SLANG_FAIL as they are so commonly used.
///
/// It is acceptable to expand 'f' to a longer name to differentiate a name or drop if unique
/// without it. ie for a facility 'DRIVER' it might make sense to have an error of the form
/// SLANG_E_DRIVER_OUT_OF_MEMORY
pub const Result = enum(i32) {
    ok = 0,
    fail = makeError(facility_win_general, 0x4005),
    not_implemented = makeError(facility_win_general, 0x4001),
    no_interface = makeError(facility_win_general, 0x4002),
    aborted = makeError(facility_win_general, 0x4004),

    invalid_handle = makeError(facility_win_api, 6),
    invalid_arg = makeError(facility_win_api, 0x57),
    out_of_memory = makeError(facility_win_api, 0xe),

    buffer_too_small = makeError(facility_core, 1),
    uninitialized,
    pending,
    cannot_open,
    not_found,
    internal_fail,
    not_available,
    time_out,
    _,

    /// Facilities compatible with windows COM - only use if known code is compatible
    pub const facility_win_general = 0x0;
    pub const facility_win_interface = 0x4;
    pub const facility_win_api = 0x7;
    /// Base facility -> so as to not clash with HRESULT values (values in 0x200 range do not
    /// appear used)
    pub const facility_base = 0x200;
    /// Facilities numbers must be unique across a project to make the resulting result a unique
    /// number. It can be useful to have a consistent short name for a facility, as used in the
    /// name prefix.
    pub const facility_core = facility_base;
    /// Facility for codes, that are not uniquely defined/protected. Can be used to pass back a
    /// specific error without requiring system wide facility uniqueness. Codes should never be
    /// part of a public API.
    pub const facility_internal = facility_base + 1;
    /// Base for external facilities. Facilities should be unique across modules.
    pub const facility_external_base = 0x210;

    pub fn makeError(facility: u15, code: u16) i32 {
        return @bitCast(@as(u32, @intCast(facility)) << 16 | @as(u32, @intCast(code)) | 0x80000000);
    }

    /// Use to test if a result was failure. Never use result != SLANG_OK to test for failure, as
    /// there may be successful codes != SLANG_OK.
    pub fn failed(self: Result) bool {
        return @intFromEnum(self) < 0;
    }

    /// Use to test if a result succeeded. Never use result == SLANG_OK to test for success, as will
    /// detect other successful codes as a failure.
    pub fn succedded(self: Result) bool {
        return @intFromEnum(self) >= 0;
    }

    pub fn getFacility(self: Result) u15 {
        return @intFromEnum(self) >> 16 & 0x7fff;
    }

    pub fn getCode(self: Result) u16 {
        return @intFromEnum(self) & 0xffff;
    }

    pub fn check(self: Result) Error!void {
        switch (self) {
            .not_implemented => return error.NotImplemented,
            .no_interface => return error.NoInterface,
            .aborted => return error.Aborted,
            .invalid_handle => return error.InvalidHandle,
            .invalid_arg => return error.InvalidArg,
            .out_of_memory => return error.OutOfMemory,
            .buffer_too_small => return error.BufferTooSmall,
            .uninitialized => return error.Uninitialized,
            .pending => return error.Pending,
            .cannot_open => return error.CannotOpen,
            .not_found => return error.NotFound,
            .internal_fail => return error.InternalFail,
            .not_available => return error.NotAvailable,
            .time_out => return error.TimeOut,
            else => if (self.failed()) return error.GenericFailure,
        }
    }
};

pub const Error = error{
    GenericFailure,
    NotImplemented,
    NoInterface,
    Aborted,
    InvalidHandle,
    InvalidArg,
    OutOfMemory,
    BufferTooSmall,
    /// Used to identify a Result that has yet to be initialized.
    /// It defaults to failure such that if used incorrectly will fail, as similar in concept to
    /// using an uninitialized variable.
    Uninitialized,
    /// Returned from an async method meaning the output is invalid (thus an error), but a result
    /// for the request is pending, and will be returned on a subsequent call with the async handle.
    /// TODO: Find all the async methods and make them return `Error!?*Foo` and remove this error code.
    Pending,
    CannotOpen,
    NotFound,
    InternalFail,
    NotAvailable,
    TimeOut,
};

pub const UUID = extern struct {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [8]u8,

    pub fn init(a: u32, b: u16, c: u16, d: [8]u8) UUID {
        return UUID{ .data1 = a, .data2 = b, .data3 = c, .data4 = d };
    }
};

const mcall: std.builtin.CallingConvention = if (builtin.os.tag == .windows) .winapi else .c;

pub const IUnknown = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x00000000, 0x0000, 0x0000, .{ 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;

    const VTable = extern struct {
        queryInterface: *const fn (this: *IUnknown, uuid_: *const UUID, out_object: **anyopaque) callconv(mcall) Result,
        addRef: *const fn (this: *IUnknown) callconv(mcall) u32,
        release: *const fn (this: *IUnknown) callconv(mcall) u32,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn queryInterface(self: *T, uuid_: *const UUID, out_object: **anyopaque) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.queryInterface(@ptrCast(self), uuid_, out_object).check();
            }

            fn addRef(self: *T) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                _ = vtable.addRef(@ptrCast(self));
            }

            fn release(self: *T) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                _ = vtable.release(@ptrCast(self));
            }
        };
    }
};

pub const ICastable = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x87ede0e1, 0x4852, 0x44b0, .{ 0x8b, 0xf2, 0xcb, 0x31, 0x87, 0x4d, 0xe2, 0x39 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;

    const VTable = extern struct {
        base: IUnknown.VTable,
        castAs: *const fn (this: *ICastable, guid: *const UUID) callconv(mcall) ?*anyopaque,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            // NOTE: I have no idea how or even if you would use this, so maybe you don't want to be
            // restricted to only types with uuid constants
            fn castAs(self: *T, comptime U: type) *U {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return @ptrCast(@alignCast(vtable.castAs(@ptrCast(self), U.uuid)));
            }
        };
    }
};

pub const IClonable = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x1ec36168, 0xe9f4, 0x430d, .{ 0xbb, 0x17, 0x4, 0x8a, 0x80, 0x46, 0xb3, 0x1f });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;
    pub const clone = IClonable.Mixin(@This()).clone;

    const VTable = extern struct {
        base: ICastable.VTable,
        clone: *const fn (this: *IClonable, guid: *const UUID) callconv(mcall) ?*anyopaque,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn clone(self: *T, guid: *const UUID) ?*anyopaque {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.clone(@ptrCast(self), guid);
            }
        };
    }
};

pub const IBlob = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x8BA5FB08, 0x5195, 0x40e2, .{ 0xAC, 0x58, 0x0D, 0x98, 0x9C, 0x3A, 0x01, 0x02 });
    pub const init = &default_instance;

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const getBuffer = IBlob.Mixin(@This()).getBuffer;
    pub const getBufferSize = IBlob.Mixin(@This()).getBufferSize;

    const VTable = extern struct {
        base: IUnknown.VTable,
        getBufferPointer: *const fn (this: *IBlob) callconv(mcall) ?[*]const u8,
        getBufferSize: *const fn (this: *IBlob) callconv(mcall) usize,
    };

    var default_instance = IBlob{ .vtable = @ptrCast(&default_vtable) };
    const default_vtable = DefaultVTable{};

    /// The only valid operation to do on a uninitialized COM object is to defer releasing it, resulting
    /// in a noop. Trying to call any other function will result in an immediate segfault.
    const DefaultVTable = extern struct {
        _pad0: [2]usize = @splat(0),
        release: *const fn (*IUnknown) callconv(mcall) u32 = &defaultRelease,
        _pad1: [29]usize = @splat(0),

        fn defaultRelease(self: *IUnknown) callconv(mcall) u32 {
            _ = self;
            return 1;
        }
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getBuffer(self: *T) []const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                const ptr = vtable.getBufferPointer(@ptrCast(self));
                if (ptr == null) {
                    return &.{};
                }
                const len = vtable.getBufferSize(@ptrCast(self));
                return ptr.?[0..len];
            }

            fn getBufferSize(self: *T) usize {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getBufferSize(@ptrCast(self));
            }
        };
    }
};

/// Can be requested from ICastable cast to indicate the contained chars are null terminated.
pub const TerminatedChars = extern struct {
    chars: [1]u8,

    pub const uuid = UUID.init(0xbe0db1a8, 0x3594, 0x4603, .{ 0xa7, 0x8b, 0xc4, 0x86, 0x84, 0x30, 0xdf, 0xbb });
};

pub const IFileSystem = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x003A09FC, 0x3A4D, 0x4BA0, .{ 0xAD, 0x60, 0x1F, 0xD8, 0x63, 0xA9, 0x15, 0xAB });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;
    pub const loadFile = IFileSystem.Mixin(@This()).loadFile;

    const VTable = extern struct {
        base: ICastable.VTable,
        loadFile: *const fn (this: *IFileSystem, path: [*:0]const u8, oub_blob: **IBlob) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn loadFile(self: *T, path: [:0]const u8) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var blob: *IBlob = undefined;
                try vtable.loadFile(@ptrCast(self), path.ptr, &blob).check();
                return blob;
            }
        };
    }
};

pub const FuncPtr = *const fn () callconv(.c) void;

pub const ISharedLibrary = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x70dbc7c3, 0xdc3b, 0x4a07, .{ 0xae, 0x7e, 0x75, 0x2a, 0xf6, 0xa8, 0x15, 0x55 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;
    pub const findSymbolAddressByName = ISharedLibrary.Mixin(@This()).findSymbolAddressByName;
    pub const findFuncByName = ISharedLibrary.Mixin(@This()).findFuncByName;

    const VTable = extern struct {
        base: ICastable.VTable,
        findSymbolAddressByName: *const fn (self: *ISharedLibrary, name: [*:0]const u8) callconv(mcall) ?*const anyopaque,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn findSymbolAddressByName(self: *T, name: [:0]const u8) ?*const anyopaque {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.findSymbolAddressByName(@ptrCast(self), name.ptr);
            }

            fn findFuncByName(self: *T, name: [:0]const u8) ?FuncPtr {
                return @ptrCast(self.findSymbolAddressByName(name) orelse return null);
            }
        };
    }
};

pub const ISharedLibraryLoader = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x6264ab2b, 0xa3e8, 0x4a06, .{ 0x97, 0xf1, 0x49, 0xbc, 0x2d, 0x2a, 0xb1, 0x4d });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const loadSharedLibrary = ISharedLibraryLoader.Mixin(@This()).loadSharedLibrary;

    const VTable = extern struct {
        base: IUnknown.VTable,
        loadSharedLibrary: *const fn (this: *ISharedLibraryLoader, path: [*:0]const u8, out_shared_library: **ISharedLibrary) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn loadSharedLibrary(self: *T, path: [:0]const u8) !*ISharedLibrary {
                var result: *ISharedLibrary = undefined;
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.loadSharedLibrary(@ptrCast(self), path.ptr, &result).check();
                return result;
            }
        };
    }
};

pub const PathType = enum(u32) {
    directory,
    file,
};

pub const FileSystemContentsCallback = *const fn (path_type: PathType, name: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void;

pub const OSPathKind = enum(u8) {
    none = 0,
    direct,
    operating_system,
};

pub const PathKind = enum(i32) {
    simplified,
    canonical,
    display,
    operating_system,
};

pub const IFileSystemExt = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x5fb632d2, 0x979d, 0x4481, .{ 0x9f, 0xee, 0x66, 0x3c, 0x3f, 0x14, 0x49, 0xe1 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;
    pub const findSymbolAddressByName = ISharedLibrary.Mixin(@This()).findSymbolAddressByName;
    pub const findFuncByName = ISharedLibrary.Mixin(@This()).findFuncByName;
    pub const getFileUniqueIdentity = IFileSystemExt.Mixin(@This()).getFileUniqueIdentity;
    pub const calcCombinedPath = IFileSystemExt.Mixin(@This()).calcCombinedPath;
    pub const getPathType = IFileSystemExt.Mixin(@This()).getPathType;
    pub const getPath = IFileSystemExt.Mixin(@This()).getPath;
    pub const clearCache = IFileSystemExt.Mixin(@This()).clearCache;
    pub const enumeratePathContents = IFileSystemExt.Mixin(@This()).enumeratePathContents;
    pub const getOSPathKind = IFileSystemExt.Mixin(@This()).getOSPathKind;

    const VTable = extern struct {
        base: IFileSystem.VTable,
        getFileUniqueIdentity: *const fn (this: *IFileSystemExt, path: [*:0]const u8, out_unhique_identity: **IBlob) callconv(mcall) Result,
        calcCombinedPath: *const fn (this: *IFileSystemExt, from_path_type: PathType, from_path: [*:0]const u8, path: [*:0]const u8, out_path: **IBlob) callconv(mcall) Result,
        getPathType: *const fn (this: *IFileSystemExt, path: [*:0]const u8, out_path_type: *PathType) callconv(mcall) Result,
        getPath: *const fn (this: *IFileSystemExt, kind: PathKind, path: [*:0]const u8, out_path: **IBlob) callconv(mcall) Result,
        clearCache: *const fn (this: *IFileSystemExt) callconv(mcall) void,
        enumeratePathContents: *const fn (this: *IFileSystemExt, path: [*:0]const u8, callback: FileSystemContentsCallback, user_data: ?*anyopaque) callconv(mcall) Result,
        getOSPathKind: *const fn (this: *IFileSystemExt) callconv(mcall) OSPathKind,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getFileUniqueIdentity(self: *T, path: [:0]const u8) !*IBlob {
                var result: *IBlob = undefined;
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.getFileUniqueIdentity(@ptrCast(self), path.ptr, &result).check();
                return result;
            }

            fn calcCombinedPath(self: *T, from_path: [:0]const u8, path: [:0]const u8) !*IBlob {
                var result: *IBlob = undefined;
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.calcCombinedPath(@ptrCast(self), from_path.ptr, path.ptr, &result).check();
                return result;
            }

            fn getPathType(self: *T, path: [:0]const u8) !PathType {
                var result: PathType = undefined;
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.getPathType(@ptrCast(self), path.ptr, &result).check();
                return result;
            }

            fn getPath(self: *T, kind: PathKind, path: [:0]const u8) !*IBlob {
                var result: *IBlob = undefined;
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.getPath(@ptrCast(self), kind, path.ptr, &result).check();
                return result;
            }

            fn clearCache(self: *T) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.clearCache(@ptrCast(self));
            }

            fn enumeratePathContents(self: *T, path: [:0]const u8, callback: FileSystemContentsCallback, user_data: ?*anyopaque) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.enumeratePathContents(@ptrCast(self), path.ptr, callback, user_data).check();
            }

            fn getOSPathKind(self: *T) OSPathKind {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getOSPathKind(@ptrCast(self));
            }
        };
    }
};

pub const IMutableFileSystem = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0xa058675c, 0x1d65, 0x452a, .{ 0x84, 0x58, 0xcc, 0xde, 0xd1, 0x42, 0x71, 0x5 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;
    pub const findSymbolAddressByName = ISharedLibrary.Mixin(@This()).findSymbolAddressByName;
    pub const findFuncByName = ISharedLibrary.Mixin(@This()).findFuncByName;
    pub const getFileUniqueIdentity = IFileSystemExt.Mixin(@This()).getFileUniqueIdentity;
    pub const calcCombinedPath = IFileSystemExt.Mixin(@This()).calcCombinedPath;
    pub const getPathType = IFileSystemExt.Mixin(@This()).getPathType;
    pub const getPath = IFileSystemExt.Mixin(@This()).getPath;
    pub const clearCache = IFileSystemExt.Mixin(@This()).clearCache;
    pub const enumeratePathContents = IFileSystemExt.Mixin(@This()).enumeratePathContents;
    pub const getOSPathKind = IFileSystemExt.Mixin(@This()).getOSPathKind;
    pub const saveFile = IMutableFileSystem.Mixin(@This()).saveFile;
    pub const saveFileBlob = IMutableFileSystem.Mixin(@This()).saveFileBlob;
    pub const remove = IMutableFileSystem.Mixin(@This()).remove;
    pub const createDirectory = IMutableFileSystem.Mixin(@This()).createDirectory;

    const VTable = extern struct {
        base: IFileSystemExt.VTable,
        saveFile: *const fn (this: *IMutableFileSystem, path: [*:0]const u8, data: [*]const u8, size: usize) callconv(mcall) Result,
        saveFileBlob: *const fn (this: *IMutableFileSystem, path: [*:0]const u8, data_blob: *IBlob) callconv(mcall) Result,
        remove: *const fn (this: *IMutableFileSystem, path: [*:0]const u8) callconv(mcall) Result,
        createDirectory: *const fn (this: *IMutableFileSystem, path: [*:0]const u8) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn saveFile(self: *T, path: [:0]const u8, data: []const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.saveFile(@ptrCast(self), path.ptr, data.ptr, data.len).check();
            }

            fn saveFileBlob(self: *T, path: [:0]const u8, data: *IBlob) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.saveFileBlob(@ptrCast(self), path.ptr, data).check();
            }

            fn remove(self: *T, path: [:0]const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.remove(@ptrCast(self), path.ptr).check();
            }

            fn createDirectory(self: *T, path: [:0]const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.createDirectory(@ptrCast(self), path.ptr).check();
            }
        };
    }
};

pub const WriterChannel = enum(u32) {
    diagnostic,
    std_output,
    std_error,
};

pub const WriterMode = enum(u32) {
    text,
    binary,
};

pub const IWriter = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0xec457f0e, 0x9add, 0x4e6b, .{ 0x85, 0x1c, 0xd7, 0xfa, 0x71, 0x6d, 0x15, 0xfd });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const beginAppendBuffer = IWriter.Mixin(@This()).beginAppendBuffer;
    pub const endAppendBuffer = IWriter.Mixin(@This()).endAppendBuffer;
    pub const write = IWriter.Mixin(@This()).write;
    pub const flush = IWriter.Mixin(@This()).flush;
    pub const isConsole = IWriter.Mixin(@This()).isConsole;
    pub const setMode = IWriter.Mixin(@This()).setMode;

    const VTable = extern struct {
        base: IUnknown.VTable,
        beginAppendBuffer: *const fn (this: *IWriter, max_num_chars: usize) callconv(mcall) ?[*]u8,
        endAppendBuffer: *const fn (this: *IWriter, buffer: [*]const u8, num_chars: usize) callconv(mcall) Result,
        write: *const fn (this: *IWriter, chars: [*]const u8, num_chars: usize) callconv(mcall) Result,
        flush: *const fn (this: *IWriter) callconv(mcall) void,
        isConsole: *const fn (this: *IWriter) callconv(mcall) bool,
        setMode: *const fn (this: *IWriter, mode: WriterMode) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn beginAppendBuffer(self: *T, max_size: usize) []u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.beginAppendBuffer(@ptrCast(self), max_size).?[0..max_size];
            }

            fn endAppendBuffer(self: *T, buffer: []const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.endAppendBuffer(@ptrCast(self), buffer.ptr, buffer.len);
            }

            fn write(self: *T, chars: []const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.write(@ptrCast(self), chars.ptr, chars.len);
            }

            fn flush(self: *T) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.flush(@ptrCast(self));
            }

            fn isConsole(self: *T) bool {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.isConsole(@ptrCast(self));
            }

            fn setMode(self: *T, mode: WriterMode) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.setMode(@ptrCast(self), mode);
            }
        };
    }
};

pub const IProfiler = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x197772c7, 0x0155, 0x4b91, .{ 0x84, 0xe8, 0x66, 0x68, 0xba, 0xff, 0x06, 0x19 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const getEntryCount = IProfiler.Mixin(@This()).getEntryCount;
    pub const getEntryName = IProfiler.Mixin(@This()).getEntryName;
    pub const getEntryTimeMS = IProfiler.Mixin(@This()).getEntryTimeMS;
    pub const getEntryInvocationTimes = IProfiler.Mixin(@This()).getEntryInvocationTimes;

    const VTable = extern struct {
        base: IUnknown.VTable,
        getEntryCount: *const fn (this: *IProfiler) callconv(mcall) usize,
        getEntryName: *const fn (this: *IProfiler, index: u32) callconv(mcall) [*:0]const u8,
        getEntryTimeMS: *const fn (this: *IProfiler, index: u32) callconv(mcall) c_long,
        getEntryInvocationTimes: *const fn (this: *IProfiler, index: u32) callconv(mcall) u32,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getEntryCount(self: *T) usize {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getEntryCount(@ptrCast(self));
            }

            fn getEntryName(self: *T, index: u32) [*:0]const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getEntryName(@ptrCast(self), index);
            }

            fn getEntryTimeMS(self: *T, index: u32) c_long {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getEntryTimeMS(@ptrCast(self), index);
            }

            fn getEntryInvocationTimes(self: *T, index: u32) u32 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getEntryInvocationTimes(@ptrCast(self), index);
            }
        };
    }
};

/// Deprecated
pub const ICompileRequest = extern struct {
    vtable: *const anyopaque,
};

pub const DiagnosticsCallback = *const fn (message: [*:0]const u8, user_data: ?*anyopaque) callconv(.c) void;

/// Get the build version 'tag' string. The string is the same as
/// Produced via `git describe --tags --match v*` for the project. If such a
/// Version could not be determined at build time then the contents will be
/// 0.0.0-unknown. Any string can be set by passing
/// -DSLANG_VERSION_FULL=whatever during the cmake invocation.
///
/// This function will return exactly the same result as the method
/// GetBuildTagString on IGlobalSession.
///
/// An advantage of using this function over the method is that doing so does
/// Not require the creation of a session, which can be a fairly costly
/// Operation.
pub const getBuildTagString = spGetBuildTagString;

extern fn spGetBuildTagString() [*:0]const u8;

// TODO:
pub const ReflectionType = opaque {};

pub const ReflectionGenericArg = extern union {
    type_val: *ReflectionType,
    int_val: i64,
    bool_val: bool,
};

pub const ReflectionGenericArgType = enum(i32) {
    type = 0,
    int = 1,
    bool = 2,
};

const TypeKind = enum(u32) {
    none = 0,
    @"struct",
    array,
    matrix,
    vector,
    scalar,
    constant_buffer,
    resource,
    sampler_state,
    texture_buffer,
    shader_storage_buffer,
    parameter_block,
    generic_type_parameter,
    interface,
    output_stream,
    mesh_output,
    specialized,
    feedback,
    pointer,
    dynamic_resource,
};

const ScalarType = enum(u32) {
    none = 0,
    void,
    bool,
    int32,
    uint32,
    int64,
    uint64,
    float16,
    float32,
    float64,
    int8,
    uint8,
    int16,
    uint16,
    intptr,
    uintptr,
};

const DeclKind = enum(u32) {
    unsupported_for_reflection = 0,
    @"struct",
    func,
    module,
    generic,
    variable,
    namespace,
};

// TODO: maybe this might be better as a packed struct or something. I don't yet know how its used
// in practice.
pub const ResourceShape = enum(u32) {
    none = 0,
    texture_1d,
    texture_2d,
    texture_3d,
    texture_cube,
    texture_buffer,

    structured_buffer,
    byte_address_buffer,
    resource_unknown,
    acceleration_structure,
    texture_subpass,

    texture_1d_array = 0x41,
    texture_2d_array = 0x42,
    texture_cube_array = 0x44,

    texture_2d_multisample = 0x82,
    texture_2d_multisample_array = 0xc2,
    texture_subpass_multisample = 0x8a,
};

pub const ResourceAccess = enum(u32) {
    none = 0,
    read,
    read_write,
    raster_ordered,
    append,
    consume,
    write,
    feedback,
    unknown = 0x7fffffff,
};

pub const ParameterCategory = enum(u32) {
    none = 0,
    mixed,
    constant_buffer,
    shader_resource,
    unordered_access,
    varying_input,
    varying_output,
    sampler_state,
    uniform,
    descriptor_table_slot,
    specialization_constant,
    push_constant_buffer,
    /// HLSL register `space`, Vulkan GLSL `set`
    register_space,
    /// A parameter whose type is to be specialized by a global generic type argument
    generic,
    ray_payload,
    hit_attributes,
    callable_payload,
    shader_record,
    /// An existential type parameter represents a "hole" that
    /// Needs to be filled with a concrete type to enable
    /// Generation of specialized code.
    ///
    /// Consider this example:
    ///
    ///      struct MyParams
    ///      {
    ///          IMaterial material;
    ///          ILight lights[3];
    ///      };
    ///
    /// This `MyParams` type introduces two existential type parameters:
    /// One for `material` and one for `lights`. Even though `lights`
    /// Is an array, it only introduces one type parameter, because
    /// We need to hae a *single* concrete type for all the array
    /// Elements to be able to generate specialized code.
    ///
    existential_type_param,
    /// An existential object parameter represents a value
    /// That needs to be passed in to provide data for some
    /// Interface-type shader paameter.
    ///
    /// Consider this example:
    ///
    ///      struct MyParams
    ///      {
    ///          IMaterial material;
    ///          ILight lights[3];
    ///      };
    ///
    /// This `MyParams` type introduces four existential object parameters:
    /// One for `material` and three for `lights` (one for each array
    /// Element). This is consistent with the number of interface-type
    /// "objects" that are being passed through to the shader.
    ///
    existential_object_param,
    /// The register space offset for the sub-elements that occupies register spaces.
    sub_element_register_space,
    /// The input_attachment_index subpass occupancy tracker
    subpass,
    /// Metal tier-1 argument buffer element [[id]].
    metal_argument_buffer_element,
    /// Metal [[attribute]] inputs.
    metal_attribute,
    /// Metal [[payload]] inputs
    metal_payload,

    pub const metal_buffer = ParameterCategory.constant_buffer;
    pub const metal_texture = ParameterCategory.shader_resource;
    pub const metal_sampler = ParameterCategory.sampler_state;
};

pub const BindingType = enum(u32) {
    unknown = 0,
    sampler,
    texture,
    constant_buffer,
    parameter_block,
    typed_buffer,
    raw_buffer,
    combined_texture_sampler,
    input_render_target,
    inline_uniform_data,
    ray_tracing_acceleration_structure,
    varying_input,
    varying_output,
    existential_value,
    push_constant,

    mutable_teture = 0x102,
    mutable_typed_buffer = 0x104,
    mutable_raw_buffer = 0x106,

    pub fn isMutable(self: BindingType) bool {
        return @intFromEnum(self) & mutable_flag != 0;
    }

    const mutable_flag = 0x100;
    const base_mask = 0x00ff;
    const ext_mask = 0xff00;
};

pub const LayoutRules = enum(u32) {
    default,
    metal_argument_buffer_tier_2,
};

pub const ModifierID = enum(u32) {
    shared,
    no_diff,
    static,
    @"const",
    @"export",
    @"extern",
    differentiable,
    mutating,
    in,
    out,
    inout,
};

pub const ImageFormat = enum(u32) {
    unknown = 0,
    rgba32f,
    rgba16f,
    rg32f,
    rg16f,
    r11f_g11f_b10f,
    r32f,
    r16f,
    rgba16,
    rgb10_a2,
    rgba8,
    rg16,
    rg8,
    r16,
    r8,
    rgba16_snorm,
    rgba8_snorm,
    rg16_snorm,
    rg8_snorm,
    r16_snorm,
    r8_snorm,
    rgba32i,
    rgba16i,
    rgba8i,
    rg32i,
    rg16i,
    rg8i,
    r32i,
    r16i,
    r8i,
    rgba32ui,
    rgba16ui,
    rgb10_a2ui,
    rgba8ui,
    rg32ui,
    rg16ui,
    rg8ui,
    r32ui,
    r16ui,
    r8ui,
    r64ui,
    r64i,
    bgra8,
};

const umbounded_size = std.math.maxInt(usize);

// =============================================================================
// TODO: reflection api, #include deprecated.h
// =============================================================================
const ProgramLayout = extern struct {
    _pad0: [1]u8,

    fn entryPointCount(self: ProgramLayout) u32 {
        _ = self;
        return 1;
    }

    fn parameterCount(self: ProgramLayout) u32 {
        _ = self;
        return 3;
    }
};

const FunctionReflection = extern struct {
    _pad0: [1]u8,
};

const DeclReflection = extern struct {
    _pad0: [1]u8,
};

const TypeReflection = extern struct {
    extern fn spReflectionType_GetKind(type: *TypeReflection) TypeKind;

    extern fn spReflectionType_GetFieldCount(type: *TypeReflection) u32;
};

const TypeLayoutReflection = extern struct {};
// =============================================================================

pub const CompileCoreModuleFlags = packed struct(u32) {
    write_documentation: bool = false,
    _pad0: u31 = 0,
};

pub const BuiltinModuleName = enum(i32) {
    core,
    glsl,
};

pub const GetCompilerElapsedTimeResult = struct {
    total_time: f64,
    downstream_time: f64,
};

pub const ParseCommandLineArgumentsResult = struct {
    session_desc: SessionDesc,
    aux_allocation: *IUnknown,
};

pub const IGlobalSession = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0xc140b5fd, 0xc78, 0x452e, .{ 0xba, 0x7c, 0x1a, 0x1e, 0x70, 0xc7, 0xf7, 0x1c });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const createSession = IGlobalSession.Mixin(@This()).createSession;
    pub const findProfile = IGlobalSession.Mixin(@This()).findProfile;
    pub const setDownstreamCompilerPath = IGlobalSession.Mixin(@This()).setDownstreamCompilerPath;
    pub const setDownstreamCompilerPrelude = IGlobalSession.Mixin(@This()).setDownstreamCompilerPrelude;
    pub const getDownstreamCompilerPrelude = IGlobalSession.Mixin(@This()).getDownstreamCompilerPrelude;
    pub const getBuildTagString = IGlobalSession.Mixin(@This()).getBuildTagString;
    pub const setDefaultDownstreamCompiler = IGlobalSession.Mixin(@This()).setDefaultDownstreamCompiler;
    pub const getDefaultDownstreamCompiler = IGlobalSession.Mixin(@This()).getDefaultDownstreamCompiler;
    pub const setLanguagePrelude = IGlobalSession.Mixin(@This()).setLanguagePrelude;
    pub const getLanguagePrelude = IGlobalSession.Mixin(@This()).getLanguagePrelude;
    pub const createCompileRequest = IGlobalSession.Mixin(@This()).createCompileRequest;
    pub const addBuiltins = IGlobalSession.Mixin(@This()).addBuiltins;
    pub const setSharedLibraryLoader = IGlobalSession.Mixin(@This()).setSharedLibraryLoader;
    pub const getSharedLibraryLoader = IGlobalSession.Mixin(@This()).getSharedLibraryLoader;
    pub const checkCompileTargetSupport = IGlobalSession.Mixin(@This()).checkCompileTargetSupport;
    pub const checkPassThroughSupport = IGlobalSession.Mixin(@This()).checkPassThroughSupport;
    pub const compileCoreModule = IGlobalSession.Mixin(@This()).compileCoreModule;
    pub const loadCoreModule = IGlobalSession.Mixin(@This()).loadCoreModule;
    pub const saveCoreModule = IGlobalSession.Mixin(@This()).saveCoreModule;
    pub const findCapability = IGlobalSession.Mixin(@This()).findCapability;
    pub const setDownstreamCompilerForTransition = IGlobalSession.Mixin(@This()).setDownstreamCompilerForTransition;
    pub const getDownstreamCompilerForTransition = IGlobalSession.Mixin(@This()).getDownstreamCompilerForTransition;
    pub const getCompilerElapsedTime = IGlobalSession.Mixin(@This()).getCompilerElapsedTime;
    pub const setSPIRVCoreGrammar = IGlobalSession.Mixin(@This()).setSPIRVCoreGrammar;
    pub const parseCommandLineArguments = IGlobalSession.Mixin(@This()).parseCommandLineArguments;
    pub const getSessionDescDigest = IGlobalSession.Mixin(@This()).getSessionDescDigest;
    pub const compileBuiltinModule = IGlobalSession.Mixin(@This()).compileBuiltinModule;
    pub const loadBuiltinModule = IGlobalSession.Mixin(@This()).loadBuiltinModule;
    pub const saveBuiltinModule = IGlobalSession.Mixin(@This()).saveBuiltinModule;

    const VTable = extern struct {
        base: IUnknown.VTable,
        createSession: *const fn (this: *IGlobalSession, desc: *const SessionDescExtern, out_session: **ISession) callconv(mcall) Result,
        findProfile: *const fn (this: *IGlobalSession, name: [*:0]const u8) callconv(mcall) ProfileID,
        setDownstreamCompilerPath: *const fn (this: *IGlobalSession, pass_through: PassThrough, path: [*:0]const u8) callconv(mcall) void,
        setDownstreamCompilerPrelude: *const fn (this: *IGlobalSession, pass_through: PassThrough, predule_text: [*:0]const u8) callconv(mcall) void,
        getDownstreamCompilerPrelude: *const fn (this: *IGlobalSession, pass_through: PassThrough, out_prelude: **IBlob) callconv(mcall) void,
        getBuildTagString: *const fn (this: *IGlobalSession) callconv(mcall) [*:0]const u8,
        setDefaultDownstreamCompiler: *const fn (this: *IGlobalSession, source_language: SourceLanguage, default_compiler: PassThrough) callconv(mcall) Result,
        getDefaultDownstreamCompiler: *const fn (this: *IGlobalSession, source_language: SourceLanguage) callconv(mcall) PassThrough,
        setLanguagePrelude: *const fn (this: *IGlobalSession, source_language: SourceLanguage, prelude_text: [*:0]const u8) callconv(mcall) void,
        getLanguagePrelude: *const fn (this: *IGlobalSession, source_language: SourceLanguage, out_prelude: **IBlob) callconv(mcall) void,
        /// Deprecated
        createCompileRequest: *const fn (this: *IGlobalSession, out_compiler_request: **ICompileRequest) callconv(mcall) Result,
        addBuiltins: *const fn (this: *IGlobalSession, source_path: [*:0]const u8, source_string: [*:0]const u8) callconv(mcall) void,
        setSharedLibraryLoader: *const fn (this: *IGlobalSession, loader: *ISharedLibraryLoader) callconv(mcall) void,
        getSharedLibraryLoader: *const fn (this: *IGlobalSession) callconv(mcall) *ISharedLibraryLoader,
        checkCompileTargetSupport: *const fn (this: *IGlobalSession, target: CompileTarget) callconv(mcall) Result,
        checkPassThroughSupport: *const fn (this: *IGlobalSession, pass_through: PassThrough) callconv(mcall) Result,
        compileCoreModule: *const fn (this: *IGlobalSession, flags: CompileCoreModuleFlags) callconv(mcall) Result,
        loadCoreModule: *const fn (this: *IGlobalSession, core_module: [*]const u8, core_module_size_in_bytes: usize) callconv(mcall) Result,
        saveCoreModule: *const fn (this: *IGlobalSession, archive_type: ArchiveType, out_blob: **IBlob) callconv(mcall) Result,
        findCapability: *const fn (this: *IGlobalSession, name: [*:0]const u8) callconv(mcall) CapabilityID,
        setDownstreamCompilerForTransition: *const fn (this: *IGlobalSession, source: CompileTarget, target: CompileTarget, compiler: PassThrough) callconv(mcall) void,
        getDownstreamCompilerForTransition: *const fn (this: *IGlobalSession, source: CompileTarget, target: CompileTarget) callconv(mcall) PassThrough,
        getCompilerElapsedTime: *const fn (this: *IGlobalSession, out_total_time: *f64, out_downstream_time: *f64) callconv(mcall) void,
        setSPIRVCoreGrammar: *const fn (this: *IGlobalSession, json_path: [*:0]const u8) callconv(mcall) Result,
        parseCommandLineArguments: *const fn (this: *IGlobalSession, argc: i32, argv: [*]const [*:0]const u8, out_session_desc: *SessionDescExtern, out_aux_allocation: **IUnknown) callconv(mcall) Result,
        getSessionDescDigest: *const fn (this: *IGlobalSession, session_desc: *SessionDescExtern, out_blob: **IBlob) callconv(mcall) Result,
        compileBuiltinModule: *const fn (this: *IGlobalSession, module: BuiltinModuleName, flags: CompileCoreModuleFlags) callconv(mcall) Result,
        loadBuiltinModule: *const fn (this: *IGlobalSession, module: BuiltinModuleName, module_data: [*]const u8, size_in_bytes: usize) callconv(mcall) Result,
        saveBuiltinModule: *const fn (this: *IGlobalSession, module: BuiltinModuleName, archive_type: ArchiveType, out_blob: **IBlob) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn createSession(self: *T, desc: SessionDesc) !*ISession {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var session: *ISession = undefined;
                try vtable.createSession(@ptrCast(self), &desc.toSlang(), &session).check();
                return session;
            }

            fn findProfile(self: *T, name: [*:0]const u8) ProfileID {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.findProfile(@ptrCast(self), name);
            }

            fn setDownstreamCompilerPath(self: *T, pass_through: PassThrough, path: [*:0]const u8) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.setDownstreamCompilerPath(@ptrCast(self), pass_through, path);
            }

            fn setDownstreamCompilerPrelude(self: *T, pass_through: PassThrough, predule_text: [*:0]const u8) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.setDownstreamCompilerPrelude(@ptrCast(self), pass_through, predule_text);
            }

            fn getDownstreamCompilerPrelude(self: *T, pass_through: PassThrough) *IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var prelude: *IBlob = undefined;
                vtable.getDownstreamCompilerPrelude(@ptrCast(self), pass_through, &prelude);
                return prelude;
            }

            fn getBuildTagString(self: *T) [*:0]const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getBuildTagString(@ptrCast(self));
            }

            fn setDefaultDownstreamCompiler(self: *T, source_language: SourceLanguage, default_compiler: PassThrough) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.setDefaultDownstreamCompiler(@ptrCast(self), source_language, default_compiler).check();
            }

            fn getDefaultDownstreamCompiler(self: *T, source_language: SourceLanguage) PassThrough {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getDefaultDownstreamCompiler(@ptrCast(self), source_language);
            }

            fn setLanguagePrelude(self: *T, source_language: SourceLanguage, prelude_text: [*:0]const u8) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.setLanguagePrelude(@ptrCast(self), source_language, prelude_text);
            }

            fn getLanguagePrelude(self: *T, source_language: SourceLanguage) *IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var prelude: *IBlob = undefined;
                vtable.getLanguagePrelude(@ptrCast(self), source_language, &prelude);
                return prelude;
            }

            /// Deprecated
            fn createCompileRequest(self: *IGlobalSession) callconv(mcall) !*ICompileRequest {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var compiler_request: *ICompileRequest = undefined;
                try vtable.createCompileRequest(@ptrCast(self), &compiler_request).check();
                return compiler_request;
            }

            fn addBuiltins(self: *T, source_path: [*:0]const u8, source_string: [*:0]const u8) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.addBuiltins(@ptrCast(self), source_path, source_string);
            }

            fn setSharedLibraryLoader(self: *T, loader: *ISharedLibraryLoader) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.setSharedLibraryLoader(@ptrCast(self), loader);
            }

            fn getSharedLibraryLoader(self: *T) *ISharedLibraryLoader {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getSharedLibraryLoader(@ptrCast(self));
            }

            fn checkCompileTargetSupport(self: *T, target: CompileTarget) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.checkCompileTargetSupport(@ptrCast(self), target).check();
            }

            fn checkPassThroughSupport(self: *T, pass_through: PassThrough) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.checkPassThroughSupport(@ptrCast(self), pass_through).check();
            }

            fn compileCoreModule(self: *T, flags: CompileCoreModuleFlags) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.compileCoreModule(@ptrCast(self), flags).check();
            }

            fn loadCoreModule(self: *T, core_module: []const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.loadCoreModule(@ptrCast(self), core_module.ptr, core_module.len).check();
            }

            fn saveCoreModule(self: *T, archive_type: ArchiveType) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var blob: *IBlob = undefined;
                try vtable.saveCoreModule(@ptrCast(self), archive_type, &blob).check();
                return blob;
            }

            fn findCapability(self: *T, name: [*:0]const u8) CapabilityID {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.findCapability(@ptrCast(self), name);
            }

            fn setDownstreamCompilerForTransition(self: *T, source: CompileTarget, target: CompileTarget, compiler: PassThrough) void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.setDownstreamCompilerForTransition(@ptrCast(self), source, target, compiler);
            }

            fn getDownstreamCompilerForTransition(self: *T, source: CompileTarget, target: CompileTarget) PassThrough {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getDownstreamCompilerForTransition(@ptrCast(self), source, target);
            }

            fn getCompilerElapsedTime(self: *T) GetCompilerElapsedTimeResult {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var result: GetCompilerElapsedTimeResult = undefined;
                vtable.getCompilerElapsedTime(@ptrCast(self), &result.total_time, &result.downstream_time);
                return result;
            }

            fn setSPIRVCoreGrammar(self: *T, json_path: [*:0]const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.setSPIRVCoreGrammar(@ptrCast(self), json_path).check();
            }

            fn parseCommandLineArguments(self: *T, args: []const [*:0]const u8) !ParseCommandLineArgumentsResult {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var aux_allocation: *IUnknown = undefined;
                var session_desc: SessionDescExtern = undefined;
                try vtable.parseCommandLineArguments(@ptrCast(self), @intCast(args.len), args.ptr, &session_desc, &aux_allocation).check();
                return .{
                    .aux_allocation = aux_allocation,
                    .session_desc = session_desc.fromSlang(),
                };
            }

            fn getSessionDescDigest(self: *T, session_desc: SessionDesc) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var blob: *IBlob = undefined;
                var desc = session_desc.toSlang();
                try vtable.getSessionDescDigest(@ptrCast(self), &desc, &blob).check();
                return blob;
            }

            fn compileBuiltinModule(self: *T, module: BuiltinModuleName, flags: CompileCoreModuleFlags) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.compileBuiltinModule(@ptrCast(self), module, flags).check();
            }

            fn loadBuiltinModule(self: *T, module: BuiltinModuleName, module_data: []const u8) Result {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.loadBuiltinModule(@ptrCast(self), module, module_data.ptr, module_data.len).check();
            }

            fn saveBuiltinModule(self: *T, module: BuiltinModuleName, archive_type: ArchiveType) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var blob: *IBlob = undefined;
                try vtable.saveBuiltinModule(@ptrCast(self), module, archive_type, &blob).check();
                return blob;
            }
        };
    }
};

pub const TargetDesc = extern struct {
    _structure_size: usize = @sizeOf(@This()),
    format: CompileTarget = .unknown,
    profile: ProfileID = .unknown,
    flags: TargetFlags = .{ .generate_spirv_directly = true },
    floating_point_mode: FloatingPointMode = .default,
    line_directive_mode: LineDirectiveMode = .default,
    force_glsl_scalar_buffer_layout: bool = false,
    /// NOTE: In C++ this is non-const, but then you can't assign a slice literal to it in Zig
    compiler_option_entries: ?[*]const CompilerOptionEntry = null,
    compiler_option_entry_count: u32 = 0,
};

pub const SessionFlags = enum(u32) {
    none = 0,
};

const PreprocessorMacroDesc = extern struct {
    name: [*:0]const u8,
    value: [*:0]const u8,
};

pub const SessionDesc = struct {
    targets: []const TargetDesc = &.{},
    flags: SessionFlags = .none,
    default_matrix_layout_mode: MatrixLayoutMode = .row_major,
    search_paths: []const [*:0]const u8 = &.{},
    preprpcessor_macros: []const PreprocessorMacroDesc = &.{},
    file_system: ?*IFileSystem = null,
    enable_effect_annotations: bool = false,
    allow_glsl_syntax: bool = false,
    compiler_option_entries: []const CompilerOptionEntry = &.{},
    skip_spirv_validation: bool = false,

    fn toSlang(self: SessionDesc) SessionDescExtern {
        for (self.targets, 0..) |desc, i| {
            if (desc.compiler_option_entries != null and desc.compiler_option_entry_count == 0) {
                std.log.err("Forgot to set 'TargetDesc.compiler_option_entry_count' at index {} in the 'SessionDesc.targets' array.", .{i});
            }
        }

        return SessionDescExtern{
            .targets = if (self.targets.len > 0) self.targets.ptr else null,
            .target_count = @intCast(self.targets.len),
            .flags = self.flags,
            .default_matrix_layout_mode = self.default_matrix_layout_mode,
            .search_paths = if (self.search_paths.len > 0) self.search_paths.ptr else null,
            .search_path_count = @intCast(self.search_paths.len),
            .preprpcessor_macros = if (self.preprpcessor_macros.len > 0) self.preprpcessor_macros.ptr else null,
            .preprocessor_macro_count = @intCast(self.preprpcessor_macros.len),
            .file_system = self.file_system,
            .enable_effect_annotations = self.enable_effect_annotations,
            .allow_glsl_syntax = self.allow_glsl_syntax,
            .compiler_options_entries = if (self.compiler_option_entries.len > 0) self.compiler_option_entries.ptr else null,
            .compiler_option_entry_count = @intCast(self.compiler_option_entries.len),
            .skip_spirv_validation = self.skip_spirv_validation,
        };
    }
};

const SessionDescExtern = extern struct {
    _structure_size: usize = @sizeOf(@This()),
    targets: ?[*]const TargetDesc = null,
    target_count: i64 = 0,
    flags: SessionFlags = .none,
    default_matrix_layout_mode: MatrixLayoutMode = .row_major,
    search_paths: ?[*]const [*:0]const u8 = null,
    search_path_count: i64 = 0,
    preprpcessor_macros: ?[*]const PreprocessorMacroDesc = null,
    preprocessor_macro_count: i64 = 0,
    file_system: ?*IFileSystem = null,
    enable_effect_annotations: bool = false,
    allow_glsl_syntax: bool = false,
    compiler_options_entries: ?[*]const CompilerOptionEntry = null,
    compiler_option_entry_count: u32 = 0,
    skip_spirv_validation: bool = false,

    fn fromSlang(self: SessionDescExtern) SessionDesc {
        return SessionDesc{
            .targets = if (self.targets != null) self.targets[0..@intCast(self.target_count)] else &.{},
            .flags = self.flags,
            .default_matrix_layout_mode = self.default_matrix_layout_mode,
            .search_paths = if (self.search_paths != null) self.search_paths[0..@intCast(self.search_path_count)] else &.{},
            .preprpcessor_macros = if (self.preprpcessor_macros != null) self.preprpcessor_macros[0..@intCast(self.preprocessor_macro_count)] else &.{},
            .file_system = self.file_system,
            .enable_effect_annotations = self.enable_effect_annotations,
            .allow_glsl_syntax = self.allow_glsl_syntax,
            .compiler_option_entries = if (self.compiler_options_entries != null) self.compiler_options_entries[0..@intCast(self.compiler_option_entry_count)] else &.{},
            .skip_spirv_validation = self.skip_spirv_validation,
        };
    }
};

const ContainerType = enum(i32) {
    none = 0,
    unsizedarray,
    structuredbuffer,
    constantbuffer,
    parameterblock,
};

pub const LoadModuleInfoFromIRBlobResult = struct {
    module_version: i64,
    module_name: [*:0]const u8,
    module_compiler_version: [*:0]const u8,
};

pub const ISession = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x67618701, 0xd116, 0x468f, .{ 0xab, 0x3b, 0x47, 0x4b, 0xed, 0xce, 0xe, 0x3d });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const getGlobalSession = ISession.Mixin(@This()).getGlobalSession;
    pub const loadModule = ISession.Mixin(@This()).loadModule;
    pub const loadModuleFromSourceBlob = ISession.Mixin(@This()).loadModuleFromSourceBlob;
    pub const createCompositeComponentType = ISession.Mixin(@This()).createCompositeComponentType;
    pub const specializeType = ISession.Mixin(@This()).specializeType;
    pub const getTypeLayout = ISession.Mixin(@This()).getTypeLayout;
    pub const getContainerType = ISession.Mixin(@This()).getContainerType;
    pub const getDynamicType = ISession.Mixin(@This()).getDynamicType;
    pub const getTypeRTTIMangledName = ISession.Mixin(@This()).getTypeRTTIMangledName;
    pub const getTypeConformanceWitnessMangledName = ISession.Mixin(@This()).getTypeConformanceWitnessMangledName;
    pub const getTypeConformanceWitnessSequentialID = ISession.Mixin(@This()).getTypeConformanceWitnessSequentialID;
    pub const createCompileRequest = ISession.Mixin(@This()).createCompileRequest;
    pub const createTypeConformanceComponentType = ISession.Mixin(@This()).createTypeConformanceComponentType;
    pub const loadModuleFromIRBlob = ISession.Mixin(@This()).loadModuleFromIRBlob;
    pub const getLoadedModuleCount = ISession.Mixin(@This()).getLoadedModuleCount;
    pub const getLoadedModule = ISession.Mixin(@This()).getLoadedModule;
    pub const isBinaryModuleUpToDate = ISession.Mixin(@This()).isBinaryModuleUpToDate;
    pub const loadModuleFromSourceString = ISession.Mixin(@This()).loadModuleFromSourceString;
    pub const getDynamicObjectRTTIBytes = ISession.Mixin(@This()).getDynamicObjectRTTIBytes;
    pub const loadModuleInfoFromIRBlob = ISession.Mixin(@This()).loadModuleInfoFromIRBlob;

    /// Load a module from source code with size specification.
    ///
    /// @param session The session to load the module into.
    /// @param moduleName The name of the module.
    /// @param path The path for the module.
    /// @param source Pointer to the source code data.
    /// @param sourceSize Size of the source code data in bytes.
    /// @param outDiagnostics (out, optional) Diagnostics output.
    /// @return The loaded module on success, or nullptr on failure.
    pub fn loadModuleFromSource(
        self: *ISession,
        module_name: [*:0]const u8,
        path: [*:0]const u8,
        source: [:0]const u8,
        out_diagnostics: ?**IBlob,
    ) ?*IModule {
        const diagnostics = getDiagnosticsPtr(out_diagnostics);
        defer logDiagnostics(diagnostics, out_diagnostics);
        return slang_loadModuleFromSource(self, module_name, path, source.ptr, source.len, diagnostics);
    }

    extern fn slang_loadModuleFromSource(session: *ISession, module_name: [*:0]const u8, path: [*:0]const u8, source: [*:0]const u8, source_size: usize, out_diagnostics: ?**IBlob) ?*IModule;

    /// Load a module from IR data.
    /// @param session The session to load the module into.
    /// @param moduleName Name of the module to load.
    /// @param path Path for the module (used for diagnostics).
    /// @param source IR data containing the module.
    /// @param sourceSize Size of the IR data in bytes.
    /// @param outDiagnostics (out, optional) Diagnostics output.
    /// @return The loaded module on success, or nullptr on failure.
    pub fn loadModuleFromIR(
        self: *ISession,
        module_name: [*:0]const u8,
        path: [*:0]const u8,
        source: []const u8,
        out_diagnostics: ?**IBlob,
    ) ?*IModule {
        const diagnostics = getDiagnosticsPtr(out_diagnostics);
        defer logDiagnostics(diagnostics, out_diagnostics);
        return slang_loadModuleFromIRBlob(self, module_name, path, source.ptr, source.len, diagnostics);
    }

    extern fn slang_loadModuleFromIRBlob(session: *ISession, module_name: [*:0]const u8, path: [*:0]const u8, source: [*]const u8, source_size: usize, out_diagnostics: ?**IBlob) ?*IModule;

    /// Read module info (name and version) from IR data.
    /// @param session The session to use for loading module info.
    /// @param source IR data containing the module.
    /// @param sourceSize Size of the IR data in bytes.
    /// @param outModuleVersion (out) Module version number.
    /// @param outModuleCompilerVersion (out) Compiler version that created the module.
    /// @param outModuleName (out) Name of the module.
    /// @return SLANG_OK on success, or an error code on failure.
    pub fn loadModuleInfoFromIR(self: *ISession, source: []const u8) !LoadModuleInfoFromIRBlobResult {
        var result: LoadModuleInfoFromIRBlobResult = undefined;
        try slang_loadModuleInfoFromIRBlob(self, source.ptr, source.len, &result.module_version, &result.module_compiler_version, &result.module_name).check();
        return result;
    }

    extern fn slang_loadModuleInfoFromIRBlob(session: *ISession, source: [*]const u8, source_size: usize, out_module_version: *i64, out_module_compiler_version: *[*:0]const u8, out_module_name: *[*:0]const u8) Result;

    const VTable = extern struct {
        base: IUnknown.VTable,
        getGlobalSession: *const fn (this: *ISession) callconv(mcall) *IGlobalSession,
        loadModule: *const fn (this: *ISession, module_name: [*:0]const u8, out_diagnostics: ?**IBlob) callconv(mcall) ?*IModule,
        loadModuleFromSource: *const fn (this: *ISession, module_name: [*:0]const u8, path: [*:0]const u8, source: *IBlob, out_diagnostics: ?**IBlob) callconv(mcall) ?*IModule,
        createCompositeComponentType: *const fn (this: *ISession, componentTypes: [*]const *IComponentType, componentTypeCount: i64, out_composite_component_type: **IComponentType, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        specializeType: *const fn (this: *ISession, type: *TypeReflection, specializationArgs: [*]const SpecializationArg, specializationArgCount: i64, out_diagnostics: ?**IBlob) callconv(mcall) *TypeReflection,
        getTypeLayout: *const fn (this: *ISession, type: *TypeReflection, targetIndex: i64, rules: LayoutRules, out_diagnostics: ?**IBlob) callconv(mcall) *TypeLayoutReflection,
        getContainerType: *const fn (this: *ISession, elementType: *TypeReflection, containerType: ContainerType, out_diagnostics: ?**IBlob) callconv(mcall) *TypeReflection,
        getDynamicType: *const fn (this: *ISession) callconv(mcall) *TypeReflection,
        getTypeRTTIMangledName: *const fn (this: *ISession, type: *TypeReflection, out_name_blob: **IBlob) callconv(mcall) Result,
        getTypeConformanceWitnessMangledName: *const fn (this: *ISession, type: *TypeReflection, interfaceType: *TypeReflection, out_name_blob: **IBlob) callconv(mcall) Result,
        getTypeConformanceWitnessSequentialID: *const fn (this: *ISession, type: *TypeReflection, interfaceType: *TypeReflection, out_id: *u32) callconv(mcall) Result,
        createCompileRequest: *const fn (this: *ISession, out_compile_request: **ICompileRequest) callconv(mcall) Result,
        createTypeConformanceComponentType: *const fn (this: *ISession, type: *TypeReflection, interfaceType: *TypeReflection, out_conformance: **ITypeConformance, conformanceIdOverride: i64, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        loadModuleFromIRBlob: *const fn (this: *ISession, module_name: [*:0]const u8, path: [*:0]const u8, source: *IBlob, out_diagnostics: ?**IBlob) callconv(mcall) ?*IModule,
        getLoadedModuleCount: *const fn (this: *ISession) callconv(mcall) i64,
        getLoadedModule: *const fn (this: *ISession, index: i64) callconv(mcall) *IModule,
        isBinaryModuleUpToDate: *const fn (this: *ISession, modulePath: [*:0]const u8, binaryModuleBlob: *IBlob) callconv(mcall) bool,
        loadModuleFromSourceString: *const fn (this: *ISession, module_name: [*:0]const u8, path: [*:0]const u8, str: [*:0]const u8, out_diagnostics: ?**IBlob) callconv(mcall) ?*IModule,
        getDynamicObjectRTTIBytes: *const fn (this: *ISession, type: *TypeReflection, interfaceType: *TypeReflection, out_rtti_data_buffer: [*]u32, bufferSizeInBytes: u32) callconv(mcall) Result,
        loadModuleInfoFromIRBlob: *const fn (this: *ISession, source: *IBlob, out_module_version: *i64, out_module_compiler_version: *[*:0]const u8, out_module_name: *[*:0]const u8) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getGlobalSession(self: *T) *IGlobalSession {
                const vtable: *const VTable = @ptrCast(self.vtable);
                vtable.getGlobalSession(@ptrCast(self));
            }

            fn loadModule(self: *T, module_name: [*:0]const u8, out_diagnostics: ?**IBlob) ?*IModule {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.loadModule(@ptrCast(self), module_name, diagnostics);
            }

            fn loadModuleFromSourceBlob(self: *T, module_name: [*:0]const u8, path: [*:0]const u8, source: *IBlob, out_diagnostics: ?**IBlob) ?*IModule {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.loadModuleFromSource(@ptrCast(self), module_name, path, source, diagnostics);
            }

            fn createCompositeComponentType(self: *T, component_types: []const *IComponentType, out_diagnostics: ?**IBlob) !*IComponentType {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var component_type: *IComponentType = undefined;
                try vtable.createCompositeComponentType(@ptrCast(self), component_types.ptr, @intCast(component_types.len), &component_type, diagnostics).check();
                return component_type;
            }

            fn specializeType(self: *T, type_: *TypeReflection, specialization_args: []const SpecializationArg, out_diagnostics: ?**IBlob) *TypeReflection {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.specializeType(@ptrCast(self), type_, specialization_args.ptr, @intCast(specialization_args.len), diagnostics);
            }

            fn getTypeLayout(self: *T, type_: *TypeReflection, targetIndex: i64, rules: LayoutRules, out_diagnostics: ?**IBlob) *TypeLayoutReflection {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getTypeLayout(@ptrCast(self), type_, targetIndex, rules, diagnostics);
            }

            fn getContainerType(self: *T, elementType: *TypeReflection, containerType: ContainerType, out_diagnostics: ?**IBlob) *TypeReflection {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getContainerType(@ptrCast(self), elementType, containerType, diagnostics);
            }

            fn getDynamicType(self: *T) *TypeReflection {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getDynamicType(@ptrCast(self));
            }

            fn getTypeRTTIMangledName(self: *T, type_: *TypeReflection) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var name_blob: *IBlob = undefined;
                try vtable.getTypeRTTIMangledName(@ptrCast(self), type_, &name_blob).check();
                return name_blob;
            }

            fn getTypeConformanceWitnessMangledName(self: *T, type_: *TypeReflection, interfaceType: *TypeReflection) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var name_blob: *IBlob = undefined;
                try vtable.getTypeConformanceWitnessMangledName(@ptrCast(self), type_, interfaceType, &name_blob).check();
                return name_blob;
            }

            fn getTypeConformanceWitnessSequentialID(self: *T, type_: *TypeReflection, interfaceType: *TypeReflection) !u32 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var id: u32 = undefined;
                try vtable.getTypeConformanceWitnessSequentialID(@ptrCast(self), type_, interfaceType, &id).check();
                return id;
            }

            fn createCompileRequest(self: *T) !*ICompileResult {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var compile_request: *ICompileRequest = undefined;
                try vtable.createCompileRequest(@ptrCast(self), &compile_request).check();
                return compile_request;
            }

            fn createTypeConformanceComponentType(self: *T, type_: *TypeReflection, interfaceType: *TypeReflection, conformanceIdOverride: i64, out_diagnostics: ?**IBlob) !*ITypeConformance {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var conformance: *ITypeConformance = undefined;
                try vtable.createTypeConformanceComponentType(@ptrCast(self), type_, interfaceType, &conformance, conformanceIdOverride, diagnostics).check();
                return conformance;
            }

            fn loadModuleFromIRBlob(self: *T, module_name: [*:0]const u8, path: [*:0]const u8, source: *IBlob, out_diagnostics: ?**IBlob) ?*IModule {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.loadModuleFromIRBlob(@ptrCast(self), module_name, path, source, diagnostics);
            }

            fn getLoadedModuleCount(self: *T) usize {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return @intCast(vtable.getLoadedModuleCount(@ptrCast(self)));
            }

            fn getLoadedModule(self: *T, index: i64) *IModule {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getLoadedModule(@ptrCast(self), index);
            }

            fn isBinaryModuleUpToDate(self: *T, modulePath: [*:0]const u8, binaryModuleBlob: *IBlob) bool {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.isBinaryModuleUpToDate(@ptrCast(self), modulePath, binaryModuleBlob);
            }

            fn loadModuleFromSourceString(self: *T, module_name: [:0]const u8, path: [:0]const u8, source_str: [:0]const u8, out_diagnostics: ?**IBlob) ?*IModule {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.loadModuleFromSourceString(@ptrCast(self), module_name.ptr, path.ptr, source_str.ptr, diagnostics);
            }

            fn getDynamicObjectRTTIBytes(self: *T, type_: *TypeReflection, interfaceType: *TypeReflection, out_rtti_data_buffer: []u32) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.getDynamicObjectRTTIBytes(@ptrCast(self), type_, interfaceType, out_rtti_data_buffer.ptr, @intCast(out_rtti_data_buffer.len)).check();
            }

            fn loadModuleInfoFromIRBlob(self: *T, source: *IBlob) !LoadModuleInfoFromIRBlobResult {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var result: LoadModuleInfoFromIRBlobResult = undefined;
                try vtable.loadModuleInfoFromIRBlob(@ptrCast(self), source, &result.module_version, &result.module_compiler_version, &result.module_name).check();
                return result;
            }
        };
    }
};

pub const IMetadata = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init();

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;
    pub const isParameterLocationUsed = IMetadata.Mixin(@This()).isParameterLocationUsed;
    pub const getDebugBuildIdentifier = IMetadata.Mixin(@This()).getDebugBuildIdentifier;

    const VTable = extern struct {
        base: ICastable.VTable,
        isParameterLocationUsed: *const fn (this: *IMetadata, category: ParameterCategory, spaceIndex: u64, registerIndex: u64, out_used: *bool) callconv(mcall) Result,
        getDebugBuildIdentifier: *const fn (this: *IMetadata) callconv(mcall) [*:0]const u8,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn isParameterLocationUsed(self: *T, category: ParameterCategory, spaceIndex: u64, registerIndex: u64) !bool {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var used: *bool = undefined;
                try vtable.isParameterLocationUsed(@ptrCast(self), category, spaceIndex, registerIndex, &used).check();
                return used;
            }

            fn getDebugBuildIdentifier(self: *T) [*:0]const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getDebugBuildIdentifier(@ptrCast(self));
            }
        };
    }
};

pub const ICompileResult = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init();

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const castAs = ICastable.Mixin(@This()).castAs;
    pub const getItemCount = ICompileResult.Mixin(@This()).getItemCount;
    pub const getItemData = ICompileResult.Mixin(@This()).getItemData;
    pub const getMetadata = ICompileResult.Mixin(@This()).getMetadata;

    const VTable = extern struct {
        base: ICastable.VTable,
        getItemCount: *const fn (this: *ICompileResult) callconv(mcall) u32,
        getItemData: *const fn (this: *ICompileResult, index: u32, out_blob: **IBlob) callconv(mcall) Result,
        getMetadata: *const fn (this: *ICompileResult, out_metadata: **IMetadata) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getItemCount(self: *T) u32 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getItemCount(@ptrCast(self));
            }

            fn getItemData(self: *T, index: u32) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var blob: *IBlob = undefined;
                try vtable.getItemData(@ptrCast(self), index, &blob).check();
                return blob;
            }

            fn getMetadata(self: *T) !*IMetadata {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var blob: *IBlob = undefined;
                try vtable.getMetadata(@ptrCast(self), &blob).check();
                return blob;
            }
        };
    }
};

pub const IComponentType = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x5bc42be8, 0x5c50, 0x4929, .{ 0x9e, 0x5e, 0xd1, 0x5e, 0x7c, 0x24, 0x1, 0x5f });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const getSession = IComponentType.Mixin(@This()).getSession;
    pub const getLayout = IComponentType.Mixin(@This()).getLayout;
    pub const getSpecializationParamCount = IComponentType.Mixin(@This()).getSpecializationParamCount;
    pub const getEntryPointCode = IComponentType.Mixin(@This()).getEntryPointCode;
    pub const getResultAsFileSystem = IComponentType.Mixin(@This()).getResultAsFileSystem;
    pub const getEntryPointHash = IComponentType.Mixin(@This()).getEntryPointHash;
    pub const specialize = IComponentType.Mixin(@This()).specialize;
    pub const link = IComponentType.Mixin(@This()).link;
    pub const getEntryPointHostCallable = IComponentType.Mixin(@This()).getEntryPointHostCallable;
    pub const renameEntryPoint = IComponentType.Mixin(@This()).renameEntryPoint;
    pub const linkWithOptions = IComponentType.Mixin(@This()).linkWithOptions;
    pub const getTargetCode = IComponentType.Mixin(@This()).getTargetCode;
    pub const getTargetMetadata = IComponentType.Mixin(@This()).getTargetMetadata;
    pub const getEntryPointMetadata = IComponentType.Mixin(@This()).getEntryPointMetadata;

    const VTable = extern struct {
        base: IUnknown.VTable,
        getSession: *const fn (this: *IComponentType) callconv(mcall) *ISession,
        getLayout: *const fn (this: *IComponentType, target_index: i64, out_diagnostics: ?**IBlob) callconv(mcall) ?*ProgramLayout,
        getSpecializationParamCount: *const fn (this: *IComponentType) callconv(mcall) i64,
        getEntryPointCode: *const fn (this: *IComponentType, entry_point_index: i64, target_index: i64, out_code: **IBlob, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getResultAsFileSystem: *const fn (this: *IComponentType, entry_point_index: i64, target_index: i64, out_file_system: **IMutableFileSystem) callconv(mcall) Result,
        getEntryPointHash: *const fn (this: *IComponentType, entry_point_index: i64, target_index: i64, out_hash: **IBlob) callconv(mcall) Result,
        specialize: *const fn (this: *IComponentType, specialization_args: [*]const SpecializationArg, specialization_arg_count: i64, out_specialized_component_type: **IComponentType, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        link: *const fn (this: *IComponentType, out_linked_component_type: **IComponentType, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getEntryPointHostCallable: *const fn (this: *IComponentType, entry_point_index: i32, target_index: i32, out_shared_library: **ISharedLibrary, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        renameEntryPoint: *const fn (this: *IComponentType, new_name: [*:0]const u8, out_entry_point: **IComponentType) callconv(mcall) Result,
        linkWithOptions: *const fn (this: *IComponentType, out_linked_component_type: **IComponentType, compiler_option_entry_count: u32, compiler_option_entries: [*]CompilerOptionEntry, out_dianostics: ?**IBlob) callconv(mcall) Result,
        getTargetCode: *const fn (this: *IComponentType, target_index: i64, out_code: **IBlob, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getTargetMetadata: *const fn (this: *IComponentType, target_index: i64, out_metadata: **IMetadata, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getEntryPointMetadata: *const fn (this: *IComponentType, entry_point_index: i64, target_index: i64, out_metadata: **IMetadata, out_diagnostics: ?**IBlob) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getSession(self: *T) *ISession {
                const vtable: *const VTable = @ptrCast(self);
                return vtable.getSession(@ptrCast(self));
            }

            fn getLayout(self: *T, targetIndex: i64, out_diagnostics: ?**IBlob) ?*ProgramLayout {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getLayout(@ptrCast(self), targetIndex, diagnostics);
            }

            fn getSpecializationParamCount(self: *T) usize {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return @intCast(vtable.getSpecializationParamCount(@ptrCast(self)));
            }

            fn getEntryPointCode(self: *T, entryPointIndex: i64, targetIndex: i64, out_diagnostics: ?**IBlob) !*IBlob {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var code: *IBlob = undefined;
                try vtable.getEntryPointCode(@ptrCast(self), entryPointIndex, targetIndex, &code, diagnostics).check();
                return code;
            }

            fn getResultAsFileSystem(self: *T, entryPointIndex: i64, targetIndex: i64) !*IMutableFileSystem {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var file_system: *IMutableFileSystem = undefined;
                try vtable.getResultAsFileSystem(@ptrCast(self), entryPointIndex, targetIndex, &file_system).check();
                return file_system;
            }

            fn getEntryPointHash(self: *T, entryPointIndex: i64, targetIndex: i64) *IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var hash: *IBlob = undefined;
                try vtable.getEntryPointHash(@ptrCast(self), entryPointIndex, targetIndex, &hash).check();
                return hash;
            }

            fn specialize(self: *T, specialization_args: []const SpecializationArg, out_diagnostics: ?**IBlob) !*IComponentType {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var component_type: *IComponentType = undefined;
                try vtable.specialize(@ptrCast(self), specialization_args.ptr, @intCast(specialization_args.len), &component_type, diagnostics).check();
                return component_type;
            }

            fn link(self: *T, out_diagnostics: ?**IBlob) !*IComponentType {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var linked_component_type: *IComponentType = undefined;
                try vtable.link(@ptrCast(self), &linked_component_type, diagnostics).check();
                return linked_component_type;
            }

            fn getEntryPointHostCallable(self: *T, entryPointIndex: i32, targetIndex: i32, out_diagnostics: ?**IBlob) !*ISharedLibrary {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var shared_library: *ISharedLibrary = undefined;
                try vtable.getEntryPointHostCallable(@ptrCast(self), entryPointIndex, targetIndex, &shared_library, diagnostics).check();
                return shared_library;
            }

            fn renameEntryPoint(self: *T, newName: [*:0]const u8) !*IComponentType {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var entry_point: *IComponentType = undefined;
                try vtable.renameEntryPoint(@ptrCast(self), newName, &entry_point).check();
                return entry_point;
            }

            fn linkWithOptions(self: *T, compiler_option_entries: []const CompilerOptionEntry, out_diagnostics: ?**IBlob) !*IComponentType {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var linked_component_type: *IComponentType = undefined;
                try vtable.linkWithOptions(@ptrCast(self), &linked_component_type, @intCast(compiler_option_entries.len), compiler_option_entries.ptr, diagnostics).check();
                return linked_component_type;
            }

            fn getTargetCode(self: *T, targetIndex: i64, out_diagnostics: ?**IBlob) !*IBlob {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var code: *IBlob = undefined;
                try vtable.getTargetCode(@ptrCast(self), targetIndex, &code, diagnostics).check();
                return code;
            }

            fn getTargetMetadata(self: *T, targetIndex: i64, out_diagnostics: ?**IBlob) !*IMetadata {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var metadata: *IMetadata = undefined;
                try vtable.getTargetMetadata(@ptrCast(self), targetIndex, &metadata, diagnostics).check();
                return metadata;
            }

            fn getEntryPointMetadata(self: *T, entryPointIndex: i64, targetIndex: i64, out_diagnostics: ?**IBlob) !*IMetadata {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var metadata: *IMetadata = undefined;
                try vtable.getEntryPointMetadata(@ptrCast(self), entryPointIndex, targetIndex, &metadata, diagnostics).check();
                return metadata;
            }
        };
    }
};

pub const IEntryPoint = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x8f241361, 0xf5bd, 0x4ca0, .{ 0xa3, 0xac, 0x2, 0xf7, 0xfa, 0x24, 0x2, 0xb8 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const getSession = IComponentType.Mixin(@This()).getSession;
    pub const getLayout = IComponentType.Mixin(@This()).getLayout;
    pub const getSpecializationParamCount = IComponentType.Mixin(@This()).getSpecializationParamCount;
    pub const getEntryPointCode = IComponentType.Mixin(@This()).getEntryPointCode;
    pub const getResultAsFileSystem = IComponentType.Mixin(@This()).getResultAsFileSystem;
    pub const getEntryPointHash = IComponentType.Mixin(@This()).getEntryPointHash;
    pub const specialize = IComponentType.Mixin(@This()).specialize;
    pub const link = IComponentType.Mixin(@This()).link;
    pub const getEntryPointHostCallable = IComponentType.Mixin(@This()).getEntryPointHostCallable;
    pub const renameEntryPoint = IComponentType.Mixin(@This()).renameEntryPoint;
    pub const linkWithOptions = IComponentType.Mixin(@This()).linkWithOptions;
    pub const getTargetCode = IComponentType.Mixin(@This()).getTargetCode;
    pub const getTargetMetadata = IComponentType.Mixin(@This()).getTargetMetadata;
    pub const getEntryPointMetadata = IComponentType.Mixin(@This()).getEntryPointMetadata;

    const VTable = extern struct {
        base: IComponentType.VTable,
        getFunctionReflection: *const fn (this: *IEntryPoint) callconv(mcall) *FunctionReflection,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getFunctionReflection(self: *T) *FunctionReflection {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getFunctionReflection(@ptrCast(self));
            }
        };
    }
};

pub const ITypeConformance = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x73eb3147, 0xe544, 0x41b5, .{ 0xb8, 0xf0, 0xa2, 0x44, 0xdf, 0x21, 0x94, 0xb });

    const VTable = IComponentType.VTable;
    const Mixin = IComponentType.Mixin;
};

pub const IComponentType2 = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x9c2a4b3d, 0x7f68, 0x4e91, .{ 0xa5, 0x2c, 0x8b, 0x19, 0x3e, 0x45, 0x7a, 0x9f });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const getTargetCompileResult = IComponentType2.Mixin(@This()).getTargetCompileResult;
    pub const getEntryPointCompileResult = IComponentType2.Mixin(@This()).getEntryPointCompileResult;

    const VTable = extern struct {
        base: IUnknown.VTable,
        getTargetCompileResult: *const fn (this: *IComponentType2, targetIndex: i64, out_compile_result: **ICompileResult, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getEntryPointCompileResult: *const fn (this: *IComponentType2, entryPointIndex: i64, targetIndex: i64, out_compile_result: **ICompileResult, out_diagnostics: ?**IBlob) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn getTargetCompileResult(self: *T, targetIndex: i64, out_diagnostics: ?**IBlob) !*ICompileResult {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var compile_result: *ICompileResult = undefined;
                try vtable.getTargetCompileResult(@ptrCast(self), targetIndex, &compile_result, diagnostics).check();
                return compile_result;
            }

            fn getEntryPointCompileResult(self: *T, entryPointIndex: i64, targetIndex: i64, out_diagnostics: ?**IBlob) callconv(mcall) !*ICompileResult {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var compile_result: *ICompileResult = undefined;
                try vtable.getEntryPointCompileResult(@ptrCast(self), entryPointIndex, targetIndex, &compile_result, diagnostics).check();
                return compile_result;
            }
        };
    }
};

pub const IModule = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0xc720e64, 0x8722, 0x4d31, .{ 0x89, 0x90, 0x63, 0x8a, 0x98, 0xb1, 0xc2, 0x79 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    /// NOTE: Slang seems to only ever return non-owning pointers to `IModule`s, so to avoid double
    /// frees, the easiest solution is to just remove this method. If this situation ever changes,
    /// the refcount of the returned objects will need to be artificially incremented inside the
    /// function that return them to make it safe to defer release them.
    // pub const release = IUnknown.Mixin(@This()).release;
    pub const getSession = IComponentType.Mixin(@This()).getSession;
    pub const getLayout = IComponentType.Mixin(@This()).getLayout;
    pub const getSpecializationParamCount = IComponentType.Mixin(@This()).getSpecializationParamCount;
    pub const getEntryPointCode = IComponentType.Mixin(@This()).getEntryPointCode;
    pub const getResultAsFileSystem = IComponentType.Mixin(@This()).getResultAsFileSystem;
    pub const getEntryPointHash = IComponentType.Mixin(@This()).getEntryPointHash;
    pub const specialize = IComponentType.Mixin(@This()).specialize;
    pub const link = IComponentType.Mixin(@This()).link;
    pub const getEntryPointHostCallable = IComponentType.Mixin(@This()).getEntryPointHostCallable;
    pub const renameEntryPoint = IComponentType.Mixin(@This()).renameEntryPoint;
    pub const linkWithOptions = IComponentType.Mixin(@This()).linkWithOptions;
    pub const getTargetCode = IComponentType.Mixin(@This()).getTargetCode;
    pub const getTargetMetadata = IComponentType.Mixin(@This()).getTargetMetadata;
    pub const getEntryPointMetadata = IComponentType.Mixin(@This()).getEntryPointMetadata;
    pub const findEntryPointByName = IModule.Mixin(@This()).findEntryPointByName;
    pub const getDefinedEntryPointCount = IModule.Mixin(@This()).getDefinedEntryPointCount;
    pub const getDefinedEntryPoint = IModule.Mixin(@This()).getDefinedEntryPoint;
    pub const serialize = IModule.Mixin(@This()).serialize;
    pub const writeToFile = IModule.Mixin(@This()).writeToFile;
    pub const getName = IModule.Mixin(@This()).getName;
    pub const getFilePath = IModule.Mixin(@This()).getFilePath;
    pub const getUniqueIdentity = IModule.Mixin(@This()).getUniqueIdentity;
    pub const findAndCheckEntryPoint = IModule.Mixin(@This()).findAndCheckEntryPoint;
    pub const getDependencyFileCount = IModule.Mixin(@This()).getDependencyFileCount;
    pub const getDependencyFilePath = IModule.Mixin(@This()).getDependencyFilePath;
    pub const getModuleReflection = IModule.Mixin(@This()).getModuleReflection;
    pub const disassemble = IModule.Mixin(@This()).disassemble;

    const VTable = extern struct {
        base: IComponentType.VTable,
        findEntryPointByName: *const fn (this: *IModule, name: [*:0]const u8, out_entry_point: **IEntryPoint) callconv(mcall) Result,
        getDefinedEntryPointCount: *const fn (this: *IModule) callconv(mcall) i32,
        getDefinedEntryPoint: *const fn (this: *IModule, index: i32, out_entry_point: **IEntryPoint) callconv(mcall) Result,
        serialize: *const fn (this: *IModule, out_serialized_blob: **IBlob) callconv(mcall) Result,
        writeToFile: *const fn (this: *IModule, file_name: [*:0]const u8) callconv(mcall) Result,
        getName: *const fn (this: *IModule) callconv(mcall) [*:0]const u8,
        getFilePath: *const fn (this: *IModule) callconv(mcall) [*:0]const u8,
        getUniqueIdentity: *const fn (this: *IModule) callconv(mcall) [*:0]const u8,
        findAndCheckEntryPoint: *const fn (this: *IModule, name: [*:0]const u8, stage: Stage, out_entry_point: **IEntryPoint, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getDependencyFileCount: *const fn (this: *IModule) callconv(mcall) i32,
        getDependencyFilePath: *const fn (this: *IModule, index: i32) callconv(mcall) [*:0]const u8,
        getModuleReflection: *const fn (this: *IModule) callconv(mcall) *DeclReflection,
        disassemble: *const fn (this: *IModule, out_disassembled_blob: **IBlob) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn findEntryPointByName(self: *T, name: [*:0]const u8) !*IEntryPoint {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var entry_point: *IEntryPoint = undefined;
                try vtable.findEntryPointByName(@ptrCast(self), name, &entry_point).check();
                return entry_point;
            }

            fn getDefinedEntryPointCount(self: *T) i32 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getDefinedEntryPointCount(@ptrCast(self));
            }

            fn getDefinedEntryPoint(self: *T, index: i32) !*IEntryPoint {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var entry_point: *IEntryPoint = undefined;
                try vtable.getDefinedEntryPoint(@ptrCast(self), index, &entry_point).check();
                return entry_point;
            }

            fn serialize(self: *T) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var serialized_blob: *IBlob = undefined;
                try vtable.serialize(@ptrCast(self), &serialized_blob).check();
                return serialized_blob;
            }

            fn writeToFile(self: *T, file_name: [*:0]const u8) !void {
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.writeToFile(@ptrCast(self), file_name).check();
            }

            fn getName(self: *T) [*:0]const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getName(@ptrCast(self));
            }

            fn getFilePath(self: *T) [*:0]const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getFilePath(@ptrCast(self));
            }

            fn getUniqueIdentity(self: *T) [*:0]const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getUniqueIdentity(@ptrCast(self));
            }

            fn findAndCheckEntryPoint(self: *T, name: [*:0]const u8, stage: Stage, out_diagnostics: ?**IBlob) !*IEntryPoint {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var entry_point: *IEntryPoint = undefined;
                try vtable.findAndCheckEntryPoint(@ptrCast(self), name, stage, &entry_point, diagnostics).check();
                return entry_point;
            }

            fn getDependencyFileCount(self: *T) i32 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getDependencyFileCount(@ptrCast(self));
            }

            fn getDependencyFilePath(self: *T, index: i32) [*:0]const u8 {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getDependencyFilePath(@ptrCast(self), index);
            }

            fn getModuleReflection(self: *T) *DeclReflection {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return vtable.getModuleReflection(@ptrCast(self));
            }

            fn disassemble(self: *T) !*IBlob {
                const vtable: *const VTable = @ptrCast(self.vtable);
                var disassembled_blob: *IBlob = undefined;
                try vtable.disassemble(@ptrCast(self), &disassembled_blob).check();
                return disassembled_blob;
            }
        };
    }
};

pub const IModulePrecompileService_Experimental = extern struct {
    vtable: *const VTable,

    pub const uuid = UUID.init(0x8e12e8e3, 0x5fcd, 0x433e, .{ 0xaf, 0xcb, 0x13, 0xa0, 0x88, 0xbc, 0x5e, 0xe5 });

    pub const queryInterface = IUnknown.Mixin(@This()).queryInterface;
    pub const addRef = IUnknown.Mixin(@This()).addRef;
    pub const release = IUnknown.Mixin(@This()).release;
    pub const precompileForTarget = IModulePrecompileService_Experimental.Mixin(@This()).precompileForTarget;
    pub const getPrecompiledTargetCode = IModulePrecompileService_Experimental.Mixin(@This()).getPrecompiledTargetCode;
    pub const getModuleDependencyCount = IModulePrecompileService_Experimental.Mixin(@This()).getModuleDependencyCount;
    pub const getModuleDependency = IModulePrecompileService_Experimental.Mixin(@This()).getModuleDependency;

    const VTable = extern struct {
        base: IUnknown.VTable,
        precompileForTarget: *const fn (this: *IModulePrecompileService_Experimental, target: CompileTarget, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getPrecompiledTargetCode: *const fn (this: *IModulePrecompileService_Experimental, target: CompileTarget, out_code: **IBlob, out_diagnostics: ?**IBlob) callconv(mcall) Result,
        getModuleDependencyCount: *const fn (this: *IModulePrecompileService_Experimental) callconv(mcall) i64,
        getModuleDependency: *const fn (this: *IModulePrecompileService_Experimental, dependency_index: i64, out_module: **IModule, out_diagnostics: ?**IBlob) callconv(mcall) Result,
    };

    fn Mixin(comptime T: type) type {
        return struct {
            fn precompileForTarget(self: *T, target: CompileTarget, out_diagnostics: ?**IBlob) !void {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                try vtable.precompileForTarget(@ptrCast(self), target, diagnostics).check();
            }

            fn getPrecompiledTargetCode(self: *T, target: CompileTarget, out_diagnostics: ?**IBlob) !*IBlob {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var code: *IBlob = undefined;
                try vtable.getPrecompiledTargetCode(@ptrCast(self), target, &code, diagnostics).check();
                return code;
            }

            fn getModuleDependencyCount(self: *T) usize {
                const vtable: *const VTable = @ptrCast(self.vtable);
                return @intCast(vtable.getModuleDependencyCount(@ptrCast(self)));
            }

            fn getModuleDependency(self: *T, dependency_index: i64, out_diagnostics: ?**IBlob) !*IModule {
                const diagnostics = getDiagnosticsPtr(out_diagnostics);
                defer logDiagnostics(diagnostics, out_diagnostics);
                const vtable: *const VTable = @ptrCast(self.vtable);
                var module: *IModule = undefined;
                try vtable.getModuleDependency(@ptrCast(self), dependency_index, &module, diagnostics).check();
                return module;
            }
        };
    }
};

pub const SpecializationArg = extern struct {
    kind: enum(i32) {
        unknown = 0,
        type,
        expr,
    },
    data: extern union {
        type: *TypeReflection,
        expr: [*:0]const u8,
    },

    pub fn fromType(in_type: *TypeReflection) SpecializationArg {
        return SpecializationArg{
            .kind = .type,
            .data = .{ .type = in_type },
        };
    }

    pub fn fromExpr(in_expr: [*:0]const u8) SpecializationArg {
        return SpecializationArg{
            .kind = .expr,
            .data = .{ .expr = in_expr },
        };
    }
};

pub const API_VERSION = 0;
pub const TAG_VERSION = "2025.19.1";

pub const LanguageVersion = enum(i32) {
    unknown = 0,
    legacy = 2018,
    @"2025" = 2025,
    @"2026" = 2026,

    pub const default = LanguageVersion.legacy;
    pub const latest = LanguageVersion.@"2026";
};

const GlobalSessionDesc = extern struct {
    _structure_size: u32 = @sizeOf(@This()),
    api_version: u32 = API_VERSION,
    min_language_version: LanguageVersion = .@"2025",
    enable_glsl: bool = false,
    _reserved: [16]u32 = undefined,
};

/// Create a blob from binary data.
///
/// @param data Pointer to the binary data to store in the blob. Must not be null.
/// @param size Size of the data in bytes. Must be greater than 0.
/// @return The created blob on success, or nullptr on failure.
pub fn createBlob(data: []const u8) *IBlob {
    return slang_createBlob(data.ptr, data.len);
}

extern fn slang_createBlob(data: [*]const u8, size: usize) *IBlob;

/// Create a global session, with the built-in core module.
///
/// @param apiVersion Pass in SLANG_API_VERSION
/// @param outGlobalSession (out)The created global session.
pub fn createGlobalSession2(api_version: i64) !*IGlobalSession {
    var global_session: *IGlobalSession = undefined;
    try slang_createGlobalSession(api_version, &global_session).check();
    return global_session;
}

extern fn slang_createGlobalSession(api_version: i64, out_global_session: **IGlobalSession) Result;

/// Create a global session, with the built-in core module.
///
/// @param desc Description of the global session.
/// @param outGlobalSession (out)The created global session.
pub fn createGlobalSession(desc: GlobalSessionDesc) !*IGlobalSession {
    var global_session: *IGlobalSession = undefined;
    try slang_createGlobalSession2(&desc, &global_session).check();
    return global_session;
}

extern fn slang_createGlobalSession2(desc: *const GlobalSessionDesc, out_global_session: **IGlobalSession) Result;

/// Create a global session, but do not set up the core module. The core module can
/// then be loaded via loadCoreModule or compileCoreModule
///
/// @param apiVersion Pass in SLANG_API_VERSION
/// @param outGlobalSession (out)The created global session that doesn't have a core module setup.
///
/// NOTE! API is experimental and not ready for production code
pub fn createGlobalSessionWithoutCoreModule(api_version: i64) !*IGlobalSession {
    var global_session: *IGlobalSession = undefined;
    try slang_createGlobalSessionWithoutCoreModule(api_version, &global_session).check();
    return global_session;
}

extern fn slang_createGlobalSessionWithoutCoreModule(api_version: i64, out_global_session: **IGlobalSession) Result;

/// Returns a blob that contains the serialized core module.
/// Returns nullptr if there isn't an embedded core module.
///
/// NOTE! API is experimental and not ready for production code
pub const getEmbeddedCoreModule = slang_getEmbeddedCoreModule;

extern fn slang_getEmbeddedCoreModule() *IBlob;

/// Cleanup all global allocations used by Slang, to prevent memory leak detectors from
/// reporting them as leaks. This function should only be called after all Slang objects
/// have been released. No other Slang functions such as `createGlobalSession`
/// should be called after this function.
pub const shutdown = slang_shutdown;

extern fn slang_shutdown() void;

/// Return the last signaled internal error message.
pub const getLastInternalErrorMessage = slang_getLastInternalErrorMessage;

extern fn slang_getLastInternalErrorMessage() [*:0]const u8;

test "compile" {
    const global_session = try createGlobalSession(.{});
    defer global_session.release();

    const target_desc = TargetDesc{
        .format = .spirv,
        .profile = global_session.findProfile("spirv_1_5"),
    };
    const session_desc = SessionDesc{
        .targets = &.{target_desc},
        .search_paths = &.{"shaders"},
        .compiler_option_entries = &.{
            .macro_define("FOO", "1"),
            .optimization(.high),
        },
        .default_matrix_layout_mode = .row_major,
    };
    const session = try global_session.createSession(session_desc);
    defer session.release();

    const module = session.loadModule("test.slang", null) orelse return error.ModuleLoadFailed;
    const entry_point = try module.findEntryPointByName("computeMain");
    defer entry_point.release();

    const component_types = [_]*IComponentType{
        @ptrCast(module), @ptrCast(entry_point),
    };
    const program = try session.createCompositeComponentType(&component_types, null);
    defer program.release();

    const linked_program = try program.link(null);
    defer linked_program.release();

    const reflection = linked_program.getLayout(0, null) orelse return error.ReflectionFailed;
    try std.testing.expectEqual(1, reflection.entryPointCount());
    try std.testing.expectEqual(3, reflection.parameterCount());

    const spirv_code = try linked_program.getEntryPointCode(0, 0, null);
    defer spirv_code.release();
    try std.testing.expect(spirv_code.getBufferSize() != 0);
}

extern const slang_args_buffer: [1024]u8;
extern const slang_args_buffer_end: u32;
extern var slang_test_interfaces: SlangTestInterfaces;

const SlangTestInterfaces = extern struct {
    IUnknown: IUnknown,
    ICastable: ICastable,
    IClonable: IClonable,
    IBlob: IBlob,
    IFileSystem: IFileSystem,
    ISharedLibrary: ISharedLibrary,
    ISharedLibraryLoader: ISharedLibraryLoader,
    IFileSystemExt: IFileSystemExt,
    IMutableFileSystem: IMutableFileSystem,
    IWriter: IWriter,
    IProfiler: IProfiler,
    ICompileRequest: ICompileRequest,
    IGlobalSession: IGlobalSession,
    ISession: ISession,
    IMetadata: IMetadata,
    ICompileResult: ICompileResult,
    IComponentType: IComponentType,
    IEntryPoint: IEntryPoint,
    IComponentType2: IComponentType2,
    IModule: IModule,
    IModulePrecompileService_Experimental: IModulePrecompileService_Experimental,
};

const Rng = std.Random.DefaultPrng;
const FUNC_ITER_COUNT = 10_000;

test "vtables and argument passing" {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    var rng = Rng.init(seed);
    // TODO: I think there is a way to only show stderr after an error occured
    std.debug.print("Seed for this run was 0x{X}\n", .{seed});

    try testSlangVTable("IUnknown", &rng);
    try testSlangVTable("ICastable", &rng);
    try testSlangVTable("IClonable", &rng);
    try testSlangVTable("IBlob", &rng);
    try testSlangVTable("IFileSystem", &rng);
    try testSlangVTable("ISharedLibrary", &rng);
    try testSlangVTable("ISharedLibraryLoader", &rng);
    try testSlangVTable("IFileSystemExt", &rng);
    try testSlangVTable("IMutableFileSystem", &rng);
    try testSlangVTable("IWriter", &rng);
    try testSlangVTable("IProfiler", &rng);
    try testSlangVTable("IGlobalSession", &rng);
    try testSlangVTable("ISession", &rng);
    try testSlangVTable("IMetadata", &rng);
    try testSlangVTable("ICompileResult", &rng);
    try testSlangVTable("IComponentType", &rng);
    try testSlangVTable("IEntryPoint", &rng);
    try testSlangVTable("IComponentType2", &rng);
    try testSlangVTable("IModule", &rng);
    try testSlangVTable("IModulePrecompileService_Experimental", &rng);
}

fn testSlangVTable(comptime interface_name: []const u8, rng: *Rng) !void {
    const object = &@field(slang_test_interfaces, interface_name);
    try testSlangVTableImpl(object.vtable.*, object, interface_name, rng);
}

fn testSlangVTableImpl(vtable: anytype, this: anytype, type_name: []const u8, rng: *Rng) !void {
    inline for (std.meta.fields(@TypeOf(vtable))) |field| {
        const foo = @field(vtable, field.name);
        switch (@typeInfo(field.type)) {
            .@"struct" => try testSlangVTableImpl(foo, this, type_name, rng),
            .pointer => for (0..FUNC_ITER_COUNT) |_| {
                try testSlangFunction(foo, @ptrCast(this), type_name, field.name, rng);
            },
            else => unreachable,
        }
    }
}

fn testSlangFunction(func: anytype, this: *anyopaque, type_name: []const u8, func_name: []const u8, rng: *Rng) !void {
    const F = std.meta.Child(@TypeOf(func));
    const Args = functionArgTuple(F);
    var args: Args = undefined;

    var zig_args_buffer: [1024]u8 = undefined;
    var zig_args: std.ArrayList(u8) = .initBuffer(&zig_args_buffer);
    try zig_args.appendSliceBounded(type_name);
    try zig_args.appendBounded('.');
    try zig_args.appendSliceBounded(func_name);

    inline for (@typeInfo(F).@"fn".params, 0..) |param, i| {
        if (i == 0) {
            args[i] = @ptrCast(@alignCast(this));
        } else {
            args[i] = getRandomValue(param.type.?, rng);
        }
        try zig_args.appendSliceBounded(std.mem.asBytes(&args[i]));
    }
    _ = @call(.auto, func, args);
    try std.testing.expectEqualSlices(u8, slang_args_buffer[0..slang_args_buffer_end], zig_args.items);
}

fn getRandomValue(comptime T: type, rng: *Rng) T {
    var result: T = undefined;
    rng.fill(std.mem.asBytes(&result));
    return result;
}

fn functionArgTuple(comptime F: type) type {
    const params = @typeInfo(F).@"fn".params;
    const names = [8][:0]const u8{ "0", "1", "2", "3", "4", "5", "6", "7" };
    comptime var fields: [8]std.builtin.Type.StructField = undefined;

    inline for (params, 0..) |param, i| {
        std.debug.assert(param.is_generic == false);
        fields[i] = .{
            .name = names[i],
            .type = param.type.?,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(param.type.?),
        };
    }
    return @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .fields = fields[0..params.len],
            .decls = &.{},
            .is_tuple = true,
        },
    });
}

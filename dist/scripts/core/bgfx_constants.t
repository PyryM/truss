--Autogenerated bgfx constants
local m = {}

m.BGFX_API_VERSION = 0x5fULL
m.BGFX_STATE_WRITE_R = 0x1ULL
m.BGFX_STATE_WRITE_G = 0x2ULL
m.BGFX_STATE_WRITE_B = 0x4ULL
m.BGFX_STATE_WRITE_A = 0x8ULL
m.BGFX_STATE_WRITE_Z = 0x4000000000ULL
m.BGFX_STATE_WRITE_RGB = 0x7ULL
m.BGFX_STATE_WRITE_MASK = 0x400000000fULL
m.BGFX_STATE_DEPTH_TEST_LESS = 0x10ULL
m.BGFX_STATE_DEPTH_TEST_LEQUAL = 0x20ULL
m.BGFX_STATE_DEPTH_TEST_EQUAL = 0x30ULL
m.BGFX_STATE_DEPTH_TEST_GEQUAL = 0x40ULL
m.BGFX_STATE_DEPTH_TEST_GREATER = 0x50ULL
m.BGFX_STATE_DEPTH_TEST_NOTEQUAL = 0x60ULL
m.BGFX_STATE_DEPTH_TEST_NEVER = 0x70ULL
m.BGFX_STATE_DEPTH_TEST_ALWAYS = 0x80ULL
m.BGFX_STATE_DEPTH_TEST_SHIFT = 0x4ULL
m.BGFX_STATE_DEPTH_TEST_MASK = 0xf0ULL
m.BGFX_STATE_BLEND_ZERO = 0x1000ULL
m.BGFX_STATE_BLEND_ONE = 0x2000ULL
m.BGFX_STATE_BLEND_SRC_COLOR = 0x3000ULL
m.BGFX_STATE_BLEND_INV_SRC_COLOR = 0x4000ULL
m.BGFX_STATE_BLEND_SRC_ALPHA = 0x5000ULL
m.BGFX_STATE_BLEND_INV_SRC_ALPHA = 0x6000ULL
m.BGFX_STATE_BLEND_DST_ALPHA = 0x7000ULL
m.BGFX_STATE_BLEND_INV_DST_ALPHA = 0x8000ULL
m.BGFX_STATE_BLEND_DST_COLOR = 0x9000ULL
m.BGFX_STATE_BLEND_INV_DST_COLOR = 0xa000ULL
m.BGFX_STATE_BLEND_SRC_ALPHA_SAT = 0xb000ULL
m.BGFX_STATE_BLEND_FACTOR = 0xc000ULL
m.BGFX_STATE_BLEND_INV_FACTOR = 0xd000ULL
m.BGFX_STATE_BLEND_SHIFT = 0xcULL
m.BGFX_STATE_BLEND_MASK = 0xffff000ULL
m.BGFX_STATE_BLEND_EQUATION_ADD = 0x0ULL
m.BGFX_STATE_BLEND_EQUATION_SUB = 0x10000000ULL
m.BGFX_STATE_BLEND_EQUATION_REVSUB = 0x20000000ULL
m.BGFX_STATE_BLEND_EQUATION_MIN = 0x30000000ULL
m.BGFX_STATE_BLEND_EQUATION_MAX = 0x40000000ULL
m.BGFX_STATE_BLEND_EQUATION_SHIFT = 0x1cULL
m.BGFX_STATE_BLEND_EQUATION_MASK = 0x3f0000000ULL
m.BGFX_STATE_BLEND_INDEPENDENT = 0x400000000ULL
m.BGFX_STATE_BLEND_ALPHA_TO_COVERAGE = 0x800000000ULL
m.BGFX_STATE_CULL_CW = 0x1000000000ULL
m.BGFX_STATE_CULL_CCW = 0x2000000000ULL
m.BGFX_STATE_CULL_SHIFT = 0x24ULL
m.BGFX_STATE_CULL_MASK = 0x3000000000ULL
m.BGFX_STATE_ALPHA_REF_SHIFT = 0x28ULL
m.BGFX_STATE_ALPHA_REF_MASK = 0xff0000000000ULL
m.BGFX_STATE_PT_TRISTRIP = 0x1000000000000ULL
m.BGFX_STATE_PT_LINES = 0x2000000000000ULL
m.BGFX_STATE_PT_LINESTRIP = 0x3000000000000ULL
m.BGFX_STATE_PT_POINTS = 0x4000000000000ULL
m.BGFX_STATE_PT_SHIFT = 0x30ULL
m.BGFX_STATE_PT_MASK = 0x7000000000000ULL
m.BGFX_STATE_POINT_SIZE_SHIFT = 0x34ULL
m.BGFX_STATE_POINT_SIZE_MASK = 0xf0000000000000ULL
m.BGFX_STATE_MSAA = 0x100000000000000ULL
m.BGFX_STATE_LINEAA = 0x200000000000000ULL
m.BGFX_STATE_CONSERVATIVE_RASTER = 0x400000000000000ULL
m.BGFX_STATE_RESERVED_SHIFT = 0x3dULL
m.BGFX_STATE_RESERVED_MASK = 0xe000000000000000ULL
m.BGFX_STATE_NONE = 0x0ULL
m.BGFX_STATE_MASK = 0xffffffffffffffffULL
m.BGFX_STATE_DEFAULT = 0x10000500000001fULL
m.BGFX_STATE_BLEND_ADD = 0x2222000ULL
m.BGFX_STATE_BLEND_ALPHA = 0x6565000ULL
m.BGFX_STATE_BLEND_DARKEN = 0x1b2222000ULL
m.BGFX_STATE_BLEND_LIGHTEN = 0x242222000ULL
m.BGFX_STATE_BLEND_MULTIPLY = 0x1919000ULL
m.BGFX_STATE_BLEND_NORMAL = 0x6262000ULL
m.BGFX_STATE_BLEND_SCREEN = 0x4242000ULL
m.BGFX_STATE_BLEND_LINEAR_BURN = 0x9a9a9000ULL
m.BGFX_STENCIL_FUNC_REF_SHIFT = 0x0ULL
m.BGFX_STENCIL_FUNC_REF_MASK = 0xffULL
m.BGFX_STENCIL_FUNC_RMASK_SHIFT = 0x8ULL
m.BGFX_STENCIL_FUNC_RMASK_MASK = 0xff00ULL
m.BGFX_STENCIL_TEST_LESS = 0x10000ULL
m.BGFX_STENCIL_TEST_LEQUAL = 0x20000ULL
m.BGFX_STENCIL_TEST_EQUAL = 0x30000ULL
m.BGFX_STENCIL_TEST_GEQUAL = 0x40000ULL
m.BGFX_STENCIL_TEST_GREATER = 0x50000ULL
m.BGFX_STENCIL_TEST_NOTEQUAL = 0x60000ULL
m.BGFX_STENCIL_TEST_NEVER = 0x70000ULL
m.BGFX_STENCIL_TEST_ALWAYS = 0x80000ULL
m.BGFX_STENCIL_TEST_SHIFT = 0x10ULL
m.BGFX_STENCIL_TEST_MASK = 0xf0000ULL
m.BGFX_STENCIL_OP_FAIL_S_ZERO = 0x0ULL
m.BGFX_STENCIL_OP_FAIL_S_KEEP = 0x100000ULL
m.BGFX_STENCIL_OP_FAIL_S_REPLACE = 0x200000ULL
m.BGFX_STENCIL_OP_FAIL_S_INCR = 0x300000ULL
m.BGFX_STENCIL_OP_FAIL_S_INCRSAT = 0x400000ULL
m.BGFX_STENCIL_OP_FAIL_S_DECR = 0x500000ULL
m.BGFX_STENCIL_OP_FAIL_S_DECRSAT = 0x600000ULL
m.BGFX_STENCIL_OP_FAIL_S_INVERT = 0x700000ULL
m.BGFX_STENCIL_OP_FAIL_S_SHIFT = 0x14ULL
m.BGFX_STENCIL_OP_FAIL_S_MASK = 0xf00000ULL
m.BGFX_STENCIL_OP_FAIL_Z_ZERO = 0x0ULL
m.BGFX_STENCIL_OP_FAIL_Z_KEEP = 0x1000000ULL
m.BGFX_STENCIL_OP_FAIL_Z_REPLACE = 0x2000000ULL
m.BGFX_STENCIL_OP_FAIL_Z_INCR = 0x3000000ULL
m.BGFX_STENCIL_OP_FAIL_Z_INCRSAT = 0x4000000ULL
m.BGFX_STENCIL_OP_FAIL_Z_DECR = 0x5000000ULL
m.BGFX_STENCIL_OP_FAIL_Z_DECRSAT = 0x6000000ULL
m.BGFX_STENCIL_OP_FAIL_Z_INVERT = 0x7000000ULL
m.BGFX_STENCIL_OP_FAIL_Z_SHIFT = 0x18ULL
m.BGFX_STENCIL_OP_FAIL_Z_MASK = 0xf000000ULL
m.BGFX_STENCIL_OP_PASS_Z_ZERO = 0x0ULL
m.BGFX_STENCIL_OP_PASS_Z_KEEP = 0x10000000ULL
m.BGFX_STENCIL_OP_PASS_Z_REPLACE = 0x20000000ULL
m.BGFX_STENCIL_OP_PASS_Z_INCR = 0x30000000ULL
m.BGFX_STENCIL_OP_PASS_Z_INCRSAT = 0x40000000ULL
m.BGFX_STENCIL_OP_PASS_Z_DECR = 0x50000000ULL
m.BGFX_STENCIL_OP_PASS_Z_DECRSAT = 0x60000000ULL
m.BGFX_STENCIL_OP_PASS_Z_INVERT = 0x70000000ULL
m.BGFX_STENCIL_OP_PASS_Z_SHIFT = 0x1cULL
m.BGFX_STENCIL_OP_PASS_Z_MASK = 0xf0000000ULL
m.BGFX_STENCIL_NONE = 0x0ULL
m.BGFX_STENCIL_MASK = 0xffffffffULL
m.BGFX_STENCIL_DEFAULT = 0x0ULL
m.BGFX_CLEAR_NONE = 0x0ULL
m.BGFX_CLEAR_COLOR = 0x1ULL
m.BGFX_CLEAR_DEPTH = 0x2ULL
m.BGFX_CLEAR_STENCIL = 0x4ULL
m.BGFX_CLEAR_DISCARD_COLOR_0 = 0x8ULL
m.BGFX_CLEAR_DISCARD_COLOR_1 = 0x10ULL
m.BGFX_CLEAR_DISCARD_COLOR_2 = 0x20ULL
m.BGFX_CLEAR_DISCARD_COLOR_3 = 0x40ULL
m.BGFX_CLEAR_DISCARD_COLOR_4 = 0x80ULL
m.BGFX_CLEAR_DISCARD_COLOR_5 = 0x100ULL
m.BGFX_CLEAR_DISCARD_COLOR_6 = 0x200ULL
m.BGFX_CLEAR_DISCARD_COLOR_7 = 0x400ULL
m.BGFX_CLEAR_DISCARD_DEPTH = 0x800ULL
m.BGFX_CLEAR_DISCARD_STENCIL = 0x1000ULL
m.BGFX_CLEAR_DISCARD_COLOR_MASK = 0x7f8ULL
m.BGFX_CLEAR_DISCARD_MASK = 0x1ff8ULL
m.BGFX_DEBUG_NONE = 0x0ULL
m.BGFX_DEBUG_WIREFRAME = 0x1ULL
m.BGFX_DEBUG_IFH = 0x2ULL
m.BGFX_DEBUG_STATS = 0x4ULL
m.BGFX_DEBUG_TEXT = 0x8ULL
m.BGFX_DEBUG_PROFILER = 0x10ULL
m.BGFX_BUFFER_NONE = 0x0ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_8x1 = 0x1ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_8x2 = 0x2ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_8x4 = 0x3ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_16x1 = 0x4ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_16x2 = 0x5ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_16x4 = 0x6ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_32x1 = 0x7ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_32x2 = 0x8ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_32x4 = 0x9ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_SHIFT = 0x0ULL
m.BGFX_BUFFER_COMPUTE_FORMAT_MASK = 0xfULL
m.BGFX_BUFFER_COMPUTE_TYPE_INT = 0x10ULL
m.BGFX_BUFFER_COMPUTE_TYPE_UINT = 0x20ULL
m.BGFX_BUFFER_COMPUTE_TYPE_FLOAT = 0x30ULL
m.BGFX_BUFFER_COMPUTE_TYPE_SHIFT = 0x4ULL
m.BGFX_BUFFER_COMPUTE_TYPE_MASK = 0x30ULL
m.BGFX_BUFFER_COMPUTE_READ = 0x100ULL
m.BGFX_BUFFER_COMPUTE_WRITE = 0x200ULL
m.BGFX_BUFFER_DRAW_INDIRECT = 0x400ULL
m.BGFX_BUFFER_ALLOW_RESIZE = 0x800ULL
m.BGFX_BUFFER_INDEX32 = 0x1000ULL
m.BGFX_BUFFER_COMPUTE_READ_WRITE = 0x300ULL
m.BGFX_TEXTURE_NONE = 0x0ULL
m.BGFX_TEXTURE_MSAA_SAMPLE = 0x800000000ULL
m.BGFX_TEXTURE_RT = 0x1000000000ULL
m.BGFX_TEXTURE_RT_MSAA_X2 = 0x2000000000ULL
m.BGFX_TEXTURE_RT_MSAA_X4 = 0x3000000000ULL
m.BGFX_TEXTURE_RT_MSAA_X8 = 0x4000000000ULL
m.BGFX_TEXTURE_RT_MSAA_X16 = 0x5000000000ULL
m.BGFX_TEXTURE_RT_MSAA_SHIFT = 0x24ULL
m.BGFX_TEXTURE_RT_MSAA_MASK = 0x7000000000ULL
m.BGFX_TEXTURE_RT_WRITE_ONLY = 0x8000000000ULL
m.BGFX_TEXTURE_RT_MASK = 0xf000000000ULL
m.BGFX_TEXTURE_COMPUTE_WRITE = 0x100000000000ULL
m.BGFX_TEXTURE_SRGB = 0x200000000000ULL
m.BGFX_TEXTURE_BLIT_DST = 0x400000000000ULL
m.BGFX_TEXTURE_READ_BACK = 0x800000000000ULL
m.BGFX_SAMPLER_NONE = 0x0ULL
m.BGFX_SAMPLER_U_MIRROR = 0x1ULL
m.BGFX_SAMPLER_U_CLAMP = 0x2ULL
m.BGFX_SAMPLER_U_BORDER = 0x3ULL
m.BGFX_SAMPLER_U_SHIFT = 0x0ULL
m.BGFX_SAMPLER_U_MASK = 0x3ULL
m.BGFX_SAMPLER_V_MIRROR = 0x4ULL
m.BGFX_SAMPLER_V_CLAMP = 0x8ULL
m.BGFX_SAMPLER_V_BORDER = 0xcULL
m.BGFX_SAMPLER_V_SHIFT = 0x2ULL
m.BGFX_SAMPLER_V_MASK = 0xcULL
m.BGFX_SAMPLER_W_MIRROR = 0x10ULL
m.BGFX_SAMPLER_W_CLAMP = 0x20ULL
m.BGFX_SAMPLER_W_BORDER = 0x30ULL
m.BGFX_SAMPLER_W_SHIFT = 0x4ULL
m.BGFX_SAMPLER_W_MASK = 0x30ULL
m.BGFX_SAMPLER_MIN_POINT = 0x40ULL
m.BGFX_SAMPLER_MIN_ANISOTROPIC = 0x80ULL
m.BGFX_SAMPLER_MIN_SHIFT = 0x6ULL
m.BGFX_SAMPLER_MIN_MASK = 0xc0ULL
m.BGFX_SAMPLER_MAG_POINT = 0x100ULL
m.BGFX_SAMPLER_MAG_ANISOTROPIC = 0x200ULL
m.BGFX_SAMPLER_MAG_SHIFT = 0x8ULL
m.BGFX_SAMPLER_MAG_MASK = 0x300ULL
m.BGFX_SAMPLER_MIP_POINT = 0x400ULL
m.BGFX_SAMPLER_MIP_SHIFT = 0xaULL
m.BGFX_SAMPLER_MIP_MASK = 0x400ULL
m.BGFX_SAMPLER_COMPARE_LESS = 0x10000ULL
m.BGFX_SAMPLER_COMPARE_LEQUAL = 0x20000ULL
m.BGFX_SAMPLER_COMPARE_EQUAL = 0x30000ULL
m.BGFX_SAMPLER_COMPARE_GEQUAL = 0x40000ULL
m.BGFX_SAMPLER_COMPARE_GREATER = 0x50000ULL
m.BGFX_SAMPLER_COMPARE_NOTEQUAL = 0x60000ULL
m.BGFX_SAMPLER_COMPARE_NEVER = 0x70000ULL
m.BGFX_SAMPLER_COMPARE_ALWAYS = 0x80000ULL
m.BGFX_SAMPLER_COMPARE_SHIFT = 0x10ULL
m.BGFX_SAMPLER_COMPARE_MASK = 0xf0000ULL
m.BGFX_SAMPLER_SAMPLE_STENCIL = 0x100000ULL
m.BGFX_SAMPLER_BORDER_COLOR_SHIFT = 0x18ULL
m.BGFX_SAMPLER_BORDER_COLOR_MASK = 0xf000000ULL
m.BGFX_SAMPLER_RESERVED_SHIFT = 0x1cULL
m.BGFX_SAMPLER_RESERVED_MASK = 0xf0000000ULL
m.BGFX_SAMPLER_POINT = 0x540ULL
m.BGFX_SAMPLER_UVW_MIRROR = 0x15ULL
m.BGFX_SAMPLER_UVW_CLAMP = 0x2aULL
m.BGFX_SAMPLER_UVW_BORDER = 0x3fULL
m.BGFX_SAMPLER_BITS_MASK = 0xf07ffULL
m.BGFX_RESET_NONE = 0x0ULL
m.BGFX_RESET_FULLSCREEN = 0x1ULL
m.BGFX_RESET_FULLSCREEN_SHIFT = 0x0ULL
m.BGFX_RESET_FULLSCREEN_MASK = 0x1ULL
m.BGFX_RESET_MSAA_X2 = 0x10ULL
m.BGFX_RESET_MSAA_X4 = 0x20ULL
m.BGFX_RESET_MSAA_X8 = 0x30ULL
m.BGFX_RESET_MSAA_X16 = 0x40ULL
m.BGFX_RESET_MSAA_SHIFT = 0x4ULL
m.BGFX_RESET_MSAA_MASK = 0x70ULL
m.BGFX_RESET_VSYNC = 0x80ULL
m.BGFX_RESET_MAXANISOTROPY = 0x100ULL
m.BGFX_RESET_CAPTURE = 0x200ULL
m.BGFX_RESET_FLUSH_AFTER_RENDER = 0x2000ULL
m.BGFX_RESET_FLIP_AFTER_RENDER = 0x4000ULL
m.BGFX_RESET_SRGB_BACKBUFFER = 0x8000ULL
m.BGFX_RESET_HDR10 = 0x10000ULL
m.BGFX_RESET_HIDPI = 0x20000ULL
m.BGFX_RESET_DEPTH_CLAMP = 0x40000ULL
m.BGFX_RESET_SUSPEND = 0x80000ULL
m.BGFX_RESET_RESERVED_SHIFT = 0x1fULL
m.BGFX_RESET_RESERVED_MASK = 0x80000000ULL
m.BGFX_CAPS_ALPHA_TO_COVERAGE = 0x1ULL
m.BGFX_CAPS_BLEND_INDEPENDENT = 0x2ULL
m.BGFX_CAPS_COMPUTE = 0x4ULL
m.BGFX_CAPS_CONSERVATIVE_RASTER = 0x8ULL
m.BGFX_CAPS_DRAW_INDIRECT = 0x10ULL
m.BGFX_CAPS_FRAGMENT_DEPTH = 0x20ULL
m.BGFX_CAPS_FRAGMENT_ORDERING = 0x40ULL
m.BGFX_CAPS_FRAMEBUFFER_RW = 0x80ULL
m.BGFX_CAPS_GRAPHICS_DEBUGGER = 0x100ULL
m.BGFX_CAPS_HDR10 = 0x400ULL
m.BGFX_CAPS_HIDPI = 0x800ULL
m.BGFX_CAPS_INDEX32 = 0x1000ULL
m.BGFX_CAPS_INSTANCING = 0x2000ULL
m.BGFX_CAPS_OCCLUSION_QUERY = 0x4000ULL
m.BGFX_CAPS_RENDERER_MULTITHREADED = 0x8000ULL
m.BGFX_CAPS_SWAP_CHAIN = 0x10000ULL
m.BGFX_CAPS_TEXTURE_2D_ARRAY = 0x20000ULL
m.BGFX_CAPS_TEXTURE_3D = 0x40000ULL
m.BGFX_CAPS_TEXTURE_BLIT = 0x80000ULL
m.BGFX_CAPS_TEXTURE_COMPARE_ALL = 0x300000ULL
m.BGFX_CAPS_TEXTURE_COMPARE_LEQUAL = 0x200000ULL
m.BGFX_CAPS_TEXTURE_CUBE_ARRAY = 0x400000ULL
m.BGFX_CAPS_TEXTURE_DIRECT_ACCESS = 0x800000ULL
m.BGFX_CAPS_TEXTURE_READ_BACK = 0x1000000ULL
m.BGFX_CAPS_VERTEX_ATTRIB_HALF = 0x2000000ULL
m.BGFX_CAPS_VERTEX_ATTRIB_UINT10 = 0x4000000ULL
m.BGFX_CAPS_VERTEX_ID = 0x8000000ULL
m.BGFX_CAPS_FORMAT_TEXTURE_NONE = 0x0ULL
m.BGFX_CAPS_FORMAT_TEXTURE_2D = 0x1ULL
m.BGFX_CAPS_FORMAT_TEXTURE_2D_SRGB = 0x2ULL
m.BGFX_CAPS_FORMAT_TEXTURE_2D_EMULATED = 0x4ULL
m.BGFX_CAPS_FORMAT_TEXTURE_3D = 0x8ULL
m.BGFX_CAPS_FORMAT_TEXTURE_3D_SRGB = 0x10ULL
m.BGFX_CAPS_FORMAT_TEXTURE_3D_EMULATED = 0x20ULL
m.BGFX_CAPS_FORMAT_TEXTURE_CUBE = 0x40ULL
m.BGFX_CAPS_FORMAT_TEXTURE_CUBE_SRGB = 0x80ULL
m.BGFX_CAPS_FORMAT_TEXTURE_CUBE_EMULATED = 0x100ULL
m.BGFX_CAPS_FORMAT_TEXTURE_VERTEX = 0x200ULL
m.BGFX_CAPS_FORMAT_TEXTURE_IMAGE = 0x400ULL
m.BGFX_CAPS_FORMAT_TEXTURE_FRAMEBUFFER = 0x800ULL
m.BGFX_CAPS_FORMAT_TEXTURE_FRAMEBUFFER_MSAA = 0x1000ULL
m.BGFX_CAPS_FORMAT_TEXTURE_MSAA = 0x2000ULL
m.BGFX_CAPS_FORMAT_TEXTURE_MIP_AUTOGEN = 0x4000ULL
m.BGFX_RESOLVE_NONE = 0x0ULL
m.BGFX_RESOLVE_AUTO_GEN_MIPS = 0x1ULL
m.BGFX_PCI_ID_NONE = 0x0ULL
m.BGFX_PCI_ID_SOFTWARE_RASTERIZER = 0x1ULL
m.BGFX_PCI_ID_AMD = 0x1002ULL
m.BGFX_PCI_ID_INTEL = 0x8086ULL
m.BGFX_PCI_ID_NVIDIA = 0x10deULL
m.BGFX_CUBE_MAP_POSITIVE_X = 0x0ULL
m.BGFX_CUBE_MAP_NEGATIVE_X = 0x1ULL
m.BGFX_CUBE_MAP_POSITIVE_Y = 0x2ULL
m.BGFX_CUBE_MAP_NEGATIVE_Y = 0x3ULL
m.BGFX_CUBE_MAP_POSITIVE_Z = 0x4ULL
m.BGFX_CUBE_MAP_NEGATIVE_Z = 0x5ULL

return m

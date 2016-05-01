-- genconstants.t
--
-- use some metaprogramming trickery to extract #define constants
-- for bgfx

local function makeCReturnFunc(funcname, defname)
	local ret = ""
	ret = ret .. "uint64_t " .. funcname .. "() {\n"
	ret = ret .. "    return " .. defname .. ";\n"
	ret = ret .. "}\n"
	return ret
end

local function makeCFile(defpairs)
	local ret =  '#include <stdint.h>\n'
	ret = ret .. '#include "include/bgfxdefines.h"\n\n'
	for defname, funcname in pairs(defpairs) do
		ret = ret .. makeCReturnFunc(funcname, defname)
	end
	return ret
end

local tempbuffer = terralib.new(uint8[255])
local stdio = terralib.includec("stdio.h")

local function formatULLConstant(val)
	stdio.sprintf(tempbuffer, "0x%llxULL", val)
	return ffi.string(tempbuffer)
end

local function getConstantValues(defnames)
	local defpairs = {}
	for idx, dname in ipairs(defnames) do
		defpairs[dname] = "get_bgfxconst_" .. idx
	end

	local cfile = makeCFile(defpairs)
	log.info(cfile)

	local compiled = terralib.includecstring(cfile)

	local ret = {}

	for defname, funcname in pairs(defpairs) do
		local val = compiled[funcname]()
		ret[defname] = val
	end

	return ret
end

function init()
	local defnames = {"BGFX_API_VERSION",
	"BGFX_STATE_RGB_WRITE",
	"BGFX_STATE_ALPHA_WRITE",
	"BGFX_STATE_DEPTH_WRITE",
	"BGFX_STATE_DEPTH_TEST_LESS",
	"BGFX_STATE_DEPTH_TEST_LEQUAL",
	"BGFX_STATE_DEPTH_TEST_EQUAL",
	"BGFX_STATE_DEPTH_TEST_GEQUAL",
	"BGFX_STATE_DEPTH_TEST_GREATER",
	"BGFX_STATE_DEPTH_TEST_NOTEQUAL",
	"BGFX_STATE_DEPTH_TEST_NEVER",
	"BGFX_STATE_DEPTH_TEST_ALWAYS",
	"BGFX_STATE_DEPTH_TEST_SHIFT",
	"BGFX_STATE_DEPTH_TEST_MASK",
	"BGFX_STATE_BLEND_ZERO",
	"BGFX_STATE_BLEND_ONE",
	"BGFX_STATE_BLEND_SRC_COLOR",
	"BGFX_STATE_BLEND_INV_SRC_COLOR",
	"BGFX_STATE_BLEND_SRC_ALPHA",
	"BGFX_STATE_BLEND_INV_SRC_ALPHA",
	"BGFX_STATE_BLEND_DST_ALPHA",
	"BGFX_STATE_BLEND_INV_DST_ALPHA",
	"BGFX_STATE_BLEND_DST_COLOR",
	"BGFX_STATE_BLEND_INV_DST_COLOR",
	"BGFX_STATE_BLEND_SRC_ALPHA_SAT",
	"BGFX_STATE_BLEND_FACTOR",
	"BGFX_STATE_BLEND_INV_FACTOR",
	"BGFX_STATE_BLEND_SHIFT",
	"BGFX_STATE_BLEND_MASK",
	"BGFX_STATE_BLEND_EQUATION_ADD",
	"BGFX_STATE_BLEND_EQUATION_SUB",
	"BGFX_STATE_BLEND_EQUATION_REVSUB",
	"BGFX_STATE_BLEND_EQUATION_MIN",
	"BGFX_STATE_BLEND_EQUATION_MAX",
	"BGFX_STATE_BLEND_EQUATION_SHIFT",
	"BGFX_STATE_BLEND_EQUATION_MASK",
	"BGFX_STATE_BLEND_INDEPENDENT",
	"BGFX_STATE_CULL_CW",
	"BGFX_STATE_CULL_CCW",
	"BGFX_STATE_CULL_SHIFT",
	"BGFX_STATE_CULL_MASK",
	"BGFX_STATE_ALPHA_REF_SHIFT",
	"BGFX_STATE_ALPHA_REF_MASK",
	"BGFX_STATE_PT_TRISTRIP",
	"BGFX_STATE_PT_LINES",
	"BGFX_STATE_PT_LINESTRIP",
	"BGFX_STATE_PT_POINTS",
	"BGFX_STATE_PT_SHIFT",
	"BGFX_STATE_PT_MASK",
	"BGFX_STATE_POINT_SIZE_SHIFT",
	"BGFX_STATE_POINT_SIZE_MASK",
	"BGFX_STATE_MSAA",
	"BGFX_STATE_RESERVED_SHIFT",
	"BGFX_STATE_RESERVED_MASK",
	"BGFX_STATE_NONE",
	"BGFX_STATE_MASK",
	"BGFX_STATE_DEFAULT",
	"BGFX_STATE_BLEND_ADD",
	"BGFX_STATE_BLEND_ALPHA",
	"BGFX_STATE_BLEND_DARKEN",
	"BGFX_STATE_BLEND_LIGHTEN",
	"BGFX_STATE_BLEND_MULTIPLY",
	"BGFX_STATE_BLEND_NORMAL",
	"BGFX_STATE_BLEND_SCREEN",
	"BGFX_STATE_BLEND_LINEAR_BURN",
	"BGFX_STENCIL_FUNC_REF_SHIFT",
	"BGFX_STENCIL_FUNC_REF_MASK",
	"BGFX_STENCIL_FUNC_RMASK_SHIFT",
	"BGFX_STENCIL_FUNC_RMASK_MASK",
	"BGFX_STENCIL_TEST_LESS",
	"BGFX_STENCIL_TEST_LEQUAL",
	"BGFX_STENCIL_TEST_EQUAL",
	"BGFX_STENCIL_TEST_GEQUAL",
	"BGFX_STENCIL_TEST_GREATER",
	"BGFX_STENCIL_TEST_NOTEQUAL",
	"BGFX_STENCIL_TEST_NEVER",
	"BGFX_STENCIL_TEST_ALWAYS",
	"BGFX_STENCIL_TEST_SHIFT",
	"BGFX_STENCIL_TEST_MASK",
	"BGFX_STENCIL_OP_FAIL_S_ZERO",
	"BGFX_STENCIL_OP_FAIL_S_KEEP",
	"BGFX_STENCIL_OP_FAIL_S_REPLACE",
	"BGFX_STENCIL_OP_FAIL_S_INCR",
	"BGFX_STENCIL_OP_FAIL_S_INCRSAT",
	"BGFX_STENCIL_OP_FAIL_S_DECR",
	"BGFX_STENCIL_OP_FAIL_S_DECRSAT",
	"BGFX_STENCIL_OP_FAIL_S_INVERT",
	"BGFX_STENCIL_OP_FAIL_S_SHIFT",
	"BGFX_STENCIL_OP_FAIL_S_MASK",
	"BGFX_STENCIL_OP_FAIL_Z_ZERO",
	"BGFX_STENCIL_OP_FAIL_Z_KEEP",
	"BGFX_STENCIL_OP_FAIL_Z_REPLACE",
	"BGFX_STENCIL_OP_FAIL_Z_INCR",
	"BGFX_STENCIL_OP_FAIL_Z_INCRSAT",
	"BGFX_STENCIL_OP_FAIL_Z_DECR",
	"BGFX_STENCIL_OP_FAIL_Z_DECRSAT",
	"BGFX_STENCIL_OP_FAIL_Z_INVERT",
	"BGFX_STENCIL_OP_FAIL_Z_SHIFT",
	"BGFX_STENCIL_OP_FAIL_Z_MASK",
	"BGFX_STENCIL_OP_PASS_Z_ZERO",
	"BGFX_STENCIL_OP_PASS_Z_KEEP",
	"BGFX_STENCIL_OP_PASS_Z_REPLACE",
	"BGFX_STENCIL_OP_PASS_Z_INCR",
	"BGFX_STENCIL_OP_PASS_Z_INCRSAT",
	"BGFX_STENCIL_OP_PASS_Z_DECR",
	"BGFX_STENCIL_OP_PASS_Z_DECRSAT",
	"BGFX_STENCIL_OP_PASS_Z_INVERT",
	"BGFX_STENCIL_OP_PASS_Z_SHIFT",
	"BGFX_STENCIL_OP_PASS_Z_MASK",
	"BGFX_STENCIL_NONE",
	"BGFX_STENCIL_MASK",
	"BGFX_STENCIL_DEFAULT",
	"BGFX_CLEAR_NONE",
	"BGFX_CLEAR_COLOR",
	"BGFX_CLEAR_DEPTH",
	"BGFX_CLEAR_STENCIL",
	"BGFX_CLEAR_DISCARD_COLOR_0",
	"BGFX_CLEAR_DISCARD_COLOR_1",
	"BGFX_CLEAR_DISCARD_COLOR_2",
	"BGFX_CLEAR_DISCARD_COLOR_3",
	"BGFX_CLEAR_DISCARD_COLOR_4",
	"BGFX_CLEAR_DISCARD_COLOR_5",
	"BGFX_CLEAR_DISCARD_COLOR_6",
	"BGFX_CLEAR_DISCARD_COLOR_7",
	"BGFX_CLEAR_DISCARD_DEPTH",
	"BGFX_CLEAR_DISCARD_STENCIL",
	"BGFX_CLEAR_DISCARD_COLOR_MASK",
	"BGFX_CLEAR_DISCARD_MASK",
	"BGFX_DEBUG_NONE",
	"BGFX_DEBUG_WIREFRAME",
	"BGFX_DEBUG_IFH",
	"BGFX_DEBUG_STATS",
	"BGFX_DEBUG_TEXT",
	"BGFX_BUFFER_NONE",
	"BGFX_BUFFER_COMPUTE_FORMAT_8x1",
	"BGFX_BUFFER_COMPUTE_FORMAT_8x2",
	"BGFX_BUFFER_COMPUTE_FORMAT_8x4",
	"BGFX_BUFFER_COMPUTE_FORMAT_16x1",
	"BGFX_BUFFER_COMPUTE_FORMAT_16x2",
	"BGFX_BUFFER_COMPUTE_FORMAT_16x4",
	"BGFX_BUFFER_COMPUTE_FORMAT_32x1",
	"BGFX_BUFFER_COMPUTE_FORMAT_32x2",
	"BGFX_BUFFER_COMPUTE_FORMAT_32x4",
	"BGFX_BUFFER_COMPUTE_FORMAT_SHIFT",
	"BGFX_BUFFER_COMPUTE_FORMAT_MASK",
	"BGFX_BUFFER_COMPUTE_TYPE_UINT",
	"BGFX_BUFFER_COMPUTE_TYPE_INT",
	"BGFX_BUFFER_COMPUTE_TYPE_FLOAT",
	"BGFX_BUFFER_COMPUTE_TYPE_SHIFT",
	"BGFX_BUFFER_COMPUTE_TYPE_MASK",
	"BGFX_BUFFER_COMPUTE_READ",
	"BGFX_BUFFER_COMPUTE_WRITE",
	"BGFX_BUFFER_DRAW_INDIRECT",
	"BGFX_BUFFER_ALLOW_RESIZE",
	"BGFX_BUFFER_INDEX32",
	"BGFX_BUFFER_COMPUTE_READ_WRITE",
	"BGFX_TEXTURE_NONE",
	"BGFX_TEXTURE_U_MIRROR",
	"BGFX_TEXTURE_U_CLAMP",
	"BGFX_TEXTURE_U_BORDER",
	"BGFX_TEXTURE_U_SHIFT",
	"BGFX_TEXTURE_U_MASK",
	"BGFX_TEXTURE_V_MIRROR",
	"BGFX_TEXTURE_V_CLAMP",
	"BGFX_TEXTURE_V_BORDER",
	"BGFX_TEXTURE_V_SHIFT",
	"BGFX_TEXTURE_V_MASK",
	"BGFX_TEXTURE_W_MIRROR",
	"BGFX_TEXTURE_W_CLAMP",
	"BGFX_TEXTURE_W_BORDER",
	"BGFX_TEXTURE_W_SHIFT",
	"BGFX_TEXTURE_W_MASK",
	"BGFX_TEXTURE_MIN_POINT",
	"BGFX_TEXTURE_MIN_ANISOTROPIC",
	"BGFX_TEXTURE_MIN_SHIFT",
	"BGFX_TEXTURE_MIN_MASK",
	"BGFX_TEXTURE_MAG_POINT",
	"BGFX_TEXTURE_MAG_ANISOTROPIC",
	"BGFX_TEXTURE_MAG_SHIFT",
	"BGFX_TEXTURE_MAG_MASK",
	"BGFX_TEXTURE_MIP_POINT",
	"BGFX_TEXTURE_MIP_SHIFT",
	"BGFX_TEXTURE_MIP_MASK",
	"BGFX_TEXTURE_RT",
	"BGFX_TEXTURE_RT_MSAA_X2",
	"BGFX_TEXTURE_RT_MSAA_X4",
	"BGFX_TEXTURE_RT_MSAA_X8",
	"BGFX_TEXTURE_RT_MSAA_X16",
	"BGFX_TEXTURE_RT_MSAA_SHIFT",
	"BGFX_TEXTURE_RT_MSAA_MASK",
	"BGFX_TEXTURE_RT_WRITE_ONLY",
	"BGFX_TEXTURE_RT_MASK",
	"BGFX_TEXTURE_COMPARE_LESS",
	"BGFX_TEXTURE_COMPARE_LEQUAL",
	"BGFX_TEXTURE_COMPARE_EQUAL",
	"BGFX_TEXTURE_COMPARE_GEQUAL",
	"BGFX_TEXTURE_COMPARE_GREATER",
	"BGFX_TEXTURE_COMPARE_NOTEQUAL",
	"BGFX_TEXTURE_COMPARE_NEVER",
	"BGFX_TEXTURE_COMPARE_ALWAYS",
	"BGFX_TEXTURE_COMPARE_SHIFT",
	"BGFX_TEXTURE_COMPARE_MASK",
	"BGFX_TEXTURE_COMPUTE_WRITE",
	"BGFX_TEXTURE_SRGB",
	"BGFX_TEXTURE_BLIT_DST",
	"BGFX_TEXTURE_READ_BACK",
	"BGFX_TEXTURE_BORDER_COLOR_SHIFT",
	"BGFX_TEXTURE_BORDER_COLOR_MASK",
	"BGFX_TEXTURE_RESERVED_SHIFT",
	"BGFX_TEXTURE_RESERVED_MASK",
	"BGFX_TEXTURE_SAMPLER_BITS_MASK",
	"BGFX_RESET_NONE",
	"BGFX_RESET_FULLSCREEN",
	"BGFX_RESET_FULLSCREEN_SHIFT",
	"BGFX_RESET_FULLSCREEN_MASK",
	"BGFX_RESET_MSAA_X2",
	"BGFX_RESET_MSAA_X4",
	"BGFX_RESET_MSAA_X8",
	"BGFX_RESET_MSAA_X16",
	"BGFX_RESET_MSAA_SHIFT",
	"BGFX_RESET_MSAA_MASK",
	"BGFX_RESET_VSYNC",
	"BGFX_RESET_MAXANISOTROPY",
	"BGFX_RESET_CAPTURE",
	"BGFX_RESET_HMD",
	"BGFX_RESET_HMD_DEBUG",
	"BGFX_RESET_HMD_RECENTER",
	"BGFX_RESET_FLUSH_AFTER_RENDER",
	"BGFX_RESET_FLIP_AFTER_RENDER",
	"BGFX_RESET_SRGB_BACKBUFFER",
	"BGFX_RESET_HIDPI",
	"BGFX_RESET_DEPTH_CLAMP",
	"BGFX_RESET_SUSPEND",
	"BGFX_RESET_RESERVED_SHIFT",
	"BGFX_RESET_RESERVED_MASK",
	"BGFX_CAPS_TEXTURE_COMPARE_LEQUAL",
	"BGFX_CAPS_TEXTURE_COMPARE_ALL",
	"BGFX_CAPS_TEXTURE_3D",
	"BGFX_CAPS_VERTEX_ATTRIB_HALF",
	"BGFX_CAPS_VERTEX_ATTRIB_UINT10",
	"BGFX_CAPS_INSTANCING",
	"BGFX_CAPS_RENDERER_MULTITHREADED",
	"BGFX_CAPS_FRAGMENT_DEPTH",
	"BGFX_CAPS_BLEND_INDEPENDENT",
	"BGFX_CAPS_COMPUTE",
	"BGFX_CAPS_FRAGMENT_ORDERING",
	"BGFX_CAPS_SWAP_CHAIN",
	"BGFX_CAPS_HMD",
	"BGFX_CAPS_INDEX32",
	"BGFX_CAPS_DRAW_INDIRECT",
	"BGFX_CAPS_HIDPI",
	"BGFX_CAPS_TEXTURE_BLIT",
	"BGFX_CAPS_TEXTURE_READ_BACK",
	"BGFX_CAPS_OCCLUSION_QUERY",
	"BGFX_CAPS_FORMAT_TEXTURE_NONE",
	"BGFX_CAPS_FORMAT_TEXTURE_2D",
	"BGFX_CAPS_FORMAT_TEXTURE_2D_SRGB",
	"BGFX_CAPS_FORMAT_TEXTURE_2D_EMULATED",
	"BGFX_CAPS_FORMAT_TEXTURE_3D",
	"BGFX_CAPS_FORMAT_TEXTURE_3D_SRGB",
	"BGFX_CAPS_FORMAT_TEXTURE_3D_EMULATED",
	"BGFX_CAPS_FORMAT_TEXTURE_CUBE",
	"BGFX_CAPS_FORMAT_TEXTURE_CUBE_SRGB",
	"BGFX_CAPS_FORMAT_TEXTURE_CUBE_EMULATED",
	"BGFX_CAPS_FORMAT_TEXTURE_VERTEX",
	"BGFX_CAPS_FORMAT_TEXTURE_IMAGE",
	"BGFX_CAPS_FORMAT_TEXTURE_FRAMEBUFFER",
	"BGFX_CAPS_FORMAT_TEXTURE_FRAMEBUFFER_MSAA",
	"BGFX_CAPS_FORMAT_TEXTURE_MSAA",
	"BGFX_VIEW_NONE",
	"BGFX_VIEW_STEREO",
	"BGFX_SUBMIT_EYE_LEFT",
	"BGFX_SUBMIT_EYE_RIGHT",
	"BGFX_SUBMIT_EYE_MASK",
	"BGFX_SUBMIT_EYE_FIRST",
	"BGFX_SUBMIT_RESERVED_SHIFT",
	"BGFX_SUBMIT_RESERVED_MASK",
	"BGFX_PCI_ID_NONE",
	"BGFX_PCI_ID_SOFTWARE_RASTERIZER",
	"BGFX_PCI_ID_AMD",
	"BGFX_PCI_ID_INTEL",
	"BGFX_PCI_ID_NVIDIA",
	"BGFX_HMD_NONE",
	"BGFX_HMD_DEVICE_RESOLUTION",
	"BGFX_HMD_RENDERING",
	"BGFX_CUBE_MAP_POSITIVE_X",
	"BGFX_CUBE_MAP_NEGATIVE_X",
	"BGFX_CUBE_MAP_POSITIVE_Y",
	"BGFX_CUBE_MAP_NEGATIVE_Y",
	"BGFX_CUBE_MAP_POSITIVE_Z",
	"BGFX_CUBE_MAP_NEGATIVE_Z"}

	local ullvals = getConstantValues(defnames)

	local ret = "--Autogenerated bgfx constants\nlocal m = {}\n\n"
	for defname, defval in pairs(ullvals) do
		ret = ret .. "m." .. defname .. " = " .. formatULLConstant(defval) .. "\n"
	end
	ret = ret .. "\nreturn m\n"

	log.info(ret)
end

function update()
	-- just quit immediately
	core.truss.truss_stop_interpreter(core.TRUSS_ID)
end
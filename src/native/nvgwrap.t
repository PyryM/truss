local m = {}

function m.build(options, built_systems)
  local DBGPRINT = options.DBGPRINT
  local build = require("core/build.t")
  local headerparse = require("native/headerparser.t")
  local ByteBuffer = require("native/buffer.t").ByteBuffer
  local HEADER_FN = "bgfx/nanovg_terra.h"

  local FS = built_systems and built_systems.fs
  print("NanoVG building w/ FS support!", FS ~= nil)

  local BANNED_FUNCTIONS = {
    nvgCreateC = true,
    nvgDeleteC = true
  }

  local c = build.includec(HEADER_FN)
  local nvg_func_info = headerparse.parse_header_file(HEADER_FN)

  local SizedString = require("native/commontypes.t").SizedString

  local struct NVGContext {
    ctx: &c.NVGcontext;
    width: float;
    height: float;
  }

  local MAX_CONTEXTS = options.max_nanovg_contexts or 4
  local struct NanoVG {
    contexts: NVGContext[MAX_CONTEXTS]
  }

  if FS then
    table.insert(NVGContext.entries, {"_fs", &FS.ctype})
    table.insert(NanoVG.entries, {"_fs", &FS.ctype})
  end

  local function rename(s)
    local prefix = s:sub(1,3):lower()
    if prefix ~= "nvg" then return nil end
    if BANNED_FUNCTIONS[s] then return nil end
    local first_two_letters = s:sub(4,5)
    if first_two_letters:upper() == first_two_letters then
      -- Functions like nvgRGBA -> rgba instead of rGBA
      return s:sub(4,-1):lower()
    else
      local first_letter = s:sub(4,4):lower()
      local remainder = s:sub(5,-1)
      return first_letter .. remainder
    end
  end

  local function find_argname(funcname, arg_idx)
    local info = nvg_func_info[funcname]
    if info and info.args[arg_idx] then
      return info.args[arg_idx][1]
    else
      return "_a" .. arg_idx 
    end  
  end

  local constants = {}

  for func_name, func in pairs(c) do
    local renamed = rename(func_name)
    if renamed and terralib.type(func) == "terrafunction" then
      local is_member_func, arg_start = false, 1
      if func.definition.type.parameters[1] == &c.NVGcontext then
        is_member_func = true
        arg_start = 2
      end
      local args = {}
      for idx = arg_start, #func.definition.type.parameters do
        local argtype = func.definition.type.parameters[idx]
        local argname = find_argname(func_name, idx)
        --"_a" .. (idx-arg_start+1)
        table.insert(args, terralib.newsymbol(argtype, argname))
      end
      if is_member_func then
        NVGContext.methods[renamed] = terra(self: &NVGContext, [args])
          return func(self.ctx, [args])
        end
      else -- static function
        NVGContext.methods[renamed] = terra(self: &NVGContext, [args])
          return func([args])
        end
      end
      NVGContext.methods[renamed]:setname(renamed)
    elseif renamed and terralib.type(func) == 'number' then
      local const_name = renamed:upper()
      if const_name:sub(1,1) == "_" then
        const_name = const_name:sub(2,-1)
      end
      constants[const_name] = func
    end
  end

  terra NVGContext:_init()
    self.ctx = nil
    self.width = 0
    self.height = 0
  end

  if FS then
    terra NVGContext:init(fs: &FS.ctype)
      self._fs = fs
      self:_init()
    end
  else
    terra NVGContext:init()
      self:_init()
    end
  end

  terra NVGContext:create(edgeaa: bool, viewid: uint16)
    self:shutdown()
    var aa: int32 = 0
    if edgeaa then aa = 1 end
    self.ctx = c.nvgCreateC(aa, viewid)
  end

  terra NVGContext:shutdown()
    if self.ctx == nil then return end
    c.nvgDeleteC(self.ctx)
    self.ctx = nil
  end

  terra NVGContext:begin_view(viewid: uint16, width: float, height: float)
    c.nvgSetViewIdC(self.ctx, viewid)
    c.nvgBeginFrame(self.ctx, width, height, 1.0)
    self.width = width
    self.height = height
  end

  terra NVGContext:end_view()
    c.nvgEndFrame(self.ctx)
  end

  terra NVGContext:create_font_raw(name: &int8, font_data: &int8, font_data_size: uint32): int32
    -- HACK: we intentionally leak memory here because of questionble NVG behavior!
    var buffer: ByteBuffer
    buffer:init()
    buffer:copy([&uint8](font_data), font_data_size)
    return c.nvgCreateFontMem(self.ctx, name, buffer.data, buffer.datasize, 0)
  end

  terra NVGContext:create_font_str(name: &int8, font_data: SizedString): int32
    -- HACK: we intentionally leak memory here because of questionble NVG behavior!
    var buffer: ByteBuffer
    buffer:init()
    buffer:copy([&uint8](font_data.str), font_data.len)
    return c.nvgCreateFontMem(self.ctx, name, buffer.data, buffer.datasize, 0)
  end

  terra NVGContext:create_image_rgba_str(imdata: SizedString, w: int32, h: int32, flags: int32): int32
    if imdata.len < w*h*4 then return -1 end
    return c.nvgCreateImageRGBA(self.ctx, w, h, flags, [&uint8](imdata.str))
  end

  -- Warning! No safety checks AT ALL!
  terra NVGContext:update_image_rgba_str(image: int32, imdata: SizedString)
    c.nvgUpdateImage(self.ctx, image, [&uint8](imdata.str))
  end

  terra NVGContext:image_size(image: int32): {int32, int32}
    var w: int32 = -1
    var h: int32 = -1
    c.nvgImageSize(self.ctx, image, &w, &h)
    return w, h
  end

  -- convenience function to draw an image
  terra NVGContext:image(im: int32, x: float, y: float, w: float, h: float, alpha: float)
    c.nvgBeginPath(self.ctx)
    if w < 0.0 or h < 0.0 then
      var iw: int32 = -1
      var ih: int32 = -1
      c.nvgImageSize(self.ctx, im, &iw, &ih)
      w = iw
      h = ih
    end
    var patt = c.nvgImagePattern(self.ctx, x, y, w, h, 0.0, im, alpha)
    c.nvgFillPaint(self.ctx, patt)
    c.nvgRect(self.ctx, x, y, w, h)
    c.nvgFill(self.ctx)
  end

  terra NVGContext:text_cstr(x: float, y: float, text: &int8): float
    var ss: SizedString
    ss:from_c_string(text)
    return c.nvgText(self.ctx, x, y, text, text + ss.len)
  end

  if FS then
    local imageload = require("gfx/imageload.t")

    terra NVGContext:load_png_image(fnpw: SizedString, flags: int32): int32
      if self._fs == nil then
        [DBGPRINT("NanoVG has nil FS!")]
        return -1
      end
      var data = self._fs:read(fnpw)
      if data.data == nil or data.datasize == 0 then return -1 end

      var imdata: imageload.C.bgfx_util_imagedata
      imdata.data = nil
      imdata.datasize = 0
      if not imageload.C.igBGFXUtilDecodeImage(data.data, data.datasize, &imdata) then
        [DBGPRINT("Error decoding image")]
        data:release()
        return -1
      end
      if imdata.datasize ~= imdata.width * imdata.height * 4 then
        [DBGPRINT("Image is not RGBA? %d * %d * 4 != %d", `imdata.width, `imdata.height, `imdata.datasize)]
        imageload.C.igBGFXUtilReleaseImage(&imdata)
        data:release()
        return -1
      else
        [DBGPRINT("Loaded RGBA image %d x %d", `imdata.width, `imdata.height)]
      end
      var image_id = c.nvgCreateImageRGBA(self.ctx, imdata.width, imdata.height, flags, imdata.data)
      imageload.C.igBGFXUtilReleaseImage(&imdata)
      data:release()
      return image_id
    end

    terra NVGContext:load_png_image_str(fnpw: &int8, flags: int32): int32
      var s: SizedString
      s:from_c_string(fnpw)
      return self:load_png_image(s, flags)
    end
  end

  if FS then
    terra NanoVG:init(fs: &FS.ctype): bool
      for idx = 0, MAX_CONTEXTS do
        self.contexts[idx]:init(fs)
      end
      return true
    end
  else
    terra NanoVG:init(): bool
      for idx = 0, MAX_CONTEXTS do
        self.contexts[idx]:init()
      end
      return true
    end
  end

  terra NanoVG:max_contexts(): uint32
    return MAX_CONTEXTS
  end

  terra NanoVG:get_context(idx: uint32): &NVGContext
    if idx >= 0 and idx < MAX_CONTEXTS then
      return &(self.contexts[idx])
    else
      return nil
    end
  end

  local function add_bindings(built, bindname, binder)
    local isjit = binder:lua_version() == "jit"
    print("Is luajit?", isjit)
    binder:add_binding(built.NVGContext, {classname = "nvgcontext", ffi_api = isjit})
    binder:add_binding(built.NanoVG, {classname = bindname, ffi_api = isjit})
    binder:add_constants(constants, {namespace = "nvg"})
  end

  return {
    ctype = NanoVG,
    bind = add_bindings,
    NanoVG = NanoVG,
    NVGContext = NVGContext,
    const = constants,
  }
end

function m.default()
  if not m._default then
    m._default = m.build{}
  end
  return m._default
end

return m
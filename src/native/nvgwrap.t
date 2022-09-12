local m = {}

function m.build(options, built_systems)
  local build = require("core/build.t")
  local headerparse = require("native/headerparser.t")
  local HEADER_FN = "bgfx/nanovg_terra.h"

  local c = build.includec(HEADER_FN)
  local nvg_func_info = headerparse.parse_header_file(HEADER_FN)

  local SizedString = require("native/commontypes.t").SizedString

  local struct NVGContext {
    ctx: &c.NVGcontext;
  }

  local function rename(s)
    local prefix = s:sub(1,3):lower()
    if prefix ~= "nvg" then return nil end
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
    elseif renamed and terralib.type(func) == 'number' then
      local const_name = renamed:upper()
      if const_name:sub(1,1) == "_" then
        const_name = const_name:sub(2,-1)
      end
      constants[const_name] = func
    end
  end

  terra NVGContext:init()
    self.ctx = nil
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

  terra NVGContext:set_view(viewid: uint16)
    c.nvgSetViewIdC(self.ctx, viewid)
  end

  terra NVGContext:create_font_raw(name: &int8, font_data: &uint8, font_data_size: uint32): int32
    -- final 0 argument indicates that nanovg should not free the data
    return c.nvgCreateFontMem(self.ctx, name, font_data, font_data_size, 0)
  end

  terra NVGContext:creat_font_str(name: &int8, font_data: SizedString): int32
    -- final 0 argument indicates that nanovg should not free the data
    return c.nvgCreateFontMem(self.ctx, name, [&uint8](font_data.str), font_data.len, 0)
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

  local MAX_CONTEXTS = options.max_nanovg_contexts or 4
  local struct NanoVG {
    contexts: NVGContext[MAX_CONTEXTS]
  }

  terra NanoVG:init(): bool
    for idx = 0, MAX_CONTEXTS do
      self.contexts[idx]:init()
    end
    return true
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
    binder:add_binding(built.NVGContext, {classname = "nvgcontext"})
    binder:add_binding(built.NanoVG, {classname = bindname})
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
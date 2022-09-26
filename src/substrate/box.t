-- substrate/box.t
--
-- a 'boxed' value (owned, dynamically allocated pointer)

local m = {}
local lazy = require("./lazyload.t")
local util = require("./util.t")

function m._Box(T, options)
  assert(T, "No type provided!")
  options = options or {}
  local cfg = options.cfg or require("./cfg.t").configure()
  local size_t = assert(cfg.size_t, "No size_t!")
  local derive = require("./derive.t")
  local intrinsics = require("./intrinsics.t")

  local FREE = cfg.FREE
  local ASSERT = cfg.ASSERT
  local LOG = cfg.LOG

  local struct Box {
    val: &T;
  }

  terra Box:init()
    self.val = nil
  end

  terra Box:release()
    if self.val == nil then return end
    escape
      if T.methods and T.methods.release then
        emit(quote self.val:release() end)
      end
    end
    [FREE(`self.val)]
    self.val = nil
  end

  terra Box:clear()
    self:release()
  end

  if derive.can_init_by_zeroing(T) then
    terra Box:allocate()
      self:release()
      self.val = [cfg.ALLOCATE_ZEROED(T)]
    end
  else
    terra Box:allocate()
      self:release()
      self.val = [cfg.ALLOCATE(T)]
      self.val:init()
    end
  end

  terra Box:copy(rhs: &Box)
    self:release()
    if not rhs:is_filled() then 
      return
    end
    self.val = [cfg.ALLOCATE(T)]
    [derive.copy(`self.val, `rhs.val)]
  end

  terra Box:get_ref(): &T
    if self.val == nil then self:allocate() end
    return self.val
  end

  terra Box:is_filled(): bool
    return self.val ~= nil
  end

  Box.substrate = {
    allow_move_by_memcpy = true
  }

  util.set_template_name(Box, options.typename or "Box", T)

  return Box
end

m.Box = terralib.memoize(function(T)
  return m._Box(T)
end)

m.exported_names = {"Box"}

return m
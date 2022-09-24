-- native/box.t
--
-- a 'boxed' value

local m = {}
local c = require("substrate/clib.t")
local tutil = require("native/typeutils.t")

function m.box(T, options)
  options = options or {}

  local struct Box {
    val: &T;
  }

  -- TODO: refactor all these default allocators somewhere?
  local allocate = options.allocate or function(T)
    return `[&T](c.std.malloc(sizeof(T)))
  end

  local free = options.free or function(v)
    return quote c.std.free(v) end
  end

  terra Box:init()
    self.val = nil
  end

  terra Box:allocate()
    self:release()
    self.val = [allocate(T)]
    escape
      if T.methods and T.methods.init then
        emit(quote self.val:init() end)
      end
    end
  end

  terra Box:release()
    escape
      if T.methods and T.methods.release then
        emit(quote 
          if self.val ~= nil then self.val:release() end
        end)
      end
    end
    [free(`self.val)]
    self.val = nil
  end

  terra Box:copy(rhs: &Box)
    if not rhs:is_filled() then 
      self:clear()
      return 
    end
    self:allocate()
    [tutil.copy(`self.val, `rhs.val)]
  end

  terra Box:clear()
    self:release()
  end

  terra Box:get_ref(): &T
    if self.val == nil then self:allocate() end
    return self.val
  end

  terra Box:is_filled(): bool
    return self.val ~= nil
  end

  if options.name or T.name then
    --Box:setname("Box_" .. (options.name or T.name))
    Box.name = "Box_" .. (options.name or T.name) -- ????
  end

  return Box
end

function m.build(options)
  return terralib.memoize(function(T)
    return m.box(T, options)
  end)
end

return m
-- native/vector.t
--
-- think 'dynamic array' not 'xyz'

local c = require("substrate/clib.t")
local utils = require("native/typeutils.t")
local m = {}

function m.vec(T, options)
  options = options or {}
  local size_t = options.size_t or uint64
  local allocate = options.allocate or function(T, n)
    n = n or 1
    return `[&T](c.std.malloc(sizeof(T) * [n]))
  end
  local free = options.free or function(v)
    return quote c.std.free(v) end
  end

  local function init_val(v) return quote end end
  local function init_items(data, startpos, endpos) return quote end end
  local function release_items(data, startpos, endpos) return quote end end

  if options.default then
    init_val = function(v) return quote v = [options.default] end end
    init_items = function(data, startpos, endpos)
      return quote
        for pos = startpos, endpos do
          data[pos] = [options.default]
        end
      end
    end
  elseif T.methods and T.methods.init then
    init_val = function(v) return quote v:init() end end
    init_items = function(data, startpos, endpos)
      return quote
        for pos = startpos, endpos do
          data[pos]:init()
        end
      end
    end
  end

  -- WARNING: source of subtle bugs is inconsisten use of release vs. clear
  local clearfunc = T.methods and (T.methods.release or T.methods.clear)
  if clearfunc then
    release_items = function(data, startpos, endpos)
      return quote
        for pos = startpos, endpos do
          clearfunc(&data[pos])
        end
      end
    end
  end

  local struct Vec {
    data: &T;
    size: size_t;
    capacity: size_t;
  }

  terra Vec:init()
    self.data = nil
    self.size = 0
    self.capacity = 0
  end

  terra Vec:resize_capacity(new_capacity: size_t)
    var new_data = [allocate(T, new_capacity)]
    var ncopy = self.size
    if ncopy > new_capacity then ncopy = new_capacity end
    if self.data ~= nil then
      if ncopy > 0 then
        c.str.memcpy([&uint8](new_data), 
                     [&uint8](self.data), 
                     sizeof(T)*ncopy)
      end
      if new_capacity < self.size then
        [release_items(`self.data, ncopy, `self.size)]
      end
      [free(`self.data)]
    end
    if new_capacity > ncopy then
      [init_items(new_data, ncopy, new_capacity)]
    end
    self.data = new_data
    self.capacity = new_capacity
    if self.size > self.capacity then
      self.size = self.capacity
    end
  end

  terra Vec:clear()
    [release_items(`self.data, 0, `self.size)]
    self.size = 0
  end

  terra Vec:release()
    [release_items(`self.data, 0, `self.size)]
    [free(`self.data)]
    self.data = nil
    self.size = 0
    self.capacity = 0
  end

  terra Vec:_adjust_capacity(newsize: size_t)
    if self.capacity >= newsize then return end
    var newcap = self.capacity
    if newcap == 0 then newcap = newsize end
    while newcap < newsize do
      newcap = newcap * 2
    end
    self:resize_capacity(newcap)
  end

  terra Vec:resize(newsize: size_t)
    self:_adjust_capacity(newsize)
    self.size = newsize
  end

  if utils.is_trivially_serializable(T) then
    terra Vec:push_raw_bytes(bytes: &uint8, len: size_t)
      var nitems: size_t = len / sizeof(T)
      self:_adjust_capacity(self.size + nitems)
      c.str.memcpy([&uint8](self.data + self.size), 
                  bytes, 
                  nitems * sizeof(T))
      self.size = self.size + nitems
    end

    terra Vec:get_raw_bytes(pos: size_t, n: size_t): {&uint8, size_t}
      if pos+n > self.size then return {nil, 0} end
      return {[&uint8](self.data + pos), sizeof(T)*n}
    end
  end

  -- Note: we're relying on return-type inference here
  terra Vec:get_ref(idx: size_t)
    if idx >= self.size then return nil end
    escape
      if T.methods and T.methods.get_ref then
        emit(quote return self.data[idx]:get_ref() end)
      else
        emit(quote return self.data + idx end)
      end
    end
  end

  -- Note: we're relying on return-type inference here
  terra Vec:push_new()
    self:_adjust_capacity(self.size+1)
    var item_idx = self.size
    self.size = self.size + 1
    --This isn't necessary because resize will have taken care
    --of init!
    --[init_val(`self.data[item_idx])]
    return self:get_ref(item_idx)
  end

  -- hmm
  if T:isprimitive() then
    terra Vec:push(v: T)
      @(self:push_new()) = v
    end

    terra Vec:get(idx: size_t): T
      if idx >= self.size then return [T](0) end
      return self.data[idx]
    end
  else
    terra Vec:push(v: &T)
      @(self:push_new()) = @v
    end

    terra Vec:get(idx: size_t)
      return self:get_ref(idx)
    end
  end

  terra Vec:length(): size_t
    return self.size
  end

  terra Vec:copy(rhs: &Vec)
    self:clear()
    for idx = 0, rhs:length() do
      var src = rhs:get_ref(idx)
      var dest = self:push_new()
      [utils.copy(`dest, `src)]
    end
  end

  return Vec
end

function m.build(options)
  return terralib.memoize(function(T)
    return m.vec(T, options)
  end)
end

return m
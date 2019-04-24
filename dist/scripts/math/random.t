-- math/random.t
--
-- random number generators

local rand = math.random
local Vector = require("./vec.t").Vector
local m = {}

function m.set_random_generator(_rand)
  rand = _rand
end

function m.choice(options)
  return options[math.floor(rand()*#options) + 1]
end

function m.rand_normal()
  return math.sqrt(-2 * math.log(rand())) * math.cos(2 * math.pi * rand())
end

function m.rand_symmetric()
  return rand()*2.0 - 1.0
end

function m.rand_vector(v)
  v = v or Vector()
  v:set(m.rand_symmetric(), 
        m.rand_symmetric(), 
        m.rand_symmetric(), 
        m.rand_symmetric())
  return v
end

function m.rand_spherical(v)
  -- rejection sample for now
  v = v or Vector()
  v:set(1,1,1)
  while v:length3() > 1.0 do
    m.rand_vector(v)
  end
  return v
end

return m
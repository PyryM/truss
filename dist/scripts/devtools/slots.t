-- devtools/slots.t
--
-- simulates a slot machine in the terminal.......

local m = {}
local icons      =   {"🍇","🍈","🍉","🍊","🍋","🍌","🍍","🍎"}
local point_vals =  {  4,   5,   6,   7,  8,   9,  10,  11}
local function rand_choice(optlist)
  local idx = math.random(#optlist)
  return optlist[idx], idx
end

local function reseed()
  math.randomseed(os.time())
  -- the early outputs of math.random() have poor entropy
  for i = 1,20 do math.random() end
end

function m.do_slots(need_reseed)
  if need_reseed then reseed() end
  local vpoints = {}
  local vals = {}
  for i = 1,3 do
    local v, vidx = rand_choice(icons)
    vals[i] = v
    vpoints[v] = (vpoints[v] or 1) * point_vals[vidx]
  end
  local total_points = 0
  for _, pv in pairs(vpoints) do
    total_points = total_points + pv
  end
  return "[" .. table.concat(vals, " |") .. " ] => " .. total_points .. "pts"
end

return m

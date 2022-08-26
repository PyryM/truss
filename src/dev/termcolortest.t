local function init()
  local term = truss.term
  for row = 0, 7 do
    local colfrags = {}
    for col = 0, 7 do
      local linidx = row*8 + col
      local b = linidx % 4
      linidx = math.floor(linidx / 4)
      local g = linidx % 4
      linidx = math.floor(linidx / 4)
      local r = linidx % 4
      local fg = {255, 255, 255}
      local bg = {r * 64, g * 64, b * 64}
      local block = term.color_rgb(fg, bg) .. "    " .. term.RESET
      table.insert(colfrags, block)
    end
    print(table.concat(colfrags))
  end
end

return {init = init}
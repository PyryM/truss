local IG = require("imgui").C

local m = {}

terra m.set_truss_style_defaults()
  var style = IG.GetStyle()
  -- borders
  style.WindowBorderSize = 1.0
  style.WindowRounding = 1.0
  style.ChildRounding = 1.0
  style.PopupRounding = 1.0
  style.FrameRounding = 1.0
  style.ScrollbarRounding = 1.0
  style.GrabRounding = 1.0
  style.TabRounding = 1.0
  --ImVec2 WindowPadding;
  style.WindowMenuButtonPosition = IG.Dir_Right
end

return m
local IG = require("./imgui.t").C

local m = {}

terra m.set_truss_style_defaults()
  var style = IG.GetStyle()
  -- borders
  style.WindowBorderSize = 1.0
  style.WindowRounding = 3.0
  style.ChildRounding = 1.0
  style.PopupRounding = 3.0
  style.FrameRounding = 2.0
  style.ScrollbarRounding = 1.0
  style.GrabRounding = 1.0
  style.TabRounding = 1.0
  --ImVec2 WindowPadding;
  --style.WindowMenuButtonPosition = IG.Dir_Right
end

m.DEFAULT_STYLE_WEIGHTS = {
  Text={weights={1.0,0.0,0.0,0.0}, alpha=1.0},
  TextDisabled={weights={0.512283855465719,0.4876599918142111,3.455776047216554e-05,2.1594994615924815e-05}, alpha=1.0},
  ChildBg={weights={0.0,1.0,0.0,0.0}, alpha=0.0},
  FrameBgActive={weights={0.0,0.0,1.0,0.0}, alpha=0.67},
  FrameBgHovered={weights={0.0,0.0,1.0,0.0}, alpha=0.4},
  TextSelectedBg={weights={0.0,0.0,1.0,0.0}, alpha=0.35},
  TitleBgActive={weights={0.0,0.49059914270716115,0.5094008572928395,0.0}, alpha=1.0},
  FrameBg={weights={0.0,0.49059914270716115,0.5094008572928395,0.0}, alpha=0.54},
  MenuBarBg={weights={0.10071879555290286,0.8992247998089072,3.678996251060009e-05,1.9612346696585606e-05}, alpha=1.0},
  TitleBg={weights={0.0,1.0,0.0,0.0}, alpha=1.0},
  PopupBg={weights={0.02169152775165635,0.9782660300626993,2.7102999024399582e-05,1.5339191965565677e-05}, alpha=0.94},
  WindowBg={weights={0.0,1.0,0.0,0.0}, alpha=0.94},
  ModalWindowDimBg={weights={0.8120993110681702,0.18782430887184218,4.47815181337652e-05,3.159859712891801e-05}, alpha=0.35},
  NavWindowingDimBg={weights={0.8120993110681702,0.18782430887184218,4.47815181337652e-05,3.159859712891801e-05}, alpha=0.2},
  ScrollbarBg={weights={0.0,1.0,0.0,0.0}, alpha=0.53},
  TitleBgCollapsed={weights={0.0,1.0,0.0,0.0}, alpha=0.51},
  Border={weights={0.0882362671341797,0.3562576678749062,0.3939963114570715,0.16150975353384264}, alpha=0.5},
  BorderShadow={weights={0.0,1.0,0.0,0.0}, alpha=0.0},
  ScrollbarGrab={weights={0.30549004845795086,0.6944592412476251,3.249622507722874e-05,1.821545065465038e-05}, alpha=1.0},
  ScrollbarGrabHovered={weights={0.4164651912010524,0.5834804409359785,3.402369565198331e-05,2.034417888842051e-05}, alpha=1.0},
  ScrollbarGrabActive={weights={0.5227309649141881,0.4772143757247564,3.365150191794415e-05,2.100789906705905e-05}, alpha=1.0},
  CheckMark={weights={0.0,0.0,1.0,0.0}, alpha=1.0},
  SliderGrab={weights={0.0,0.08789802278734093,0.9121019772126594,0.0}, alpha=1.0},
  SliderGrabActive={weights={0.0,0.0,1.0,0.0}, alpha=1.0},
  Button={weights={0.0,0.0,1.0,0.0}, alpha=0.4},
  ButtonHovered={weights={0.0,0.0,1.0,0.0}, alpha=1.0},
  ButtonActive={weights={0.0,0.0,1.0,0.0}, alpha=1.0},
  Header={weights={0.0,0.0,1.0,0.0}, alpha=0.31},
  HeaderHovered={weights={0.0,0.0,1.0,0.0}, alpha=0.8},
  HeaderActive={weights={0.0,0.0,1.0,0.0}, alpha=1.0},
  Separator={weights={0.0882362671341797,0.3562576678749062,0.3939963114570715,0.16150975353384264}, alpha=0.5},
  SeparatorHovered={weights={0.0,0.18751344879782633,0.8124865512021756,0.0}, alpha=0.78},
  SeparatorActive={weights={0.0,0.18751344879782633,0.8124865512021756,0.0}, alpha=1.0},
  ResizeGrip={weights={0.0,0.0,1.0,0.0}, alpha=0.2},
  ResizeGripHovered={weights={0.0,0.0,1.0,0.0}, alpha=0.67},
  ResizeGripActive={weights={0.0,0.0,1.0,0.0}, alpha=0.95},
  Tab={weights={0.0,0.38682765151935616,0.6131723484806445,0.0}, alpha=0.86},
  TabHovered={weights={0.0,0.0,1.0,0.0}, alpha=0.8},
  TabActive={weights={0.0,0.28635968035875903,0.7136403196412413,0.0}, alpha=1.0},
  TabUnfocused={weights={0.0,0.8750642148882074,0.12493578511179342,0.0}, alpha=0.97},
  TabUnfocusedActive={weights={0.0,0.5582762035098405,0.4417237964901602,0.0}, alpha=1.0},
  PlotLines={weights={0.6252763089709155,0.37466348343264483,3.6341604777921566e-05,2.386603566110204e-05}, alpha=1.0},
  PlotLinesHovered={weights={0.0,0.029855642247936704,0.27908969249536564,0.6910546652566976}, alpha=1.0},
  PlotHistogram={weights={0.0,0.0,0.0,1.0}, alpha=1.0},
  PlotHistogramHovered={weights={0.0,0.005008765241890982,0.005764682806178459,0.9892265519519305}, alpha=1.0},
  TableHeaderBg={weights={0.10916958169683753,0.8040455480624765,0.06219178633358813,0.02459308390709796}, alpha=1.0},
  TableBorderStrong={weights={0.09721401905146065,0.5718832308254018,0.2354783013817418,0.0954244487413958}, alpha=1.0},
  TableBorderLight={weights={0.10486472691365965,0.7243964318306582,0.12198217013689899,0.04875667111878329}, alpha=1.0},
  TableRowBg={weights={0.0,1.0,0.0,0.0}, alpha=0.0},
  TableRowBgAlt={weights={1.0,0.0,0.0,0.0}, alpha=0.06},
  DragDropTarget={weights={0.0,0.0,0.0,1.0}, alpha=0.9},
  NavHighlight={weights={0.0,0.0,1.0,0.0}, alpha=1.0},
  NavWindowingHighlight={weights={1.0,0.0,0.0,0.0}, alpha=0.7}
}

function m.build_color_setter(options)
  local colorspaces = require("math/colorspaces.t")

  options = options or {}
  local weights = options.style_weights or m.DEFAULT_STYLE_WEIGHTS

  local terra add_weighted(dest: &float, src: &float, weight: float)
    for idx = 0, 3 do
      dest[idx] = dest[idx] + src[idx]*weight
    end
  end

  local terra color_comb(dest: &float, refs: &float, weights: &float)
    for chan = 0, 4 do dest[chan] = 0.0 end
    for idx = 0, 4 do
      add_weighted(dest, refs + idx*4, weights[idx])
    end
    dest[3] = weights[4]
  end

  local l_color_indices, l_weights = {}, {}, {}
  local NUM_COLORS = 0
  for colorname, colorinfo in pairs(weights) do
    NUM_COLORS = NUM_COLORS + 1
    table.insert(l_color_indices, IG["Col_" .. colorname])
    for ii = 1, 4 do
      table.insert(l_weights, colorinfo.weights[ii])
    end
    table.insert(l_weights, colorinfo.alpha)
  end
  assert(#l_color_indices == NUM_COLORS)
  assert(#l_weights == NUM_COLORS*5)

  local c_color_indices = terralib.constant(`arrayof([uint32], [l_color_indices]))
  local c_weights = terralib.constant(`arrayof([float], [l_weights]))

  local terra set_colors(ref_lab_colors: &float)
    var style = IG.GetStyle()
    var cur_color: float[4]
    for i = 0, NUM_COLORS do
      color_comb(cur_color, ref_lab_colors, c_weights + i*5)
      colorspaces.lab2rgb(cur_color, cur_color, true)
      style.Colors[c_color_indices[i]] = IG.Vec4{cur_color[0], cur_color[1], cur_color[2], cur_color[3]} 
    end
  end

  return set_colors
end

return m
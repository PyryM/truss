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
  --style.WindowMenuButtonPosition = IG.Dir_Right
end

local EH = {
Text                   = {1.00, 1.00, 1.00, 1.00},
TextDisabled           = {0.50, 0.50, 0.50, 1.00},

ChildBg                = {0.00, 0.00, 0.00, 0.00},

FrameBgActive          = {0.26, 0.59, 0.98, 0.67},
FrameBgHovered         = {0.26, 0.59, 0.98, 0.40},
TextSelectedBg         = {0.26, 0.59, 0.98, 0.35},
TitleBgActive          = {0.16, 0.29, 0.48, 1.00},
FrameBg                = {0.16, 0.29, 0.48, 0.54},


MenuBarBg              = {0.14, 0.14, 0.14, 1.00},
TitleBg                = {0.04, 0.04, 0.04, 1.00},
PopupBg                = {0.08, 0.08, 0.08, 0.94},
WindowBg               = {0.06, 0.06, 0.06, 0.94},


ModalWindowDimBg       = {0.80, 0.80, 0.80, 0.35},
NavWindowingDimBg      = {0.80, 0.80, 0.80, 0.20},


ScrollbarBg            = {0.02, 0.02, 0.02, 0.53},
TitleBgCollapsed       = {0.00, 0.00, 0.00, 0.51},


Border                 = {0.43, 0.43, 0.50, 0.50},
BorderShadow           = {0.00, 0.00, 0.00, 0.00},


ScrollbarGrab          = {0.31, 0.31, 0.31, 1.00},
ScrollbarGrabHovered   = {0.41, 0.41, 0.41, 1.00},
ScrollbarGrabActive    = {0.51, 0.51, 0.51, 1.00},

CheckMark              = {0.26, 0.59, 0.98, 1.00},
SliderGrab             = {0.24, 0.52, 0.88, 1.00},
SliderGrabActive       = {0.26, 0.59, 0.98, 1.00},

Button                 = {0.26, 0.59, 0.98, 0.40},
ButtonHovered          = {0.26, 0.59, 0.98, 1.00},
ButtonActive           = {0.06, 0.53, 0.98, 1.00},

Header                 = {0.26, 0.59, 0.98, 0.31},
HeaderHovered          = {0.26, 0.59, 0.98, 0.80},
HeaderActive           = {0.26, 0.59, 0.98, 1.00},

Separator              = {0.43, 0.43, 0.50, 0.50},
SeparatorHovered       = {0.10, 0.40, 0.75, 0.78},
SeparatorActive        = {0.10, 0.40, 0.75, 1.00},

ResizeGrip             = {0.26, 0.59, 0.98, 0.20},
ResizeGripHovered      = {0.26, 0.59, 0.98, 0.67},
ResizeGripActive       = {0.26, 0.59, 0.98, 0.95},

Tab                    = {0.18, 0.35, 0.58, 0.86},
TabHovered             = {0.26, 0.59, 0.98, 0.80},
TabActive              = {0.20, 0.41, 0.68, 1.00},

TabUnfocused           = {0.07, 0.10, 0.15, 0.97},
TabUnfocusedActive     = {0.14, 0.26, 0.42, 1.00},

PlotLines              = {0.61, 0.61, 0.61, 1.00},
PlotLinesHovered       = {1.00, 0.43, 0.35, 1.00},
PlotHistogram          = {0.90, 0.70, 0.00, 1.00},
PlotHistogramHovered   = {1.00, 0.60, 0.00, 1.00},

TableHeaderBg          = {0.19, 0.19, 0.20, 1.00},
TableBorderStrong      = {0.31, 0.31, 0.35, 1.00},
TableBorderLight       = {0.23, 0.23, 0.25, 1.00},

TableRowBg             = {0.00, 0.00, 0.00, 0.00},
TableRowBgAlt          = {1.00, 1.00, 1.00, 0.06},

DragDropTarget         = {1.00, 1.00, 0.00, 0.90},
NavHighlight           = {0.26, 0.59, 0.98, 1.00},

NavWindowingHighlight  = {1.00, 1.00, 1.00, 0.70},
}



return m
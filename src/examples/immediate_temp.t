local w, h = gfx.backbuffer_width, gfx.backbuffer_height

local dye_in = gfx.ColorDepthTarget{
  width = w, height = h, depth_format = false, 
  color_format = assert(gfx.TEX_RGBA32F)
}
local dye_out = dye_in:clone()
local pressure_in = gfx.ColorDepthTarget{
  width = w, height = h, depth_format = false, 
  color_format = assert(gfx.TEX_R32F)
}
local pressure_out = pressure_in:clone()
local divergence = pressure_in:clone()
local velocity_in = gfx.ColorDepthTarget{
  width = w, height = h, depth_format = false, 
  color_format = assert(gfx.TEX_RG32F)
}
local velocity_out = velocity_in:clone()

ctx:fullscreen{
  program = {"vs_fluid_base", "fs_fluid_divergence"},
  s_texVelocity = {0, velocity_in},
  target = divergence
}

ctx:fullscreen{
  program = {"vs_fluid_base", "fs_fluid_dissipate"},
  s_texSource = {0, pressure_in},
  u_fluidParams = math.Vector(TIMESTEP, VELOCITY_DISSIPATION, PRESSURE_DISSIPATION, 0),
  target = pressure_out
}
pressure_in, pressure_out = pressure_out, pressure_in -- swap

for i = 1, PRESSURE_ITERATIONS do
  ctx:fullscreen{
    program = {"vs_fluid_base", "fs_fluid_pressure"},
    s_texPressure = {0, pressure_in},
    s_texDivergence = {1, divergence},
    target = pressure_out
  }
  pressure_in, pressure_out = pressure_out, pressure_in -- swap
end

ctx:fullscreen{
  program = {"vs_fluid_base", "fs_fluid_gradsub"},
  s_texVelocity = {0, velocity_in},
  s_texPressure = {1, pressure_in},
  target = velocity_out
}
velocity_in, velocity_out = velocity_out, velocity_in -- swap

ctx:fullscreen{
  program = {"vs_fluid_base", "fs_fluid_advection"},
  s_texVelocity = {0, velocity_in},
  s_texSource   = {1, velocity_in},
  u_fluidParams = math.Vector(TIMESTEP, VELOCITY_DISSIPATION, PRESSURE_DISSIPATION),
  u_dissipateColor = math.Vector(0, 0, 0, 0),
  target = velocity_out
}
velocity_in, velocity_out = velocity_out, velocity_in -- swap

ctx:fullscreen{
  program = {"vs_fluid_base", "fs_fluid_advection"},
  s_texVelocity = {0, velocity_in},
  s_texSource   = {1, dye_in},
  u_fluidParams = math.Vector(TIMESTEP, DYE_DISSIPATION, PRESSURE_DISSIPATION),
  u_dissipateColor = math.Vector(0, 0, 0, 0),
  target = dye_out
}
dye_in, dye_out = dye_out, dye_in -- swap

ctx:fullscreen{
  program = {"vs_fluid_base", "fs_fluid_splat"},
  state = {blend = 'add', depth_test = 'false'},
  u_splatPoint = state.splat_point, 
  u_splatColor = state.splat_color,
  target = dye_in
}

ctx:fullscreen{
  program = {"vs_fluid_base", "fs_fluid_splat"},
  state = {blend = 'add', depth_test = 'false'},
  u_splatPoint = state.splat_point, 
  u_splatColor = state.splat_velocity,
  target = velocity_in
}

ctx:copy{
  src = dye_in, dest = gfx.backbuffer, shader = "fs_fullscreen_copy_gamma"
}
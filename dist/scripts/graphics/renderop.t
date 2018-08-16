-- graphics/renderop.t
--
-- an individual rendering operation

local RenderOperation = class("RenderOperation")
m.RenderOperation = RenderOperation

function RenderOperation:init()
  -- nothing in particular to do
end

function RenderOperation:bind_stage(stage)
  self.stage = stage
  self.opfunc = self:bind_to(stage)
end

function RenderOperation:bind_to(stage)
  return function(component, tf)
    self:apply(component, tf)
  end
end

local CompiledOp = RenderOperation:extend("CompiledOp")
m.CompiledOp = CompiledOp

function CompiledOp:init(options)
  options = options or {}
  self._filter = options.filter
end

function CompiledOp:bind_to(stage)
  return function(renderable, tf)
    renderable.drawcall:submit(stage.view._viewid, stage.globals, tf)
  end
end

function CompiledOp:bind_stage(stage)
  if self._func then truss.error("Render op already bound!") end
  self._func = self:bind_to(stage)
  self._multi_func = function(renderable, tf)
    renderable.drawcall:multi_submit(stage._start_view_id, stage._num_views,
                                     stage.globals, tf)
  end
end

function CompiledOp:matches(tags)
  if not tags.compiled then return nil end
  if self._filter and not self._filter(tags) then return nil end
  return self._func, self._multi_func
end

-- TODO: compiled multirendering
--[[
local MultiRenderOperation = RenderOperation:extend("MultiRenderOperation")
m.MultiRenderOperation = MultiRenderOperation

function MultiRenderOperation:multi_render(contexts, component)
  truss.error("Base MultiRenderOperation should never actually :multi_render!")
end

function MultiRenderOperation:to_multiview_function(contexts)
  return function(component)
    self:multi_render(contexts, component)
  end
end

function GenericRenderOp:_replacement_render(context, component)
  local geo, mat = component.geo, self._replacement_mat
  generic_render(geo, mat, component.ent, context)
end

local function generic_multi_render(geo, mat, entity, contexts)
  -- render to multiple contexts/views, using the 'preserve_state' flag
  -- in bgfx.submit to try to minimize the number of bgfx function calls
  -- (in most cases will greatly reduce the number of uniform set calls)
  if not entity.visible_world then return end
  if (not geo) or (not mat) then return end
  if not mat.program then return end
  gfx.set_transform(entity.matrix_world)
  geo:bind()
  mat:bind()
  local nctx = #contexts
  local last_globals = nil
  for idx, ctx in ipairs(contexts) do
    if ctx.globals ~= last_globals then
      mat:bind_globals(ctx.globals)
    end
    last_globals = ctx.globals
    local preserve_state = (idx ~= nctx)
    gfx.submit(ctx.view, mat.program, nil, preserve_state)
  end
end

function GenericRenderOp:multi_render(contexts, component)
  local geo, mat = component.geo, component.mat
  generic_multi_render(geo, mat, component.ent, contexts)
end

function GenericRenderOp:_replacement_multi_render(context, component)
  local geo, mat = component.geo, self._replacement_mat
  generic_multi_render(geo, mat, component.ent, context)
end
]]
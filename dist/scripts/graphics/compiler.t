-- graphics/compiler.t
--
-- the renderop compiler

local m = {}

-- general flow:
--    pipeline:compile()
--
--   renderable:compile() -->
--    compile_ops(renderable, ops) -->
--     op.stage:compile_op(op)

function m.compile_pipeline(pipeline)
  -- TODO
end

-- returns
function m.compile_ops(comp, ops)
  local expressions = {}
  local typeinfo = {}
  local newops = {}
  local stageinfo = {}
  local has_compiled = false
  for idx, op in ipairs(ops) do
    if op.can_compile and op:can_compile() then
      op:compile(expressions, typeinfo, stageinfo)
      has_compiled = true
    else
      table.insert(newops, op)
    end
  end
  table.insert(newops, m.create_stager(comp, stageinfo, typeinfo))
  table.insert(newops, m._finalize_compilation(comp, typeinfo, expressions))
  comp._render_staging = terralib.new(typeinfo.ttype)
  return newops
end

return m

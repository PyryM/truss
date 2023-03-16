-- lua/node_compat
--
-- attempts to provide a few interfaces to mimic
-- nodejs for TSTL usage.

local m = {}

-- node fs functions:
--
-- fs.readdirSync(path[, options])
--   path <string>
--   options: ignored
-- Returns: <string[]>

return m
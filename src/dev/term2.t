-- dev/term2.t
--
-- extra terminal utils

local m = {}
m.settings = {
  cols = 80,
  indent = 2
}

function m.setup(options)
  truss.extend_table(m.settings, options)
end

local BlockPrinter = truss.nanoclass("BlockPrinter")
m.BlockPrinter = BlockPrinter

BlockPrinter.DEFAULT_STYLE = {
  horizontal_top = "-",
  corner_top = "",
  vertical = "|",
  corner_bottom = "",
  horizontal_bottom = "-",
}

function BlockPrinter:init()
  self.scopes = truss.Stack()
  self:_update_scope()
  self.width = m.settings.cols
end

function BlockPrinter:enter_block(new_style, text)
  style = truss.extend_table({}, BlockPrinter.DEFAULT_STYLE)
  if new_style then
    style = truss.extend_table(style, new_style)
  end
  self.scopes:push(style)
  self:_update_scope()
end

function BlockPrinter:leave_block(text)
  self.scopes:pop()
  self:_update_scope()
end

function BlockPrinter:_update_scope()
  self.cur_scope = {
    style = self.scopes[-1] or BlockPrinter.DEFAULT_STYLE,
    gutter = self:_get_gutter()
  }
end

function BlockPrinter:_get_gutter()
  local frags = {}
  for idx = 1, self.scopes:size() do
    frags[idx] = self.scopes[idx].vertical
  end
  return table.concat(frags)
end

function BlockPrinter:print(...)
  print(self.cur_scope.gutter, ...)
end

return m
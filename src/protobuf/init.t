local moduleutils = require("core/module.t")

local protobuf = {}

moduleutils.include_submodules({
  "protobuf/gen.t",
  "protobuf/schemaparser.t",
}, protobuf)

return protobuf
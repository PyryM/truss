local moduleutils = require("core/module.t")

local protobuf = {}

moduleutils.include_submodules({
  "native/protobuf/gen.t",
  "native/protobuf/schemaparser.t",
}, protobuf)

return protobuf
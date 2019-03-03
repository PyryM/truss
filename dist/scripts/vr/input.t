-- vr/input.t
--
-- 'new' openvr input system

local m = {}
local class = require("class")
local openvr = nil
local openvr_c = nil
local input_ptr = nil

function m.init(_parent)
  openvr_c = _parent.c_api
  openvr = _parent

  local addonfuncs = truss.addons.openvr.functions
  local addonptr   = truss.addons.openvr.pointer

  -- TODO: cast this for actual type checking?
  input_ptr = addonfuncs.truss_openvr_get_input(addonptr)
end

function m._write_manifest(manifest)
  if not truss.absolute_data_path then
    truss.error("Installing a manifest requires an absolute data path to be set!")
  end
  m.manifest_path = truss.absolute_data_path .. "/openvr_actions.json"
  return m.manifest_path
end

function m.install_manifest(manifest)
  local path = m._write_manifest(manifest or m.create_default_manifest())
  openvr_c.SetActionManifestPath(input_ptr, path)
end


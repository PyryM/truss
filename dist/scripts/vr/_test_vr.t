-- test parts of vr that can reasonably be tested
-- without actually starting vr

local testlib = require("devtools/test.t")
local test = testlib.test
local vrinput = require("vr/input.t")
local json = require("lib/json.lua")
local m = {}

local function test_manifest_generation(t)
  local action_sets = vrinput.generate_action_sets{
    main = {
      description = "My Game Actions",
      usage = 'leftright',
      actions = {
        OpenInventory = {
          kind = 'boolean',
          requirement = 'mandatory',
          description = "Open Inventory"
        },
        RightHand = {
          kind = 'pose',
          description = "Right Hand"
        }
      }
    },
    driving = {
      HonkHorn = {
        kind = 'boolean',
        requirement = 'optional',
        description = "Honk Horn"
      },
      Throttle = {
        kind = 'vector1',
        requirement = 'suggested'
      }
    }
  }
  local manifest = vrinput._action_sets_to_manifest(action_sets)
  local expected_manifest = require("vr/default_action_manifest.lua")
  t.expect(manifest, expected_manifest, "Manifest generated correctly", function(a,b)
    return json:encode_pretty(a) .. " vs. " .. json:encode_pretty(b)
  end)
end

function m.run()
  test("VR Input Manifest Generation", test_manifest_generation)
end

return m
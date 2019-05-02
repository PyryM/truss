-- gfx/tests.t
--

local m = {}

function m.run(test)
  test("tagset", m.test_tagset)
end

function m.test_tagset(t)
  local tagset = require("./tagset.t")

  local tostring_count = 0
  local sentinel = setmetatable({}, {
    __tostring = function()
      tostring_count = tostring_count + 1
      return "sv"
    end
  })

  local s1 = tagset.tagset{a = sentinel, b = 12}
  local h1 = s1.hash
  local h2 = s1.hash
  t.ok(tostring_count == 1, "hash was called once")
  t.ok(h1 == h2, "hash has not changed")
  s1.b = nil
  local h3 = s1.hash
  t.ok(tostring_count == 2, "hash was called again")
  t.ok(h1 ~= h3, "hash has changed")

  s1 = tagset.tagset{b = 12.0, a = 'sv'}
  local s2 = tagset.tagset{a = 'sv', b = 12}
  t.expect(s1.hash, s2.hash, "separately created hashes are identical")

  local s3 = tagset.tagset{a = 'sv', b = 11}
  t.ok(s1.hash ~= s3.hash, "hashes are different")

  local s4 = s1:clone()
  t.expect(s1.hash, s4.hash, "cloned tagset has same hash")
  s4.a = 'sx'
  t.ok(s1.hash ~= s4.hash, "changing clone doesn't change original")

  local sa = tagset.tagset{x = 12}
  sa:extend{y = true}
  local sb = tagset.tagset{x = 12, y = true}
  t.expect(sa.hash, sb.hash, "extension with plain table works")

  sa = tagset.tagset{x = 12}
  sa:extend(tagset.tagset{y = true})
  t.expect(sa.hash, sb.hash, "extension with other tagset works")
end

return m
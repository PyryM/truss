local m = {}

function m.init(jape)
  (jape or require("dev/jape.t")).describe("procgen", function(jape)
    require("./_test_strongrand.t").init(jape)
    require("./_test_murmur.t").init(jape)
  end)
end

return m
local m = {}

function m.init(jape)
  (jape or require("dev/jape.t")).describe("substrate", function(jape)
    require("./_test_array.t").init(jape)
    require("./_test_assert.t").init(jape)
    require("./_test_derives.t").init(jape)
    require("./_test_file.t").init(jape)
    require("./_test_intrinsics.t").init(jape)
    require("./_test_utf8.t").init(jape)
  end)
end

return m
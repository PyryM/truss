local m = {}

local function test_files(jape)
  local substrate = require("substrate")
  local File = substrate.File
  local ByteArray = substrate.ByteArray
  local StringSlice = substrate.StringSlice
  local ffi = require("ffi")
  local test, expect = jape.test, jape.expect

  local function as_string(buff)
    return ffi.string(buff.data, buff.size)
  end

  local function test_read(desc, filecontents)
    -- TODO: setup and teardown?
    test(desc, function()
      local dest = terralib.new(ByteArray)
      dest:init()
      dest:allocate(2^16)
    
      local filename = os.tmpname()
      local outfile = io.open(filename, "wb")
    
      outfile:write(filecontents)
      outfile:close()
    
      local infile = terralib.new(File)
      infile:init()
      expect(infile:open(filename, false)):to_be_truthy()
    
      infile:read_all_into(dest, false)
      expect(tonumber(dest.size)):to_be(#filecontents)
      expect(as_string(dest)):to_be(filecontents)
    
      infile:close()
      os.remove(filename)
      dest:release()
    end)
  end

  test_read("text", [[
    “Here they saw such huge troops of whales, that they were forced to proceed with a great deal of caution for fear they should run their ship upon them.” —Schouten’s Sixth Circumnavigation.
    “We set sail from the Elbe, wind N.E. in the ship called The Jonas-in-the-Whale. * * *    
    Some say the whale can’t open his mouth, but that is a fable. * * *
    They frequently climb up the masts to see whether they can see a whale, for the first discoverer has a ducat for his pains. * * *
    I was told of a whale taken near Shetland, that had above a barrel of herrings in his belly. * * *    
    One of our harpooneers told me that he caught once a whale in Spitzbergen that was white all over.” —A Voyage to Greenland, A.D. 1671. Harris Coll. 
  ]])

  local zeros = string.rep(string.char(0), 2048)
  test_read("all zeros", zeros)
end

function m.init(jape)
  (jape or require("dev/jape.t")).describe("test files", test_files)
end

return m
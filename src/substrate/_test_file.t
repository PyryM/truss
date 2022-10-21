local m = {}

local function test_file(t)
  local substrate = require("substrate")
  local File = substrate.File
  local ByteArray = substrate.ByteArray
  local StringSlice = substrate.StringSlice
  local ffi = require("ffi")

  local function as_string(buff)
    return ffi.string(buff.data, buff.size)
  end

  local function test_read(filedesc, filecontents)
    local dest = terralib.new(ByteArray)
    dest:init()
    dest:allocate(2^16)
  
    local filename = os.tmpname()
    t.print("tempname: " .. filename)
    local outfile = io.open(filename, "wb")
  
    outfile:write(filecontents)
    outfile:close()
  
    local infile = terralib.new(File)
    infile:init()
    t.ok(infile:open(filename, false), filedesc .. ": opened")
  
    infile:read_all_into(dest, false)
    t.expect(tonumber(dest.size), #filecontents, filedesc .. ": read back correct size")
    t.expect(as_string(dest), filecontents, filedesc .. ": read back correct file contents")
  
    infile:close()
    os.remove(filename)
    dest:release()
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

function m.run(test)
  test("file basics", test_file)
end

return m
-- terrapeg.t
--
-- parsing expression grammars in terra
-- metaprograms a recursive descent parser without packratting, so
-- your grammar could very well have exponential runtime

-- MIT license
-- or alternatively you may use the revised Crowley license, in which
-- "do whatever you want" is the whole of the license

-- the resulting parser is a pure Terra function (ie, does not call into lua)
-- which means you can freely pass it into C, or even save it as a .obj file to
-- be imported by other native code

local terrapeg = {}

struct terrapeg.CaptureEntry_t {
    id: uint32;
    startpos: uint32;
    endpos: uint32;
}

struct terrapeg.CaptureBuffer_t {
    maxsize: uint32;
    pos: uint32;
    buff: &terrapeg.CaptureEntry_t;
}
local CB = terrapeg.CaptureBuffer_t

-- allocates a capture buffer
function terrapeg.capturebuffer(maxsize)
    local ret = terralib.new(CB)
    ret.maxsize = maxsize
    ret.pos = 0
    local data = terralib.new(terrapeg.CaptureEntry_t[maxsize])
    ret.buff = data
    return {cb = ret, buff = data}
end

-- copy and null terminate a string
-- dest must have size at least n+1
local terra strcpy_nt(rawsrc: &int8, dest: &uint8, n: int)
    var src: &uint8 = [&uint8](rawsrc)
    for i = 0,n do
        dest[i] = src[i]
    end
    dest[n] = 0 -- null terminate just to be safe
end

-- convert a string into a terra value (int8 array)
local function stringToTerra(s)
    local n = s:len()
    local ret = terralib.new(uint8[n+1])
    strcpy_nt(s, ret, n)
    return ret
end

-- convert a string into a terra constant
local function stringToConstant(s)
    local tstr = stringToTerra(s)
    local tconst = terralib.constant(tstr)
    return {tstr = tstr, tconst = tconst, slen = s:len()}
end

-- create a 'symbol' (forward function declaration)
-- terrapeg parsers are just compositions of functions, so mutually
-- recursive symbols need to be forward declared
function terrapeg.symbol()
    local terra symbol_ :: {&uint8, int, int, &CB} -> {bool, int}
    return symbol_
end

-- define a symbol
-- needed because of quirks in terra syntax
function terrapeg.define(symbol, patt)
    terra symbol(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        return patt(src, pos, slen, cbuff)
    end
end

-- create a terra function that pattern matches a literal
function terrapeg.literal(s)
    local const_info = stringToConstant(s)
    local const_str = const_info.tconst
    local terra literal_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        -- Square brackets in terra indicate an escape: the string length
        -- will be evaluated to a literal value as if it were a #define
        if slen - pos < [const_info.slen] then
            return false, pos
        end
        var offset_src = (src + pos)
        for i = 0,[const_info.slen] do
            if offset_src[i] ~= const_str[i] then
                return false, pos
            end
        end
        return true, pos + [const_info.slen]
    end
    return literal_
end

-- create a terra function that matches a single byte in a set
-- implemented in the naive (but space-saving) way of simply iterating
function terrapeg.byteset(s)
    local const_info = stringToConstant(s)
    local const_str = const_info.tconst
    local terra byteset_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        if slen - pos < 1 then -- not a single byte of space left
            return false, pos
        end
        var srcval = src[pos]
        for i = 0,[const_info.slen] do
            if srcval == const_str[i] then
                return true, pos+1
            end
        end
        return false, pos
    end
    return byteset_
end

-- convert a string into a constant lookup table
local function stringToConstantLUT(s)
    local tstr = stringToTerra(s)
    local lut = terralib.new(uint8[256])
    for i = 1,256 do
        lut[i-1] = 0
    end
    for i = 1,s:len() do
        lut[tstr[i-1]] = 1
    end
    local lutconst = terralib.constant(lut)
    return {lut = lut, lutconst = lutconst}
end

-- match a single byte out of a set
-- implemented by building a big (256 byte) lookup table
function terrapeg.fast_byteset(s)
    local const_info = stringToConstantLUT(s)
    local const_lut = const_info.lutconst
    local terra fastbyteset_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        if slen - pos < 1 then -- not a single byte of space left
            return false, pos
        end
        if const_lut[src[pos]] > 0 then
            return true, pos+1
        else
            return false, pos
        end
    end
    return fastbyteset_
end

-- create a terra function that will match any exactly n *bytes*
function terrapeg.any_n(n)
    local nn = n
    local terra any_n_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        if slen - pos < [nn] then
            return false, pos
        else
            return true, pos + [nn]
        end
    end
    return any_n_
end

-- create a terra function that matches minmatches or more repetitions
-- of the given pattern
function terrapeg.min_reps(patt, minmatches)
    local terra min_reps_(src: &uint8, pos: int, slen: int,  cbuff: &CB) : {bool, int}
        var p0 : int32 = pos -- save position in case we fail and need to revert
        var succeeded : bool = true
        var nsuccesses : int32 = -1 -- we always get one 'free' success
        while succeeded do
            succeeded, pos = patt(src, pos, slen, cbuff)
            nsuccesses = nsuccesses + 1
        end
        if nsuccesses >= minmatches then
            return true, pos
        else
            return false, p0
        end
    end
    return min_reps_
end

-- helper function to create a list of terra statements (quotes) that
-- try to match the sequence of all patterns
local function listcall_(patterns, success, src, pos, oldp, slen, cb)
    local stmts = terralib.newlist()
    for _, patt in ipairs(patterns) do
        local stmnt = quote
            success, pos = patt(src, pos, slen, cb)
            if not success then
                return false, oldp
            end
        end
        stmts:insert(stmnt)
    end
    return stmts
end

-- create a terra function that matches the sequence of patterns in order
function terrapeg.sequence(patterns)
    local terra sequence_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var oldpos: int = pos
        var success: bool = true
        [listcall_(patterns, success, src, pos, oldpos, slen, cbuff)]
        return true, pos
    end
    return sequence_
end

-- like listcall_, but matches as soon as it finds a matching subpattern
local function switchcall_(patterns, success, src, pos, newp, slen, cb)
    local stmts = terralib.newlist()
    local npatts = #patterns
    for idx, patt in ipairs(patterns) do
        local stmnt
        if idx < npatts then
            stmnt = quote
                success, newp = patt(src, pos, slen, cb)
                if success then
                    return true, newp
                end
            end
        else -- be tail call/recursion friendly on last pattern
            stmnt = quote
                return patt(src, pos, slen, cb)
            end
        end
        stmts:insert(stmnt)
    end
    return stmts
end

-- create a terra function that matches an "ordered choice" of patterns
function terrapeg.choice(patterns)
    local terra choice_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var success: bool = true
        var newp: int = 0
        [switchcall_(patterns, success, src, pos, newp, slen, cbuff)]
    end
    return choice_
end

-- create a terra function that matches 0 or 1 repetitions of patt
-- note that this always succeeds
function terrapeg.option(patt)
    local terra option_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var success: bool
        var npos: int
        success, npos = patt(src, pos, slen, cbuff)
        if success then
            return success, npos
        else
            return true, pos
        end
    end
    return option_
end

-- create a terra function that succeeds if patt fails, consuming no input
function terrapeg.negation(patt)
    local terra negation_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var success, npos = patt(src, pos, slen, cbuff)
        return not success, pos
    end
    return negation_
end

-- create a terra function that succeeds as patt, but consumes no input
function terrapeg.test(patt)
    local terra test_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var success, _ = patt(src, pos, slen, cbuff)
        return success, pos
    end
    return test_
end

-- a terra function that matches only at the end of a string
terra terrapeg.stringend(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
    return pos == slen, pos
end

-- a terra function that matches only at the beginning of a string
-- (not strictly ever needed: just query at 0)
terra terrapeg.stringstart(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
    return pos == 0, pos
end

-- create a terra function that captures what it is enclosing
function terrapeg.capture(patt, id)
    local terra cap_(src: &uint8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var oldcbpos = cbuff.pos
        var capturestart = pos
        var success: bool
        var endpos: int
        var ourentry: &terrapeg.CaptureEntry_t = &(cbuff.buff[cbuff.pos])
        cbuff.pos = (cbuff.pos + 1) % cbuff.maxsize -- corrupt rather overflow
        success, endpos = patt(src, pos, slen, cbuff)
        if success then
            ourentry.id = id
            ourentry.startpos = capturestart
            ourentry.endpos = endpos
        else
            -- roll back capture buffer
            cbuff.pos = oldcbpos
        end
        return success, endpos
    end
    return cap_
end

return terrapeg

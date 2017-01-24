local tpeg = require('sandbox/terrapeg.t')
local stringutils = require('utils/stringutils.t')

local m = {}
m.verbose = false

function m.createPeg()
    -- local b64chars_str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    -- local b64chars = tpeg.fast_byteset(b64chars_str)

    local digits = tpeg.fast_byteset("0123456789")

    local whitespaceChars = tpeg.fast_byteset(" \t")
    local whitespace_opt = tpeg.min_reps(whitespaceChars, 0)
    local whitespace_req = tpeg.min_reps(whitespaceChars, 1)

    local integerpatt = tpeg.min_reps(digits, 1)

    -- local b64str = tpeg.sequence{
    --     tpeg.literal('"'),
    --     tpeg.capture(tpeg.min_reps(b64chars, 0), 23),
    --     tpeg.literal('"')
    -- }
    --b64str:disas()
    --local b64strcap = tpeg.capture(b64str, 23)

    local patt = tpeg.sequence{
        whitespace_opt,
        tpeg.literal("["),
        whitespace_opt,
        tpeg.literal('"broadcast"'),
        whitespace_opt,
        tpeg.literal(","),
        whitespace_opt,
        tpeg.literal('"depthdata"'),
        whitespace_opt,
        tpeg.literal(","),
        whitespace_opt,
        tpeg.capture(integerpatt, 11),
        whitespace_opt,
        tpeg.literal(","),
        whitespace_opt,
        tpeg.capture(tpeg.literal('"'), 12)
    }

    m.patt = patt
    m.cb = tpeg.capturebuffer(200)
    m.b64lut = stringutils.createB64LUT_()
end

local terra substr_decode(src: &uint8, srcpos: uint32, srclen: uint32,
                         dest: &uint8, destlen: uint32,
                         lut: &uint8) : uint32
    var offset_src: &uint8 = &(src[srcpos])
    return stringutils.b64decode_terra(offset_src, srclen, dest, destlen, lut)
end

function m.decode(msg, target, targetsize)
    if m.patt == nil then
        m.createPeg()
    end
    local patt = m.patt
    local cb = m.cb.cb
    cb.pos = 0
    local msg_ptr = terralib.cast(&uint8, msg)
    local msglen = msg:len()
    --log.info("msglen: " .. msglen)
    local stime = tic()
    local ret = m.patt(msg_ptr, 0, msglen, cb)
    local dtime = toc(stime)
    --log.debug("Pattern match took " .. dtime*1000.0 .. " ms")

    local startpos = cb.buff[0].startpos
    local endpos = cb.buff[0].endpos
    local cid = cb.buff[0].id

    local startpos1 = cb.buff[1].startpos
    local endpos1 = cb.buff[1].endpos
    local cid1 = cb.buff[1].id

    if m.verbose then
        log.debug("cb: " .. cid .. ": " .. startpos .. " -> " .. endpos)
        log.debug("cb: " .. cid1 .. ": " .. startpos1 .. " -> " .. endpos1)
    end

    if cb.pos > 0 and ret._0 then
        if m.verbose then
            log.debug("match!")
        end

        stime = tic()
        local datalen = tonumber(msg:sub(startpos+1,endpos))
        --log.info("Datalen: " .. datalen)
        datalen = math.min(datalen, msglen - endpos1)
        local ndecoded = substr_decode(msg_ptr, endpos1, datalen,
                            target, targetsize,
                            m.b64lut)
        dtime = toc(stime)
        --log.debug("B64 decode took " .. dtime*1000.0 .. " ms")
        return ndecoded
    else
        return 0
    end
end

return m

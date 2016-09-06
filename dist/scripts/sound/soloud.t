-- soloud.t
--
-- bindings for the soloud sound library

local m = {}
local class = require("class")

-- define some classes
local SoloudWav = class("SoloudWav")
local SoloudSpeech = class("SoloudSpeech")

-- link the dynamic library (should only happen once ideally)
terralib.linklibrary("soloud")
local soloud_ = terralib.includec("soloud_c.h")

function m.init()
    m.instance_ = soloud_.Soloud_create()
    local instance = m.instance_
    local result = soloud_.Soloud_init(instance)
    if result ~= 0 then
        log.error("Soloud_init error: " .. result)
        m.instance_ = nil -- leaks a tiny bit of memory, but if soloud init
                          -- failed it might be unsafe to Soloud_destroy()
    else
        log.info("Soloud_init successful.")
    end
    m.rawWavs_ = {}
    m.aliasedWavs_ = {}
end

local terra castWavToSoundSource(wav: &soloud_.Wav)
    var result: &soloud_.AudioSource = [&soloud_.AudioSource](wav)
    return result
end

local terra castSpeechToSoundSource(speech: &soloud_.Speech)
    var result: &soloud_.AudioSource = [&soloud_.AudioSource](speech)
    return result
end

function m.createSpeech()
    return SoloudSpeech()
end

function m.loadWav(filename, alias)
    alias = alias or filename
    local data = truss.truss_load_file(filename)
    if data == nil then
        log.error("Unable to load wavefile " .. filename 
                    .. ": low-level error (file doesn't exist?)")
        return nil
    end

    local sound = soloud_.Wav_create()
    -- the 1,0 args are copy = true, takeOwnership = false
    -- (so that it copies the data and doesn't take ownership of our pointer)
    local result = soloud_.Wav_loadMemEx(sound, data.data, data.data_length, 1, 0)
    truss.truss_release_message(data)

    if result == 0 then
        m.rawWavs_[filename] = sound
        m.aliasedWavs_[alias] = sound
        log.info("Loaded " .. filename .. " --> " .. alias)
        return m.getWavByName(alias)
    else
        local estring = ffi.string(soloud_.Soloud_getErrorString(m.instance_, result))
        log.error("Error interpreting sound file " .. filename .. ": " .. estring)
        return nil
    end
end

function m.getWavByName(alias)
    return SoloudWav(m.aliasedWavs_, alias)
end

function SoloudWav:init(tableref, alias)
    self.target_ = tableref
    self.alias_ = alias
end

function SoloudWav:play(volume, pan)
    local rawsound = self:getPointer_()
    if rawsound == nil then return end
    local aSound = castWavToSoundSource(rawsound)
    soloud_.Soloud_playEx(m.instance_, 
                          aSound,
                          volume or -1.0,
                          pan or 0.0,
                          0, 0)
end

function SoloudWav:stop()
    local rawsound = self:getPointer_()
    if not rawsound then return end
    soloud_.Wav_stop(rawsound)
end

function SoloudWav:getPointer_()
    return self.target_[self.alias_]
end

function SoloudWav:setLooping(looping)
    local loopint = 0
    if looping then loopint = 1 end
    local rawsound = self:getPointer_()
    if not rawsound then return end
    soloud_.Wav_setLooping(rawsound, loopint)
end

function SoloudSpeech:init()
    self.pointer_ = soloud_.Speech_create()
end

function SoloudSpeech:say(text, volume, pan)
    soloud_.Speech_setText(self.pointer_, text)
    local aSound = castSpeechToSoundSource(self.pointer_)
    soloud_.Soloud_playEx(m.instance_, 
                          aSound,
                          volume or -1.0,
                          pan or 0.0,
                          0, 0)
end

return m
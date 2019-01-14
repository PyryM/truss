-- soloud.t
--
-- bindings for the soloud sound library

print('aaaaaaaaaaaaaaaaaaaaaaaa')

local m = {}
local class = require("class")

-- link the dynamic library (should only happen once ideally)
terralib.linklibrary("soloud_x64")
local C = terralib.includec("soloud_c.h")
m.C = C

function m.init()
  m._instance = C.Soloud_create()
  local result = C.Soloud_init(m._instance)
  if result ~= 0 then
    truss.error("Soloud_init error: " .. result)
    m._instance = nil -- leaks a tiny bit of memory, but if soloud init
                      -- failed it might be unsafe to Soloud_destroy()
  else
    log.info("Soloud_init successful.")
  end
  m._raw_wavs = {}
  m._named_wavs = {}
end

m._loaded_wavs = {}
function m._load_wav(filename, stream)
  if m._loaded_wavs[filename] then
    return m._loaded_wavs[filename]
  end

  local data = truss.C.load_file(filename)
  if data == nil then
    truss.error("Unable to load wavefile " .. filename 
                .. ": low-level error (file doesn't exist?)")
  end

  local create_wav, load_wav, destroy_wav = C.Wav_create, C.Wav_loadMemEx, C.Wav_destroy
  if stream then
    create_wav, load_wav, destroy_wav = C.WavStream_create, C.WavStream_loadMemEx, C.WavStream_destroy
  end
  local sound = create_wav()
  -- the 1,0 args are copy = true, takeOwnership = false
  -- (so that it copies the data and doesn't take ownership of our pointer)
  local result = load_wav(sound, data.data, data.data_length, 1, 0)
  truss.C.release_message(data)

  if result == 0 then
    m._loaded_wavs[filename] = {sound, destroy_wav}
    return sound
  else
    local estring = ffi.string(C.Soloud_getErrorString(m._instance, result))
    log.error("Error interpreting sound file " .. filename .. ": " .. estring)
    return nil
  end
end

function m._destroy_wav(filename)
  if not m._loaded_wavs[filename] then return end
  local wav, destroy = unpack(m._loaded_wavs[filename])
  destroy(wav)
  m._loaded_wavs[filename] = nil
end

local Bus = class("Bus")
m.Bus = Bus

function Bus:init()
  self._bus = C.Bus_create()
end

function Bus:start(volume, pan)
  local source = terralib.cast(&C.AudioSource, self._bus)
  self._handle = C.Soloud_playEx(m._instance, 
                                 source,
                                 volume or -1.0,
                                 pan or 0.0,
                                 0, 0)
  return self
end

function Bus:stop()
  if self._handle then
    C.Soloud_stop(m._instance, self._handle)
    self._handle = nil
  end
end

function Bus:play(sound, volume, pan)
  local source = sound:get_audio_source()
  sound._handle = C.Bus_playEx(self._bus, source, volume or 1.0, pan or 0.0, 0)
end

function Bus:enable_vis(enabled)
  enabled = (enabled and 1) or 0
  C.Bus_setVisualizationEnable(self._bus, enabled)
end

function Bus:get_fft()
  return C.Bus_calcFFT(self._bus)
end

local Wav = class("Wav")
m.Wav = Wav

function Wav:init(filename, stream)
  m._load_wav(filename, stream)
  self._fn = filename
  self._stream = stream
  self.filename = filename
end

function Wav:clone()
  return Wav(self._fn, self._stream)
end

function Wav:_get_wav()
  local w = m._loaded_wavs[self._fn]
  if w then return w[1] else return nil end
end

function Wav:get_audio_source()
  local rawsound = self:_get_wav()
  if not rawsound then return end
  return terralib.cast(&C.AudioSource, rawsound)
end

function Wav:play(volume, pan)
  local source = self:get_audio_source()
  if not source then return end
  --wav_to_sound_source(rawsound)
  self._handle = C.Soloud_playEx(m._instance, 
                  source,
                  volume or -1.0,
                  pan or 0.0,
                  0, 0)
end

function Wav:stop()
  if self._handle then
    C.Soloud_stop(m._instance, self._handle)
    self._handle = nil
  end
end

function Wav:stop_all()
  local source = self:get_audio_source()
  C.Soloud_stopAudioSource(m._instance, source)
end

function Wav:get_duration()
  local rawsound = self:_get_wav()
  if rawsound == nil then return 0.0 end
  if self._stream then
    return C.WavStream_getLength(rawsound)
  else
    return C.Wav_getLength(rawsound)
  end
end

function Wav:set_looping(looping)
  local loopint = 0
  if looping then loopint = 1 end
  local rawsound = self:_get_wav()
  if not rawsound then return end
  if self._stream then
    C.WavStream_setLooping(rawsound, loopint)
  else
    C.Wav_setLooping(rawsound, loopint)
  end
end

function Wav:set_inaudible_behavior(must_tick, kill)
  local rawsound = self:_get_wav()
  if not rawsound then return end
  must_tick = (must_tick and 1) or 0
  kill = (kill and 1) or 0
  print(must_tick, kill)
  if self._stream then
    C.WavStream_setInaudibleBehavior(rawsound, must_tick, kill)
  else
    C.Wav_setInaudibleBehavior(rawsound, must_tick, kill)
  end
end

local Speech = class("Speech")
m.Speech = Speech

function Speech:init()
  self._pointer = C.Speech_create()
end

function Speech:say(text, volume, pan)
  C.Speech_setText(self._pointer, text)
  local sound = terralib.cast(&C.AudioSource, self._pointer)
  self._handle = C.Soloud_playEx(m._instance, 
                  sound,
                  volume or -1.0,
                  pan or 0.0,
                  0, 0)
end

function Speech:stop()
  if self._handle then
    C.Soloud_stop(m._instance, self._handle)
    self._handle = nil
  end
end

return m
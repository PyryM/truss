-- soloud.t
--
-- bindings for the soloud sound library

local m = {}
local class = require("class")
local modutils = require("core/module.t")

-- link the dynamic library (should only happen once ideally)
terralib.linklibrary("soloud_x64")
local C_raw = terralib.includec("soloud_c.h")
local C = modutils.reexport_without_prefix(C_raw, "Soloud_")

m.C = C

local function toint(b, default_val)
  if b == nil then return default_val end
  return (b and 1) or 0
end

function m.init()
  m._instance = C.create()
  local result = C.init(m._instance)
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

function m.set_volume(volume)
  C.setGlobalVolume(m._instance, volume)
end

local Voice = class("Voice")
function Voice:init(handle)
  self._handle = handle
end

function Voice:seek(time)
  return C.seek(m._instance, self._handle, time)
end

function Voice:stop()
  C.stop(m._instance, self._handle)
end

function Voice:set_looping(looping, loop_point)
  C.setLooping(m._instance, self._handle, toint(looping))
  if loop_point then
    C.setLoopPoint(m._instance, self._handle, loop_point)
  end
end

function Voice:schedule_pause(dt)
  C.schedulePause(m._instance, self._handle, dt)
end

function Voice:schedule_stop(dt)
  C.scheduleStop(m._instance, self._handle, dt)
end

function Voice:fade_volume(target_volume, dt)
  C.fadeVolume(m._instance, self._handle, target_volume, dt)
end

function Voice:set_volume(volume)
  C.setVolume(m._instance, self._handle, volume)
end

function Voice:set_inaudible_behavior(must_tick, kill)
  C.setInaudibleBehavior(m._instance, self._handle, toint(must_tick), toint(kill))
end

function Voice:pause(paused)
  if paused == nil then paused = true end
  C.setPause(m._instance, self._handle, toint(paused))
end

local AudioSource = class("AudioSource")
function AudioSource:init(ptr)
  self._audiosrc_ptr = terralib.cast(&C_raw.AudioSource, ptr) 
end

function AudioSource:get_audio_source()
  return self._audiosrc_ptr
end

function AudioSource:play(volume, pan, paused)
  local handle = C.playEx(m._instance, self._audiosrc_ptr, 
    volume or -1.0, pan or 0.0, toint(paused, 0), 0)
  return Voice(handle)
end

function AudioSource:play_clocked(sound_time, volume, pan, paused)
  local handle = C.playClockedEx(m._instance, self._audiosrc_ptr, 
    sound_time, volume or -1.0, pan or 0.0, toint(paused, 0), 0)
  return Voice(handle)
end

function AudioSource:stop()
  C.stopAudioSource(m._instance, self._audiosrc_ptr)
end

function AudioSource:count()
  return C.countAudioSource(m._instance, self._audiosrc_ptr)
end

local function def_filter(fname, base_type_name, params, param_form)
  local FC = modutils.reexport_without_prefix(C_raw, base_type_name .. "_")

  local ptr_type = C_raw[base_type_name]
  local setter = FC[(param_form or "setParams")]
  local param_indices = {}
  local default_params = {}
  for idx, pinfo in ipairs(params) do
    param_indices[pinfo[1]] = idx
    default_params[idx] = pinfo[2]
  end

  local Filter = class(fname)
  function Filter:init(options)
    self._pointer = FC.create()
    self._params = truss.extend_table({}, default_params)
    if options then self:set_params(options) end
  end
  function Filter:destroy()
    if not self._pointer then return end
    FC.destroy(self._pointer)
    self._pointer = nil
  end
  function Filter:get_filter_pointer()
    if not self._pointer then truss.error("Null filter!") end
    return terralib.cast(&C_raw.Filter, self._pointer)
  end
  function Filter:set_params(params)
    for pname, pval in pairs(params) do
      if not param_indices[pname] then
        truss.error("Unknown param [" .. pname .. "] for " .. fname)
      end
      self._params[param_indices[pname]] = pval
    end
    setter(self._pointer, unpack(self._params))
  end
  return Filter
end

m.EchoFilter = def_filter("EchoFilter", "EchoFilter", {
  {"delay", 0.5}, {"decay", 0.7}, {"filter", 0.0}
}, "setParamsEx")

m.BiquadFilter = def_filter("BiquadFilter", "BiquadResonantFilter", {
  {"kind", 1}, {"sample_rate", 16000}, {"frequency", 8000}, {"resonance", 0.5}
})

local function def_source(sname, prefix)
  local Source = AudioSource:extend(sname)
  local SC = modutils.reexport_without_prefix(C_raw, prefix .. "_")

  function Source:create()
    self:destroy()
    self._ptr = SC.create()
  end

  function Source:destroy()
    if not self._ptr then return end
    SC.destroy(self._ptr)
    self._ptr = nil
  end

  if SC.setInaudibleBehavior then
    function Source:set_inaudible_behavior(must_tick, kill)
      if not self._ptr then return end
      SC.setInaudibleBehavior(self._ptr, toint(must_tick), toint(kill))
    end
  end

  if SC.setVolume then
    function Source:set_volume(volume)
      if not self._ptr then return end
      SC.setVolume(self._ptr, volume)
    end
  end

  if SC.setLooping then
    function Source:set_looping(looping, loop_point)
      SC.setLooping(self._ptr, toint(looping))
      if loop_point then
        SC.setLoopPoint(self._ptr, loop_point)
      end
    end
  end

  if SC.setFilter then
    function Source:set_filter(filter, slot)
      if not self._ptr then return end
      if filter == nil then 
        truss.error("Nil filter! To clear pass `false`!") 
      end
      local ptr = nil
      if filter then ptr = filter:get_filter_pointer() end
      SC.setFilter(self._ptr, slot or 0, ptr)
    end
  end

  if SC.getLength then
    function Source:get_length()
      if not self._ptr then return 0.0 end
      return SC.getLength(self._ptr)
    end
  end

  return Source, SC
end

local Bus, Bus_C = def_source("Bus", "Bus")
m.Bus = Bus

function Bus:init()
  self:create()
  Bus.super.init(self, self._ptr)
end

function Bus:add(sound, volume, pan, paused)
  local source = sound:get_audio_source()
  local h = Bus_C.playEx(self._ptr, source, volume or 1.0, pan or 0.0, toint(paused, 0))
  return Voice(h)
end

function Bus:add_clocked(sound, time, volume, pan)
  local source = sound:get_audio_source()
  local h = Bus_C.playClockedEx(self._ptr, time, source, volume or 1.0, pan or 0.0)
  return Voice(h)
end

function Bus:enable_vis(enabled)
  Bus_C.setVisualizationEnable(self._ptr, toint(enabled, 1))
end

function Bus:get_fft()
  return Bus_C.calcFFT(self._ptr)
end

local function _load_wav(filename, ptr, loader)
  local data = truss.C.load_file(filename)
  if data == nil then
    truss.error("Unable to load wavefile " .. filename 
                .. ": low-level error (file doesn't exist?)")
  end

  -- the 1,0 args are copy = true, takeOwnership = false
  -- (so that it copies the data and doesn't take ownership of our pointer)
  local result = loader(ptr, data.data, data.data_length, 1, 0)
  truss.C.release_message(data)

  if result == 0 then
    return true
  else
    local estring = ffi.string(C.Soloud_getErrorString(m._instance, result))
    log.error("Error interpreting sound file " .. filename .. ": " .. estring)
    return false, estring
  end
end

local Queue, QC = def_source("Queue", "Queue")
m.Queue = Queue

function Queue:init(sample_rate, channels)
  self:create()
  QC.setParamsEx(self._ptr, sample_rate or 44100.0, channels or 2)
  Queue.super.init(self, self._ptr)
end

function Queue:push(source)
  if self:count() == 0 then
    QC.setParamsFromAudioSource(source:get_audio_source())
  end
  QC.play(self._ptr, source:get_audio_source())
end

function Queue:is_playing()
  return QC.isCurrentlyPlaying(seslf._ptr) > 0
end

function Queue:count()
  return QC.getQueueCount(self._ptr)
end

local Wav, Wav_C = def_source("Wav", "Wav")
m.Wav = Wav

function Wav:init(filename)
  self:create()
  if filename then self:load_file(filename) end
  Wav.super.init(self, self._ptr)
end

function Wav:load_file(filename)
  self.filename = filename
  _load_wav(filename, self._ptr, Wav_C.loadMemEx)
end

function Wav:load_raw_cdata(cdata, cdata_length, bit_depth, sample_rate, channels)
  bit_depth = bit_depth or 8
  sample_rate = sample_rate or 44100.0
  channels = channels or 1
  if bit_depth == 8 then
    Wav_C.loadRawWave8Ex(self._ptr, cdata, cdata_length, sample_rate, channels)
  elseif bit_depth == 16 then
    Wav_C.loadRawWave16Ex(self._ptr, cdata, cdata_length, sample_rate, channels)
  elseif bit_depth == 32 then
    -- the trailing 1, 0 arguments = copy, don't take ownership
    Wav_C.loadRawWave(self._ptr, cdata, cdata_length, sample_rate, channels, 1, 0)
  else
    truss.error("Unsupported bit depth " .. bit_depth)
  end
  self._cdata = cdata
end

local WavStream, WavStream_C = def_source("WavStream", "WavStream")
m.WavStream = WavStream

function WavStream:init(filename)
  self:create()
  if filename then self:load_file(filename) end
  WavStream.super.init(self, self._ptr)
end

function WavStream:load_file(filename)
  self.filename = filename
  _load_wav(filename, self._ptr, WavStream_C.loadMemEx)
end

local Speech, Speech_C = def_source("Speech", "Speech")
m.Speech = Speech

function Speech:init()
  self:create()
  Speech.super.init(self, self._ptr)
end

local WAVEFORMS = {
  saw = 0,
  triangle = 1,
  sine = 2,
  square = 3,
  pulse = 4,
  noise = 5,
  warble = 6
}

function Speech:set_params(params)
  params = params or {}
  local base_freq = params.frequency or 1330
  local base_speed = params.speed or 10.0
  local declination = params.declination or 0.5
  local waveform = WAVEFORMS[params.waveform or "triangle"] or WAVEFORMS.triangle
  Speech_C.setParamsEx(self._ptr, base_freq, base_speed, declination, waveform)
end

function Speech:set_text(text)
  Speech_C.setText(self._ptr, text)
end

function Speech:say(text, volume, pan, paused)
  self:set_text(text)
  return self:play(volume, pan, paused)
end

-- it's not obvious but this is an alternate speech synthesizer
local Vizsn, Vizsn_C = def_source("Vizsn", "Vizsn")
m.Vizsn = Vizsn

function Vizsn:init()
  self:create()
  Vizsn.super.init(self, self._ptr)
end

function Vizsn:set_text(text)
  Vizsn_C.setText(self._ptr, text)
end

function Vizsn:say(text, volume, pan, paused)
  self:set_text(text)
  return self:play(volume, pan, paused)
end

return m
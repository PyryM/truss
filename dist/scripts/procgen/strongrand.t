-- procgen/strongrand.t
--
-- statistically stronger random number generator using chacha20

local class = require("class")
local chacha = require("./chacha.t")
local m = {}

local StrongRandom = class("StrongRandom")
m.StrongRandom = StrongRandom

function StrongRandom:init(seed)
  seed = seed or os.time()
  self._key, self._nonce = chacha.pad_string_to_key(seed)
  log.info("StrongRandom key: " .. chacha.to_hex(self._key, 32))
  log.info("StrongRandom nonce: " .. chacha.to_hex(self._nonce, 8))
  self._ctx = terralib.new(chacha.chacha20_ctx)
  self._ctx.available = 0
  self._output_u8 = terralib.cast(&uint8, self._ctx.keystream)
  chacha.setup(self._ctx, self._key, 32, self._nonce)
end

function StrongRandom:rand_uint8()
  if self._ctx.available <= 0 then
    chacha.block(self._ctx, self._ctx.keystream)
    self._ctx.available = 64
  end
  local ret = self._output_u8[64 - self._ctx.available]
  self._ctx.available = self._ctx.available - 1
  return ret
end

function StrongRandom:rand_uint_n(nbytes)
  local acc = self:rand_uint8()
  for i = 2, nbytes do
    acc = acc * 256
    acc = acc + self:rand_uint8()
  end
  return acc
end

function StrongRandom:rand_uint32()
  return self:rand_uint_n(4)
end

function StrongRandom:rand_unsigned(nvals)
  -- simply taking the modulus would (if nvals is non power of two)
  -- result in a non-uniform distribution, so instead we rejection
  -- sample under the tightest power of two range
  if nvals < 2 then return 0 end -- what should rand[0,0) return? 0 I guess
  local nbits = math.ceil(math.log(nvals) / math.log(2))
  local nbytes = math.ceil(nbits / 8)
  if nbits > 52 then
    truss.error("Only up to 52 bit random numbers supported ATM!")
  end
  local modulus = 2^nbits
  for _ = 1, 1000 do
    -- worst case scenario has ~1/2 rejection rate:
    -- p(1000 rejections) = 1/2^1000
    -- (we do this to guard against potential infinite loop if something
    --  goes wrong somewhere)
    local v = self:rand_uint_n(nbytes) % modulus
    if v < nvals then return v end
  end
  log.warning("Saw 1000 rejections somehow?!")
  return 0
end

function StrongRandom:rand_int(lower_bound, upper_bound)
  return lower_bound + self:rand_unsigned(upper_bound - lower_bound)
end

return m
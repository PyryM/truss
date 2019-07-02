-- math/chachat.t
--
-- implementation of the chacha20 symmetric cipher

local m = {}

--[[
Copyright (C) 2014 insane coder (http://insanecoding.blogspot.com/, http://chacha20.insanecoding.org/)

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/]]--

local terra ROTL32(v: uint32, n: uint32): uint32
  return (v << n) or (v >> (32 - n))
end

local terra LE(p: &uint8): uint32
  -- need to cast to int32 so the bit shifting doesn't overflow
  var p0: uint32 = p[0]
  var p1: uint32 = p[1]
  var p2: uint32 = p[2]
  var p3: uint32 = p[3]
  return (p0 or (p1 << 8) or (p2 << 16) or (p3 << 24))
end

local terra FROMLE(b: &uint8, i: uint32)
  b[0] = i and 0xFF
  b[1] = (i >> 8) and 0xFF
  b[2] = (i >> 16) and 0xFF
  b[3] = (i >> 24) and 0xFF
end

local terra MIN(a: uint64, b: uint64): uint64
  if a < b then return a else return b end
end

local struct chacha20_ctx
{
  schedule: uint32[16];
  keystream: uint32[16];
  available: uint64;
}
m.chacha20_ctx = chacha20_ctx

terra m.setup(ctx: &chacha20_ctx, key: &uint8, length: uint64,
  nonce: &uint8)
  var constants: &uint8
  if length == 32 then
    constants = [&uint8]("expand 32-byte k")
  else
    constants = [&uint8]("expand 16-byte k")
  end

  ctx.schedule[0] = LE(constants + 0)
  ctx.schedule[1] = LE(constants + 4)
  ctx.schedule[2] = LE(constants + 8)
  ctx.schedule[3] = LE(constants + 12)
  ctx.schedule[4] = LE(key + 0)
  ctx.schedule[5] = LE(key + 4)
  ctx.schedule[6] = LE(key + 8)
  ctx.schedule[7] = LE(key + 12)
  ctx.schedule[8] = LE(key + 16 % length)
  ctx.schedule[9] = LE(key + 20 % length)
  ctx.schedule[10] = LE(key + 24 % length)
  ctx.schedule[11] = LE(key + 28 % length)
  -- Surprise! This is really a block cipher in CTR mode
  ctx.schedule[12] = 0 -- Counter
  ctx.schedule[13] = 0 -- Counter
  ctx.schedule[14] = LE(nonce+0)
  ctx.schedule[15] = LE(nonce+4)

  ctx.available = 0
end

terra m.counter_set(ctx: &chacha20_ctx, counter: uint64)
  ctx.schedule[12] = counter and 0xFFFFFFFF
  ctx.schedule[13] = counter >> 32
  ctx.available = 0
end

local terra QUARTERROUND(x: &uint32, a: uint8, b: uint8, c: uint8, d: uint8)
  x[a] = x[a] + x[b]
  x[d] = ROTL32(x[d] ^ x[a], 16)
  x[c] = x[c] + x[d]
  x[b] = ROTL32(x[b] ^ x[c], 12)
  x[a] = x[a] + x[b]
  x[d] = ROTL32(x[d] ^ x[a], 8)
  x[c] = x[c] + x[d]
  x[b] = ROTL32(x[b] ^ x[c], 7)
end

terra m.block(ctx: &chacha20_ctx, output: &uint32)
  var nonce: &uint32 = (ctx.schedule) + 12 --12 is where the 128 bit counter is

  for i = 0,16 do
    output[i] = ctx.schedule[i]
  end

  for i = 0,10 do -- 10*8 quarter rounds = 20 rounds
    QUARTERROUND(output, 0, 4, 8, 12)
    QUARTERROUND(output, 1, 5, 9, 13)
    QUARTERROUND(output, 2, 6, 10, 14)
    QUARTERROUND(output, 3, 7, 11, 15)
    QUARTERROUND(output, 0, 5, 10, 15)
    QUARTERROUND(output, 1, 6, 11, 12)
    QUARTERROUND(output, 2, 7, 8, 13)
    QUARTERROUND(output, 3, 4, 9, 14)
  end
  for i = 0,16 do
    var result: uint32 = output[i] + ctx.schedule[i]
    --FROMLE((uint8_t *)(output+i), result);
    output[i] = result
  end

  --[[
  Official specs calls for performing a 64 bit increment here, and limit usage to 2^64 blocks.
  However, recommendations for CTR mode in various papers recommend including the nonce component for a 128 bit increment.
  This implementation will remain compatible with the official up to 2^64 blocks, and past that point, the official is not intended to be used.
  This implementation with this change also allows this algorithm to become compatible for a Fortuna-like construct.
  ]]--
  nonce[0] = nonce[0] + 1
  if nonce[0] == 0 then
    nonce[1] = nonce[1] + 1
    if nonce[1] == 0 then
      nonce[2] = nonce[2] + 1
      if nonce[2] == 0 then
        nonce[3] = nonce[3] + 1
      end
    end
  end
end

local function to_hex(s, slen)
  local ret = ""
  for i = 0,(slen-1) do
    ret = ret .. string.format("%x", s[i])
  end
  return ret
end
m.to_hex = to_hex

local terra to_uint8_str(s: &int8): &uint8
  return [&uint8](s)
end
m.to_uint8_str = to_uint8_str

function m.pad_string_to_key(s, nonce)
  s = tostring(s)
  local key = terralib.new(uint8[32])
  local nonce = terralib.new(uint8[8])
  for i = 0, 31 do
    key[i] = s:byte(i+1) or 0
  end
  for i = 0, 7 do
    nonce[i] = 0
  end
  return key, nonce
end

function m.test_basic()
  -- test vectors in :
  -- https://tools.ietf.org/html/draft-agl-tls-chacha20poly1305-04#section-7
  local ctx = terralib.new(chacha20_ctx)
  local key = terralib.new(uint8[32])
  local nonce = terralib.new(uint8[8])
  local output = terralib.new(uint32[30])

  for i = 0,31 do
    key[i] = 0
  end
  key[31] = 0
  for i = 0,7 do
    nonce[i] = 0
  end
  nonce[0] = 1
  print("key: " .. to_hex(key, 32))
  print("nonce: " .. to_hex(nonce, 8))

  m.setup(ctx, key, 32, nonce)
  m.block(ctx, output)

  local foutput = terralib.cast(&uint8, output)
  print("output: " .. to_hex(foutput, 16*4))

  local plaintext = "hello there this is a secrete message! I am going to try my" ..
  " best to make this longer than 64 characters so we can see what happens in that" ..
  " situation because I am unsure of the whole multiple block thing."
  local nchars = #plaintext
  print("nchars: " .. nchars)
  local outtext = terralib.new(int8[nchars])
  m.setup(ctx, key, 32, nonce)
  m.encrypt_raw(ctx, to_uint8_str(plaintext), to_uint8_str(outtext), nchars)
  local cipher = ffi.string(outtext, nchars)
  print("length of ciper: " .. #cipher)
  print("hex: " .. to_hex(to_uint8_str(outtext), nchars))

  local outtext2 = terralib.new(int8[nchars])
  m.setup(ctx, key, 32, nonce)
  m.encrypt_raw(ctx, to_uint8_str(outtext), to_uint8_str(outtext2), nchars)
  print("output2: " .. ffi.string(outtext2, nchars))
end

local terra stream_xor(keystream: &uint8, inptr: &uint8, outptr: &uint8, length: uint64)
  for i = 0,length do
    outptr[i] = inptr[i] ^ keystream[i]
  end
end

terra m.encrypt_raw(ctx: &chacha20_ctx, inptr: &uint8, outptr: &uint8, length: uint64)
  if length == 0 then return end
  var keystream: &uint8 = [&uint8](&(ctx.keystream))
  var pos: uint64 = 0

  -- First, use any buffered keystream from previous calls
  if ctx.available > 0 then
    var amount = MIN(length, ctx.available)
    stream_xor(keystream + (64 - ctx.available), inptr, outptr, amount)
    ctx.available = ctx.available - amount
    length = length - amount
    pos = pos + amount
  end

  -- Then, handle new blocks
  while length > 0 do
    var amount = MIN(length, 64)
    m.block(ctx, ctx.keystream)
    stream_xor(keystream, inptr + pos, outptr + pos, amount)
    length = length - amount
    ctx.available = 64 - amount
    pos = pos + amount
  end
end

return m

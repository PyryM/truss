-- would forcing these to inline make any difference?
-- (presumably LLVM is smart enough to already inline)
local terra rotl64(x: uint64, r: int8): uint64
  return (x << r) or (x >> (64 - r))
end

local terra fmix64(k: uint64): uint64
  k = k ^ (k >> 33)
  k = k * 0xff51afd7ed558ccdULL
  k = k ^ (k >> 33)
  k = k * 0xc4ceb9fe1a85ec53ULL
  k = k ^ (k >> 33)
  return k
end

local struct hash128_t {
  union {
    u64: uint64[2];
    u32: uint32[4];
    bytes: uint8[16];
  }
}

local terra MurmurHash3_128(data: &uint8, len: uint64, seed: uint64): hash128_t
  var nblocks = len / 16

  var h1: uint64 = seed
  var h2: uint64 = seed

  var c1: uint64 = 0x87c37b91114253d5ULL
  var c2: uint64 = 0x4cf5ad432745937fULL

  -- ALIASING?!
  var blocks: &uint64 = [&uint64](data)

  for i = 0, nblocks do
    var k1: uint64 = blocks[i*2+0]
    var k2: uint64 = blocks[i*2+1]

    k1 = k1 * c1 
    k1 = rotl64(k1, 31) 
    k1 = k1 * c2;
    h1 = h1 ^ k1

    h1 = rotl64(h1, 27)
    h1 = h1 + h2
    h1 = (h1 * 5) + 0x52dce729

    k2 = k2 * c2
    k2 = rotl64(k2, 33)
    k2 = k2 * c1
    h2 = h2 ^ k2

    h2 = rotl64(h2, 31)
    h2 = h2 + h1
    h2 = (h2 * 5) + 0x38495ab5
  end

  -- this complicated block is just to deal with the input not
  -- being a multiple of 16 bytes: it's logically equivalent to
  -- just padding with 0s to a multiple of 16 bytes
  var tail_pos: uint32 = nblocks * 16
  var n_tail: uint32 = len % 16

  var k1: uint64 = 0
  var k2: uint64 = 0

  for tt = 0, n_tail do
    var ttt = n_tail - tt
    if ttt > 8 then
      k2 = k2 ^ ([uint64](data[tail_pos + ttt - 1]) << (48 - 8*tt))
    else
      k1 = k1 ^ ([uint64](data[tail_pos + ttt - 1]) << (56 - 8*(tt-8)))
    end
  end
  if n_tail > 8 then
    k2 = k2 * c2
    k2 = rotl64(k2, 33)
    k2 = k2 * c1
    h2 = h2 ^ k2
  end
  if n_tail > 0 then
    k1 = k1 * c1
    k1 = rotl64(k1, 31)
    k1 = k1 * c2
    h1 = h1 ^ k1
  end

  h1 = h1 ^ len
  h2 = h2 ^ len

  h1 = h1 + h2
  h2 = h2 + h1

  h1 = fmix64(h1)
  h2 = fmix64(h2)

  h1 = h1 + h2
  h2 = h2 + h1

  var out: hash128_t
  out.u64[0] = h1
  out.u64[1] = h2
  return out
end

local function hash_to_string(h)
  local s = ""
  for i = 0, 3 do
    s = s .. ("%08x"):format(h.u32[i])
  end
  return s
end

local terra put_hex_digit(val: uint8, dest: &int8, pos: uint32)
  -- 48: 0, 97: a
  if val < 10 then
    dest[pos] = 48+val
  else
    dest[pos] = 97+(val-10)
  end
end

-- this is unfortunately named because the
-- lua version is used all over the place and
-- I don't want to rename it
-- Note: dest must be 32 bytes long at least
local terra print_hash(hash: &hash128_t, dest: &int8, nchars: uint8): uint32
  var dpos = 0
  for spos = 0, nchars/2 do
    var b = hash.bytes[spos]
    var lower = b and 0xf
    var upper = (b >> 4) and 0xf
    put_hex_digit(upper, dest, dpos+0)
    put_hex_digit(lower, dest, dpos+1)
    dpos = dpos + 2
  end
  return dpos
end

local function hash_to_string(h)
  local s = ""
  for i = 0, 3 do
    s = s .. ("%08x"):format(h.u32[i])
  end
  return s
end

return {
  hash128_t = hash128_t, 
  murmur_128 = MurmurHash3_128, 
  hash_to_string = hash_to_string,
  print_hash = print_hash
}

-- native/timing.t
--
-- high-performance timing junk

local build = require("build/build.t")
local m = {}

local target = build.target_name()

if target == "Windows" then
  local C = build.includecstring[[
  #include "stdint.h"
  typedef int BOOL;
  BOOL QueryPerformanceFrequency(int64_t* lpFrequency);
  BOOL QueryPerformanceCounter(int64_t* lpPerformanceCount);
  ]]

  terra m.get_freq(): int64
    var ret: int64 = 0
    C.QueryPerformanceFrequency(&ret)
    return ret
  end

  terra m.get_counter(): int64
    var ret: int64 = 0
    C.QueryPerformanceCounter(&ret)
    return ret
  end
--elseif truss.os == "OSX" then
else -- hope this works on linux/osx/wasm
  local C = build.includecstring[[
  #include "stdint.h"
  typedef enum {
    CLOCK_REALTIME = 0,
    CLOCK_MONOTONIC = 6
  } clockid_t;

  typedef struct {
    int64_t tv_sec;
    long tv_nsec;
  } timespec_t;

  int clock_gettime(clockid_t id, timespec_t *tp);
  ]]

  terra m.get_freq(): int64
    return 1000000000
  end

  terra m.get_counter(): int64
    var now: C.timespec_t
    C.clock_gettime(C.CLOCK_MONOTONIC, &now)
    var ret: int64 = now.tv_sec*1000000000LL + now.tv_nsec
    return ret
  end
end

m.tic = m.get_counter

terra m.toc(start_counter: int64): double
  var cur_counter = m.get_counter()
  var freq = m.get_freq()
  var delta_ticks : double = cur_counter - start_counter
  return delta_ticks / [double](freq)
end

function m.install(target)
  target.tic = m.tic
  target.toc = m.toc
end

return m
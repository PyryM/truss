-- native/cstd.t
--
-- just a wrapper around c standard headers to avoid repeated
-- parsing/inclusion of the same headers

local Cstd = terralib.includec("stdlib.h")
return Cstd
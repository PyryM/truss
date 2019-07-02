math = require("math")

rand_vector = -> math.Vector(unpack [math.random! for i = 1,4])

{ :rand_vector }
-- haserrors.t
--
-- a file with syntax errors to test loading

if foo == 3 then
	print("yay")
else foo == 2 then -- syntax error: should be elseif
	print("boo")
end
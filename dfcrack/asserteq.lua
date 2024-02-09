local function asserteq(a,b)
	if a == b then return true end
	error('expected '..tostring(a)..' == '..tostring(b))
end
return asserteq

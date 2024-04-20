---@alias Bezier {p1: Vector, p2: Vector, p3: Vector, p4: Vector}

---@param from number
---@param to number
---@param t number
---@return number
function math.lerp(from, to, t)
	return to * t + from * (1 - t)
end

local lerp = math.lerp

function math.nearest_angle(from, to)
	local diff = to - from
	diff = math.fmod(diff, math.pi * 2)

	if diff > math.pi then
		diff = diff - math.pi * 2
	elseif diff < -math.pi then
		diff = diff + math.pi * 2
	end

	return diff
end

function _G.sample_bezier(p1, p2, p3, p4, t)
	local p12 = lerp(p1, p2, t)
	local p23 = lerp(p2, p3, t)
	local p34 = lerp(p3, p4, t)

	local p13 = lerp(p12, p23, t)
	local p24 = lerp(p23, p34, t)

	return lerp(p13, p24, t)
end

function _G.sample_bezier_tangent(p1, p2, p3, p4, t)
	return
		3 * (p4 - 3 * p3 + 3 * p2 - p1) * t * t
		+ 6 * (p3 - 2 * p2 + p1) * t
		+ 3 * (p2 - p1)
end

local vector = {}

---@class Vector
---@field x number
---@field y number

---@param left Vector
---@param right Vector
---@return number
function vector.dot(left, right)
	return left.x * right.x + left.y * right.y
end

---@param left Vector
---@param right Vector
---@return number
function vector.cross(left, right)
	return left.x * right.y - left.y * right.x
end

---@param out Vector
---@param vector Vector
---@param angle number
function vector.rotate(out, vector, angle)
	local cos = math.cos(angle)
	local sin = math.sin(angle)
	out.x = vector.x * cos - vector.y * sin
	out.y = vector.y * cos + vector.x * sin
end

function vector.segment_intersect(l1, l2, r1, r2)
	local d1 = vector.cross(
	{x = r1.x - l1.x, y = r1.y - l1.y},
	{x = r2.x - l1.x, y = r2.y - l1.y}
	)
	local d2 = vector.cross(
	{x = r1.x - l2.x, y = r1.y - l2.y},
	{x = r2.x - l2.x, y = r2.y - l2.y}
	)
	local d3 = vector.cross(
	{x = l1.x - r1.x, y = l1.y - r1.y},
	{x = l2.x - r1.x, y = l2.y - r1.y}
	)
	local d4 = vector.cross(
	{x = l1.x - r2.x, y = l1.y - r2.y},
	{x = l2.x - r2.x, y = l2.y - r2.y}
	)

	return d1 * d2 < 0 and d3 * d4 < 0
end

_G.vector = vector
---@class Scroller
---@field image love.Image
---@field speed number
---@field pos Vector
local Scroller = {}
Scroller.__index = Scroller

---@param image_path string
---@param speed number
---@return Scroller
function Scroller:new(image_path, speed)
	local o = {
		image = love.graphics.newImage(image_path),
		speed = speed,
		pos = {
			x = 0,
			y = 0
		}
	}

	setmetatable(o, self)
	return o
end

function Scroller:update(dt)
	local pos = self.pos
	pos.x = pos.x + dt * self.speed

	local w, _ = self.image:getDimensions()
	if pos.x > w then
		pos.x = pos.x - w
	end
end

function Scroller:draw()
	local pos = self.pos
	love.graphics.draw(self.image, -pos.x, -pos.y)

	local w, _ = self.image:getDimensions()
	love.graphics.draw(self.image, -pos.x + w, -pos.y)
end

return Scroller

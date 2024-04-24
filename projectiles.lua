local sprites = {}

local function load()
	sprites.fireball = load_sprites("sprites/fireball")
	sprites.fireballGlow = love.graphics.newImage("sprites/fireballGlow.png")
end

---@type Projectile[]
local projectiles = {}

---@class Projectile
---@field pos Vector
---@field vel Vector
---@field shape Vector[]
---@field scale number
---@field damage number
---@field heat number
---@field erase boolean
---@field frame number
---@field subframe number
local Projectile = {}
Projectile.__index = Projectile

---@return Projectile
function Projectile:new(x, y, vx, vy, scale, damage)
	local o = {
		erase = false,

		pos = {
			x = x,
			y = y
		},
		vel = {
			x = vx,
			y = vy
		},

		scale = scale,
		damage = damage,
		heat = 1,
		frame = 1,
		subframe = 1,
	}

	setmetatable(o, self)
	return o
end

function Projectile:update(dt)
	local vel = self.vel
	local pos = self.pos
	pos.x = pos.x + vel.x * dt
	pos.y = pos.y + vel.y * dt

	---@type Vector
	local tail = {
		x = 0, y = 0
	}
	for i, enemy in ipairs(enemies.pool) do
		tail.x = pos.x + (enemy.vel.x - vel.x) * dt
		tail.y = pos.y + (enemy.vel.y - vel.y) * dt
		for i = 1, #enemy.shape, 2 do
			if vector.segment_intersect(enemy.shape[i], enemy.shape[i + 1], pos, tail) then
				enemy:hit(self)
				self.erase = true
				return
			end
		end
	end

	if
		pos.x < 0 or pos.x > STAGE_WIDTH or
		pos.y < 0 or pos.y > WORLD_HEIGHT
	then
		self.erase = true
		return
	end

	-- Animation
	self.subframe = self.subframe + dt * FLASH_FPS

	if self.subframe > 1 then
		local frames = math.floor(self.subframe)

		self.frame = self.frame + frames

		if self.frame >= #sprites.fireball then
			self.frame = #sprites.fireball - 1
		end

		self.subframe = self.subframe - frames
	end

	self.scale = math.lerp(1, self.scale, math.pow(0.85, dt * FLASH_FPS))
	self.heat = self.heat * math.exp(-dt * 10)
end

function Projectile:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(sprites.fireball[self.frame], 0, 0, 0, 0.5, 0.5, 154.5, 36.5)
	love.graphics.setColor(1, 1, 1, math.lerp(0.4, 1, self.heat))
	love.graphics.draw(sprites.fireballGlow, 0, 0, 0, 1, 1, 21.15, 21.15)
end

local new = {}
function new.fireball(x, y, vx, vy, scale, damage)
	table.insert(projectiles, Projectile:new(x, y, vx, vy, scale, damage))
end

local function update(dt)
	for i = #projectiles, 1, -1 do
		local projectile = projectiles[i]
		projectile:update(dt)
		if projectile.erase then
			table.remove(projectiles, i)
		end
	end
end

local function draw()
	love.graphics.setColor(1, 1, 1)
	for i, projectile in ipairs(projectiles) do
		love.graphics.push()

		love.graphics.translate(projectile.pos.x, projectile.pos.y)
		love.graphics.scale(projectile.scale, projectile.scale)
		love.graphics.rotate(math.atan2(projectile.vel.y, projectile.vel.x))

		projectile:draw()

		love.graphics.pop()
	end
end

return {
	load = load,
	new = new,
	update = update,
	draw = draw,
	pool = projectiles
}

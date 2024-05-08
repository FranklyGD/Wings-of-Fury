local sprites = {}

local audio = {}

local function load()
	sprites.fireball = load_sprites("sprites/fireball")
	sprites.fireballGlow = love.graphics.newImage("sprites/fireballGlow.png")
	sprites.spear = love.graphics.newImage("sprites/spear.png")

	audio.hit = { i = 1 }
	audio.hit[1] = love.audio.newSource("sounds/enemyHit.wav", "static")
	audio.hit[1]:setVolume(0.5)
	audio.hit[2] = love.audio.newSource("sounds/enemyHit.wav", "static")
	audio.hit[2]:setVolume(0.5)
end

---@type Projectile[]
local projectiles = {}

---@class Projectile
---@field erase boolean
---@field hostile boolean
---@field pos Vector
---@field vel Vector
---@field shape Vector[]
---@field scale number
---@field damage number
local Projectile = {}
Projectile.__index = Projectile

---@return Projectile
function Projectile:new()
	local o = {
		erase = false,
	}

	setmetatable(o, self)
	return o
end

function Projectile:init(x, y, vx, vy, scale, damage)
	self.pos = {
		x = x,
		y = y
	}
	self.vel = {
		x = vx,
		y = vy
	}

	self.scale = scale
	self.damage = damage
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

	if self.hostile then
		for i = 1, #player.shape, 2 do
			tail.x = pos.x + (player.vel.x - vel.x) * dt
			tail.y = pos.y + (player.vel.y - vel.y) * dt
			if vector.segment_intersect(player.shape[i], player.shape[i + 1], pos, tail) then
				player:hit(self.damage)
			end
		end
	else
		for i, enemy in ipairs(enemies.pool) do
			if enemy.health > 0 then
				tail.x = pos.x + (enemy.vel.x - vel.x) * dt
				tail.y = pos.y + (enemy.vel.y - vel.y) * dt
				for i = 1, #enemy.shape, 2 do
					if vector.segment_intersect(enemy.shape[i], enemy.shape[i + 1], pos, tail) then
						enemy:hit(self)

						local i = audio.hit.i
						love.audio.play(audio.hit[i])
						audio.hit.i = i == 1 and 2 or 1

						self.erase = true
						return
					end
				end
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
end

function Projectile:draw() end

---@class Fireball:Projectile
---@field heat number
---@field frame number
---@field subframe number
local Fireball = Projectile:new()
Fireball.__index = Fireball

function Fireball:new()
	---@type Fireball
	local o = Projectile:new()
	o.hostile = false

	o.heat = 1
	o.frame = 1
	o.subframe = 0

	setmetatable(o, self)
	return o
end

function Fireball:init(x, y, vx, vy, scale, damage)
	Projectile.init(self, x, y, vx, vy, scale, damage)
end

function Fireball:update(dt)
	Projectile.update(self, dt)

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

function Fireball:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(sprites.fireball[self.frame], 0, 0, 0, 0.5, 0.5, 154.5, 36.5)
	love.graphics.setColor(1, 1, 1, math.lerp(0.4, 1, self.heat))
	love.graphics.draw(sprites.fireballGlow, 0, 0, 0, 1, 1, 21.15, 21.15)
end

---@class Spear:Projectile
local Spear = Projectile:new()
Spear.__index = Spear

function Spear:new()
	---@type Spear
	local o = Projectile:new()
	o.hostile = true

	setmetatable(o, self)
	return o
end

function Spear:init(x, y, vx, vy, scale, damage)
	Projectile.init(self, x, y, vx, vy, scale, damage)
end

function Spear:draw()
	love.graphics.draw(sprites.spear, -71, -6)
end

local new = {}
function new.fireball(x, y, vx, vy, scale, damage)
	local proj = Fireball:new()
	proj:init(x, y, vx, vy, scale, damage)
	table.insert(projectiles, proj)
end

function new.spear(x, y, vx, vy, scale, damage)
	local proj = Spear:new()
	proj:init(x, y, vx, vy, scale, damage)
	table.insert(projectiles, proj)
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

	if debug_mode then
		for i, projectile in ipairs(projectiles) do
			if projectile.hostile then
				love.graphics.setColor(1, 0.5, 0)
			else
				love.graphics.setColor(0, 0.5, 1)
			end
			love.graphics.circle("fill", projectile.pos.x, projectile.pos.y, 4)
		end
	end
end

return {
	load = load,
	new = new,
	update = update,
	draw = draw,
	pool = projectiles
}

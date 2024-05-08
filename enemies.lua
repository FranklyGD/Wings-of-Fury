local behaviors = require "behaviors"

---@enum EnemyState
local state = {
	idle = 0,
	moving = 1,
	attacking = 2,
	dead = 3
}

local sprites = {}
sprites.gobelin = {}
sprites.orc = {}

local audio = {}
audio.gobelin = {}
audio.orc = {}

local function load()
	sprites.gobelin.idle = load_sprites("sprites/gobelinIdle")
	sprites.gobelin.attack = load_sprites("sprites/gobelinAttack")
	sprites.gobelin.death = load_sprites("sprites/gobelinDeath")
	sprites.gobelin.grounded = { love.graphics.newImage("sprites/gobelinGrounded.png") }

	sprites.orc.idle = load_sprites("sprites/orcIdle")
	sprites.orc.attack = load_sprites("sprites/orcAttack")
	sprites.orc.death = load_sprites("sprites/orcDeath")
	sprites.orc.hit = load_sprites("sprites/orcHit")
	sprites.orc.grounded = { love.graphics.newImage("sprites/orcGrounded.png") }

	audio.grounded = { i = 1 }
	audio.grounded[1] = love.audio.newSource("sounds/hitGround.wav", "static")
	audio.grounded[1]:setVolume(0.5)
	audio.grounded[2] = love.audio.newSource("sounds/hitGround.wav", "static")
	audio.grounded[2]:setVolume(0.5)

	audio.gobelin.attack = { i = 1 }
	for i = 1, 5 do
		audio.gobelin.attack[i] = love.audio.newSource("sounds/gobelinAttack.wav", "static")
		audio.gobelin.attack[i]:setVolume(0.5)
	end

	audio.gobelin.death = { i = 1 }
	audio.gobelin.death[1] = love.audio.newSource("sounds/gobelinDeath.wav", "static")
	audio.gobelin.death[1]:setVolume(0.5)
	audio.gobelin.death[2] = love.audio.newSource("sounds/gobelinDeath.wav", "static")
	audio.gobelin.death[2]:setVolume(0.5)

	audio.orc.attack = { i = 1 }
	for i = 1, 5 do
		audio.orc.attack[i] = love.audio.newSource("sounds/orcShoot.wav", "static")
		audio.orc.attack[i]:setVolume(0.5)
	end

	audio.orc.death = { i = 1 }
	audio.orc.death[1] = love.audio.newSource("sounds/orcDeath.wav", "static")
	audio.orc.death[1]:setVolume(0.5)
	audio.orc.death[2] = love.audio.newSource("sounds/orcDeath.wav", "static")
	audio.orc.death[2]:setVolume(0.5)
end

---@type Enemy[]
local enemies = {}

---@class Enemy
---@field spawn EnemySpawn
---@field health number
---@field in_stage boolean
---@field erase boolean
---@field spawn_vpos number
---@field state EnemyState
---@field motion Motion
---@field path_time number
---@field pos Vector
---@field vel Vector
---@field attack_time number|nil
---@field tvel Vector
---@field rot number
---@field flip boolean
---@field shape Vector[]
---@field sprites love.Image[]
---@field frame number
---@field loopframe number
---@field subframe number
local Enemy = {}
Enemy.__index = Enemy

Enemy.src_shape = {}

---@return Enemy
function Enemy:new()
	local o = {
		spawn = nil,
		health = 0,

		in_stage = false,
		erase = false,

		spawn_vpos = stage_vpos,
		state = state.moving,
		motion = behaviors.motions.basic,
		path_time = 0,

		pos = {
			x = 0,
			y = stage_vpos
		},
		vel = {
			x = 0,
			y = 0
		},

		attack_time = 0,
		tvel = {
			x = 0,
			y = 0
		},

		rot = 0,
		flip = false,
		shape = {},

		sprites = nil,
		frame = 1,
		loopframe = 1,
		subframe = 0,
	}

	setmetatable(o, self)
	return o
end

---@param spawn_info EnemySpawn
function Enemy:init(spawn_info)
	self.spawn = spawn_info
	self.health = spawn_info.attributes.life

	self.spawn_vpos = stage_vpos + spawn_info.pos.y
	if #spawn_info.path > 0 then
		self.motion = behaviors.motions.path
	end

	self.pos = {
		x = spawn_info.pos.x,
		y = stage_vpos + spawn_info.pos.y
	}

	self.vel = {
		x = spawn_info.attributes.velX * FLASH_FPS,
		y = spawn_info.attributes.velY * FLASH_FPS
	}

	self.flip = spawn_info.scale.x < 0

	for i = 1, #self.src_shape do
		self.shape[i] = { x = 0, y = 0 }
	end

	return self
end

function Enemy:update(dt)
	local pos = self.pos

	-- Animation
	self.subframe = self.subframe + dt * FLASH_FPS

	if self.subframe > 1 then
		if self.frame == #self.sprites then
			self.frame = self.loopframe
		else
			self.frame = self.frame + 1
		end
		self.subframe = self.subframe - 1
	end

	-- Attack
	if self.state == state.moving then
		self.attack_time = self.attack_time + dt

		if self.spawn.attributes.attack and self.attack_time > self.spawn.attributes.attackTime then
			self.state = state.attacking
			self:attack()
		end
	end

	self:motion(dt)

	if player.health > 0 and self.health > 0 then
		for si = 1, #self.shape, 2 do
			for pi = 1, #player.shape, 2 do
				if vector.segment_intersect(self.shape[si], self.shape[si + 1], player.shape[pi], player.shape[pi + 1]) then
					player:hit(0.1)
				end
			end
		end
	end

	-- In Bounds
	if self.in_stage then
		if (self.motion ~= behaviors.motions.path or self.path_time >= #self.spawn.path) and not self:is_in_world() then
			self.erase = true
			return
		end
	else
		if self:is_in_world() then
			self.in_stage = true
		end
	end

	-- Orientation
	if self.state == state.moving then
		if self.spawn.attributes.alignMotion then
			self.rot = math.atan2(self.vel.y, self.vel.x)
			self.flip = self.vel.x < 0
		elseif self.spawn.attributes.faceMotion then
			self.flip = self.vel.x < 0
		end
	end

	-- Transform Shape
	for i, p in ipairs(self.src_shape) do
		local point = self.shape[i]

		vector.rotate(point, p, self.rot)

		point.x = point.x * (self.flip and -1 or 1) + pos.x
		point.y = point.y + pos.y
	end
end

function Enemy:draw()
	local sprite = self.sprites[self.frame]
	local w, h = sprite:getDimensions()

	love.graphics.draw(sprite, -w / 2, -h / 2)
	love.graphics.setShader()
end

---@param projectile Projectile
function Enemy:hit(projectile)
	local _health = self.health
	self.health = self.health - projectile.damage
	if self.health <= 0 and _health > 0 then
		self.motion = behaviors.motions.fall
		self.state = state.dead
		self:death()
	end
end

function Enemy:death() end

function Enemy:grounded()
	local i = audio.grounded.i
	audio.grounded[i]:play()
	audio.grounded.i = i == 1 and 2 or 1
end

function Enemy:attack() end

function Enemy:is_in_world()
	local pos = self.pos
	local w, h = self.sprites[self.frame]:getDimensions()

	return
		pos.x > -w / 2 and pos.x < STAGE_WIDTH + w / 2 and
		pos.y > -h / 2 and pos.y < WORLD_HEIGHT + h / 2
end

---@class Gobelin:Enemy
local Gobelin = Enemy:new()
Gobelin.__index = Gobelin

---@type Vector[]
Gobelin.src_shape = {
	{ x = -18, y = -18 },
	{ x = 18,  y = 18 },
	{ x = -18, y = 18 },
	{ x = 18,  y = -18 },
}

function Gobelin:new()
	local o = Enemy:new()

	o.sprites = sprites.gobelin.idle

	setmetatable(o, self)
	return o
end

function Gobelin:update(dt)
	Enemy.update(self, dt)
	if self.state == state.attacking and self.frame == 68 and self.motion ~= behaviors.motions.charge then
		self.motion = behaviors.motions.charge

		local tx = player.pos.x - self.pos.x
		local ty = player.pos.y - self.pos.y
		local tlen = math.sqrt(tx * tx + ty * ty)
		self.tvel.x = tx / tlen * self.spawn.attributes.attackSpeed * FLASH_FPS
		self.tvel.y = ty / tlen * self.spawn.attributes.attackSpeed * FLASH_FPS

		local i = audio.gobelin.attack.i
		local attack = audio.gobelin.attack[i]
		attack:stop()
		attack:play()
		i = i + 1
		if i > #audio.gobelin.attack then
			i = 1
		end
		audio.gobelin.attack.i = i
	end
end

function Gobelin:draw()
	local sprite = self.sprites[self.frame]

	if self.spawn.type == "GobelinMaster" then
		shaders.color_mat:send("matrix",
			{ -2.37, 0.66, 0.66 },
			{ 3.1, 0.06, 3.1 },
			{ 0.27, 0.27, -2.7 },
			{ 0.2, 0.2, 0.2 }
		)
		love.graphics.setShader(shaders.color_mat)
	end

	if self.sprites == sprites.gobelin.death then
		love.graphics.draw(sprite, -56, -103)
	else
		love.graphics.draw(sprite, -60, -60)
	end
	love.graphics.setShader()
end

function Gobelin:attack()
	self.motion = behaviors.motions.slow

	self.subframe = 0
	self.frame = 1
	self.sprites = sprites.gobelin.attack
	self.loopframe = 68

	self.rot = 0
	self.flip = player.pos.x < self.pos.x
end

function Gobelin:death()
	self.sprites = sprites.gobelin.death
	self.frame = 1
	self.loopframe = 80

	local i = audio.gobelin.death.i
	audio.gobelin.death[i]:play()
	audio.gobelin.death.i = i == 1 and 2 or 1

	if self.spawn.type == "GobelinMaster" then
		score = score + 300
	else
		score = score + 200
	end
end

function Gobelin:grounded()
	Enemy.grounded(self)
	self.sprites = sprites.gobelin.grounded
	self.frame = 1
	self.loopframe = 1
end

---@class Orc:Enemy
local Orc = Enemy:new()
Orc.__index = Orc
---@type Vector[]

Orc.src_shape = {
	{ x = -21, y = -58 },
	{ x = 29,  y = -43 },

	{ x = 29,  y = -43 },
	{ x = 9,   y = 47 },

	{ x = 9,   y = 47 },
	{ x = -24, y = 37 },

	{ x = -24, y = 37 },
	{ x = -21, y = -58 },
}

function Orc:new()
	local o = Enemy:new()

	o.sprites = sprites.orc.idle

	setmetatable(o, self)
	return o
end

function Orc:update(dt)
	Enemy.update(self, dt)
	if self.state == state.attacking then
		if self.sprites == sprites.orc.attack and self.frame == 18 then
			self.state = state.idle

			local x_dir = self.flip and -1 or 1

			local cos = math.cos(self.rot)
			local sin = math.sin(self.rot)
			projectiles.new.spear(self.pos.x + 34.05 * x_dir, self.pos.y - 28, self.spawn.attributes.attackSpeed * FLASH_FPS * x_dir, 0, 1, self.spawn.attributes.attackDamage)

			local i = audio.orc.attack.i
			local attack = audio.orc.attack[i]
			attack:stop()
			attack:play()
			i = i + 1
			if i > #audio.orc.attack then
				i = 1
			end
			audio.orc.attack.i = i
		end
	elseif self.state == state.idle then
		if self.sprites == sprites.orc.attack and self.frame == 39 then
			self.state = state.moving

			self.attack_time = 0

			self.sprites = sprites.orc.idle
			self.frame = 1
			self.subframe = 0
			self.loopframe = 1
		end
	end
end

function Orc:draw()
	local sprite = self.sprites[self.frame]

	if self.spawn.type == "OrcMaster" then
		shaders.color_mat:send("matrix",
			{ 0.87, 0.45, -1.14 },
			{ -0.53, 1.96, 1.91 },
			{ 1.66, -0.41, 1.22 },
			{ -0.08, -0.08, -0.08 }
		)
		love.graphics.setShader(shaders.color_mat)
	end

	love.graphics.draw(sprite, -110, -110)
	love.graphics.setShader()
end

function Orc:attack()
	self.sprites = sprites.orc.attack
	self.frame = 1
	self.subframe = 0
	self.loopframe = 39
end

function Orc:death()
	self.sprites = sprites.orc.death
	self.frame = 1
	self.subframe = 0
	self.loopframe = 36

	local i = audio.orc.death.i
	audio.orc.death[i]:play()
	audio.orc.death.i = i == 1 and 2 or 1

	if self.spawn.type == "OrcMaster" then
		score = score + 525
	else
		score = score + 450
	end
end

function Orc:grounded()
	Enemy.grounded(self)
	self.sprites = sprites.orc.grounded
	self.frame = 1
	self.loopframe = 1
end

---@type table<string, Enemy>
local enemy_types = {
	["Gobelin"] = Gobelin,
	["GobelinMaster"] = Gobelin,
	["Orc"] = Orc,
	["OrcMaster"] = Orc,
}

---@param spawn_info EnemySpawn
local function new(spawn_info)
	table.insert(enemies, enemy_types[spawn_info.type]:new():init(spawn_info))
end

local function update(dt)
	for i = #enemies, 1, -1 do
		local enemy = enemies[i]
		enemy:update(dt)
		if enemy.erase then
			table.remove(enemies, i)
		end
	end
end

local function debug_enemies()
	for i, enemy in ipairs(enemies) do
		love.graphics.push()
		love.graphics.translate(enemy.spawn.pos.x, enemy.spawn_vpos)

		love.graphics.setColor(1, 1, 1)
		love.graphics.circle("fill", 0, 0, 4)
		love.graphics.print(enemy.spawn.type, 0, 0)

		if enemy.motion == behaviors.motions.path and enemy.path_time < #enemy.spawn.path then
			love.graphics.setColor(0, 0, 0, 0.2)
			for i, bezier in ipairs(enemy.spawn.path) do
				for i = 1, 50, 2 do
					local t = i / 50
					local _x, _y =
						sample_bezier(
							bezier.p1.x,
							bezier.p2.x,
							bezier.p3.x,
							bezier.p4.x,
							t
						),
						sample_bezier(
							bezier.p1.y,
							bezier.p2.y,
							bezier.p3.y,
							bezier.p4.y,
							t
						)

					t = (i + 1) / 50
					local x, y =
						sample_bezier(
							bezier.p1.x,
							bezier.p2.x,
							bezier.p3.x,
							bezier.p4.x,
							t
						),
						sample_bezier(
							bezier.p1.y,
							bezier.p2.y,
							bezier.p3.y,
							bezier.p4.y,
							t
						)

					love.graphics.line(_x, _y, x, y)
				end
			end
		end

		love.graphics.pop()

		love.graphics.setColor(1, 1, 1)
		for i = 1, #enemy.shape, 2 do
			love.graphics.line(
				enemy.shape[i].x,
				enemy.shape[i].y,
				enemy.shape[i + 1].x,
				enemy.shape[i + 1].y
			)
		end
	end
end

local function draw()
	love.graphics.setColor(1, 1, 1)
	for i, enemy in ipairs(enemies) do
		love.graphics.push()

		love.graphics.translate(enemy.pos.x, enemy.pos.y)

		love.graphics.rotate(enemy.rot)
		if enemy.state == state.moving and enemy.spawn.attributes.alignMotion then
			love.graphics.scale(1, enemy.flip and -1 or 1)
		else
			love.graphics.scale(enemy.flip and -1 or 1, 1)
		end

		enemy:draw()

		love.graphics.pop()
	end

	if debug_mode then
		debug_enemies()
	end
end

return {
	load = load,
	new = new,
	update = update,
	draw = draw,
	pool = enemies
}

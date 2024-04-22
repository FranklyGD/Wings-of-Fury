local behaviors = require "behaviors"

local sprites = {}
sprites.gobelin = {}

local function load()
	sprites.gobelin.idle = load_sprites("sprites/gobelinIdle")
	sprites.gobelin.attack = load_sprites("sprites/gobelinAttack")
end

---@type Enemy[]
local enemies = {}

---@class Enemy
---@field spawn EnemySpawn
---@field health number
---@field in_stage boolean
---@field erase boolean
---@field spawn_vpos number
---@field motion fun(self:self, dt:number)
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
		subframe = 0
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

	for i=1, #self.src_shape do
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
	self.attack_time = self.attack_time + dt

	if self.spawn.attributes.attack then
		if
			self.sprites ~= sprites.gobelin.attack and
			self.attack_time > self.spawn.attributes.attackTime
		then
			self.motion = behaviors.motions.slow

			self.subframe = 0
			self.frame = 1
			self.sprites = sprites.gobelin.attack
			self.loopframe = 68
		elseif self.frame == 68 and self.motion ~= behaviors.motions.charge then
			self.motion = behaviors.motions.charge

			local tx = player.pos.x - pos.x
			local ty = player.pos.y - pos.y
			local tlen = math.sqrt(tx * tx + ty * ty)
			self.tvel.x = tx / tlen * self.spawn.attributes.attackSpeed * FLASH_FPS
			self.tvel.y = ty / tlen * self.spawn.attributes.attackSpeed * FLASH_FPS
		end
	end

	self:motion(dt)

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
	if self.spawn.attributes.alignMotion then
		self.rot = math.atan2(self.vel.y, self.vel.x)
		self.flip = self.vel.x < 0
	elseif self.spawn.attributes.faceMotion then
		self.flip = self.vel.x < 0
	end

	-- Transform Shape
	for i, p in ipairs(self.src_shape) do
		local point = self.shape[i]

		vector.rotate(point, p, self.rot)

		point.x = point.x + pos.x
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
	self.health = self.health - projectile.damage
	if self.health <= 0 then
		self.erase = true
	end
end

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

function Gobelin:draw()
	local sprite = self.sprites[self.frame]
	local w, h = sprite:getDimensions()

	if self.spawn.type == "GobelinMaster" then
		shaders.color_mat:send("matrix",
			{ -2.37, 0.66, 0.66 },
			{ 3.1, 0.06, 3.1 },
			{ 0.27, 0.27, -2.7 },
			{ 52 / 255, 52 / 255, 52 / 255 }
		)
		love.graphics.setShader(shaders.color_mat)
	end

	love.graphics.draw(sprite, -w / 2, -h / 2)
	love.graphics.setShader()
end

---@type table<string, Enemy>
local enemy_types = {
	["Gobelin"] = Gobelin,
	["GobelinMaster"] = Gobelin
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
		if enemy.spawn.attributes.alignMotion then
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

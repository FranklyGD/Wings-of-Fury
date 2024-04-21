local behaviors = require "behaviors"

local sprites = {}
sprites.gobelin = {}
sprites.gobelin_master = {}

local function load()
	sprites.gobelin.idle = load_sprites("sprites/gobelinIdle")
	sprites.gobelin.attack = load_sprites("sprites/gobelinAttack")
end

---@param enemy Enemy
local function is_in_world(enemy)
	local pos = enemy.pos
	local w, h = enemy.sprites[enemy.frame]:getDimensions()

	return
		pos.x > -w / 2 and pos.x < STAGE_WIDTH + w / 2 and
		pos.y > -h / 2 and pos.y < WORLD_HEIGHT + h / 2
end

---@class Enemy
---@field spawn EnemySpawn
---@field spawn_vpos number
---@field health number
---@field pos Vector
---@field rot number
---@field flip boolean
---@field shape Vector[]
---@field vel Vector
---@field path_time number
---@field attack_time number
---@field erase boolean
---@field update fun(self:self, dt:number)
---@field draw fun(self:self)
---@field motion fun(self:self, dt:number)
---@field hit fun(self:self, projectile:Projectile)
---@field in_stage boolean
---@field sprites love.Image[]
---@field frame number
---@field loopframe number
---@field subframe number

---@type Enemy[]
local enemies = {}

---@class Gobelin:Enemy
---@field tvel Vector

---@type Vector[]
local gobelin_shape = {
	{ x = -18, y = -18 },
	{ x = 18,  y = 18 },
	{ x = -18, y = 18 },
	{ x = 18,  y = -18 },
}

---@param spawn_info EnemySpawn
---@return Gobelin
local function new_gobelin(spawn_info)
	---@type Gobelin
	return {
		spawn = spawn_info,
		health = spawn_info.attributes.life,
		erase = false,
		path_time = 0,
		attack_time = 0,
		spawn_vpos = stage_vpos + spawn_info.pos.y,
		pos = {
			x = spawn_info.pos.x,
			y = stage_vpos + spawn_info.pos.y
		},
		rot = 0,
		flip = false,
		vel = {
			x = spawn_info.attributes.velX * FLASH_FPS,
			y = spawn_info.attributes.velY * FLASH_FPS
		},
		tvel = {
			x = 0,
			y = 0
		},
		shape = {
			{ x = 0, y = 0 },
			{ x = 0, y = 0 },
			{ x = 0, y = 0 },
			{ x = 0, y = 0 }
		},

		---@param self Gobelin
		update = function(self, dt)
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
				if (self.motion ~= behaviors.motions.path or self.path_time >= #self.spawn.path) and not is_in_world(self) then
					self.erase = true
					return
				end
			else
				if is_in_world(self) then
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
			for i, p in ipairs(gobelin_shape) do
				local point = self.shape[i]

				vector.rotate(point, p, self.rot)

				point.x = point.x + pos.x
				point.y = point.y + pos.y
			end
		end,
		draw = function(self)
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
		end,
		hit = function (self, projectile)
			self.health = self.health - projectile.damage
			if self.health <= 0 then
				
				self.erase = true
			end
		end,
		motion = #spawn_info.path > 0 and behaviors.motions.path or behaviors.motions.basic,
		in_stage = false,
		sprites = sprites.gobelin.idle,
		frame = 1,
		loopframe = 1,
		subframe = 0
	}
end

---@type table<string, fun(spawn_info:EnemySpawn)>
local enemy_types = {
	["Gobelin"] = new_gobelin,
	["GobelinMaster"] = new_gobelin
}

---@param spawn_info EnemySpawn
local function new(spawn_info)
	table.insert(enemies, enemy_types[spawn_info.type](spawn_info))
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
			love.graphics.setColor(1, 1, 1, 0.2)
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

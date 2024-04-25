local gfx = love.graphics
local player = {}

---@type table<string, PlayerStats>
local players

local sprites = {}
sprites.spyro = {}
sprites.fire_charge = {}

local audio = {}
audio.flaps = {}
audio.fire_shoot = {}
audio.fire_charge = {}

---@type Vector[]
local head_locations = {
	{ x = 21.25, y = 12.20 },
	{ x = 21.15, y = 14.35 },
	{ x = 21.00, y = 16.55 },
	{ x = 20.90, y = 18.70 },
	{ x = 20.75, y = 20.85 },
	{ x = 20.55, y = 22.10 },
	{ x = 20.40, y = 23.35 },
	{ x = 20.20, y = 24.60 },
	{ x = 21.05, y = 24.15 },
	{ x = 21.95, y = 23.64 },
	{ x = 22.80, y = 23.20 },
	{ x = 23.10, y = 21.45 },
	{ x = 23.40, y = 19.65 },
	{ x = 23.70, y = 17.90 },
	{ x = 24.75, y = 12.70 },
	{ x = 25.80, y = 7.50 },
	{ x = 26.35, y = 2.50 },
	{ x = 26.85, y = -2.55 },
	{ x = 26.15, y = -5.30 },
	{ x = 25.45, y = -8.00 },
	{ x = 24.75, y = -10.75 },
	{ x = 24.55, y = -10.65 },
	{ x = 24.35, y = -10.55 },
	{ x = 24.10, y = -10.40 },
	{ x = 23.90, y = -10.30 },
	{ x = 23.70, y = -10.20 },
	{ x = 23.70, y = -9.45 },
	{ x = 23.70, y = -8.75 },
	{ x = 23.70, y = -8.00 },
	{ x = 24.05, y = -6.80 },
	{ x = 24.40, y = -5.65 },
	{ x = 24.75, y = -4.45 },
	{ x = 24.35, y = -3.40 },
	{ x = 23.95, y = -2.30 },
	{ x = 23.55, y = 1.25 },
	{ x = 23.20, y = -0.15 },
	{ x = 22.80, y = 0.90 },
	{ x = 22.40, y = 2.00 },
	{ x = 22.00, y = 3.05 },
	{ x = 21.95, y = 4.15 },
	{ x = 21.85, y = 5.20 },
	{ x = 21.80, y = 6.30 },
	{ x = 21.75, y = 7.40 },
	{ x = 21.65, y = 8.45 },
	{ x = 21.60, y = 9.55 },
}

local shape = {
	{ x = -60.55, y = 8.45 },
	{ x = 2.45,   y = 12.45 },
	{ x = 29.45,  y = 4.45 },
	{ x = 5.45,   y = -10.55 },
}

local shape_transformed = {
	{ x = 0, y = 0 },
	{ x = 0, y = 0 },
	{ x = 0, y = 0 },
	{ x = 0, y = 0 },
}

function player:load(data)
	players = data.players

	sprites.spyro.flying = load_sprites("sprites/spyroFlying")
	sprites.spyro.head = gfx.newImage("sprites/spyroHead.png")
	sprites.fire_charge.core = load_sprites("sprites/fireCharge")
	sprites.fire_charge.glow = gfx.newImage("sprites/fireChargeGlow.png")

	audio.flaps[1] = love.audio.newSource("sounds/flap0.wav", "static")
	audio.flaps[1]:setVolume(0.5)
	audio.flaps[2] = love.audio.newSource("sounds/flap1.wav", "static")
	audio.flaps[2]:setVolume(0.5)
	audio.fire_shoot = { i = 1 }
	for i = 1, 5 do
		audio.fire_shoot[i] = love.audio.newSource("sounds/shootFlame.wav", "static")
	end
	audio.fire_charge = love.audio.newSource("sounds/chargeFlame.wav", "static")
end

---@param name string
function player:onNewGame(name)
	self.stats = players[name]

	---@type Vector
	self.pos = {
		x = -50,
		y = WORLD_HEIGHT / 2
	}

	---@type Vector
	self.vel = {
		x = 10 * FLASH_FPS,
		y = 0 * FLASH_FPS
	}

	self.rot = 0
	self.trot = 0
	self.angvel = 0

	self.head_rot = 0

	self.sprites = sprites.spyro.flying

	self.frame = 1
	self.subframe = 0.0
	self.frame_speed = 1
	self.loopframe = 1
	self.flapping = false
	self.alt_flap = false

	self.charge = 0.0
	self.charge_frame = 0
	self.charge_subframe = 0.0
end

function player:update(dt)
	-- Animation
	self.subframe = self.subframe + dt * FLASH_FPS * self.frame_speed

	if self.subframe > 1 then
		local frames = math.floor(self.subframe)

		self.frame = self.frame + frames

		if self.frame > #self.sprites then
			self.frame = self.loopframe
		end

		self.subframe = self.subframe - frames
	end

	self.charge_subframe = self.subframe + dt * FLASH_FPS

	if self.charge_subframe > 1 then
		if self.charge_frame < 0 then
			self.charge_frame = -math.random(#sprites.fire_charge.core)
			self.charge_subframe = math.fmod(self.charge_subframe, 1)
		elseif self.charge_frame > 0 then
			local frames = math.floor(self.charge_subframe)

			self.charge_frame = self.charge_frame + frames

			if self.charge_frame > 13 then
				self.charge_frame = 0
			end

			self.charge_subframe = self.charge_subframe - frames
		end
	end

	local vel = self.vel

	vel.y = vel.y + self.stats.gravity * FLASH_FPS * FLASH_FPS * dt

	local t = math.pow(self.stats.windResistance, dt * FLASH_FPS)
	vel.x = vel.x * t
	vel.y = vel.y * t

	-- Movement
	self.frame_speed = 1
	self.flap_resistance = 1
	self.trot = 0
	local speed = self.stats.speed * FLASH_FPS

	local left_pressed = love.keyboard.isDown("a") or love.keyboard.isDown("left")
	local right_pressed = love.keyboard.isDown("d") or love.keyboard.isDown("right")
	local up_pressed = love.keyboard.isDown("w") or love.keyboard.isDown("up")
	local down_pressed = love.keyboard.isDown("s") or love.keyboard.isDown("down")

	if left_pressed then
		self.frame_speed = 2
		self.trot = math.rad(-70)
		self.flap_resistance = 0.6
	elseif right_pressed then
		self.trot = math.rad(20)
		vel.x = vel.x + speed
	end

	if up_pressed then
		self.frame_speed = 2
		if left_pressed then
			self.trot = math.rad(-45)
			self.flap_resistance = 0.8
		elseif right_pressed then
			self.trot = math.rad(45)
			vel.x = vel.x - speed
		else
			self.trot = math.rad(-7)
		end
	elseif down_pressed then
		if left_pressed then
			self.trot = math.rad(-100)
		elseif right_pressed then
			self.trot = math.rad(45)
		else
			self.frame_speed = 0.8
			self.trot = math.rad(20)
		end
		vel.y = vel.y + speed
	end

	-- Flap
	if self.frame - 1 / #self.sprites - 2 > 0.4 then
		if not self.flapping then
			self.flapping = true

			local flap_speed = self.stats.flapStrength * self.frame_speed * self.flap_resistance * FLASH_FPS
			local flap_angle = self.rot - math.pi / 2

			local vel = self.vel
			vel.x = vel.x + math.cos(flap_angle) * flap_speed
			vel.y = vel.y + math.sin(flap_angle) * flap_speed

			audio.flaps[self.alt_flap and 2 or 1]:play()
			self.alt_flap = not self.alt_flap
		end
	else
		self.flapping = false
	end

	self.angvel = self.angvel * self.stats.bodyFriction +
		math.nearest_angle(self.rot, self.trot) * self.stats.bodyStiffness
	self.rot = self.rot + self.angvel * FLASH_FPS * dt

	local pos = self.pos
	pos.x = pos.x + vel.x * dt
	pos.y = pos.y + vel.y * dt

	-- Keep in World
	if vel.x < 0 and pos.x < 20 then
		pos.x = 20
		vel.x = 0
	end

	if vel.x > 0 and pos.x > STAGE_WIDTH - 50 then
		pos.x = STAGE_WIDTH - 50
		vel.x = 0
	end

	if vel.y < 0 and pos.y < 100 then
		pos.y = 100
		vel.y = 0
	end

	if vel.y > 0 and pos.y > GROUND_HEIGHT - 50 then
		pos.y = GROUND_HEIGHT - 50
		vel.y = 0
	end

	-- Transform Shape
	for i, p in ipairs(shape) do
		local point = shape_transformed[i]

		vector.rotate(point, p, self.rot)

		point.x = point.x + pos.x
		point.y = point.y + pos.y
	end

	-- Rotate Head
	local mouse_x, mouse_y = love.mouse.getPosition()
	local head_pos = head_locations[self.frame]

	---@type Vector
	local rotated_head_pos = { x = 0, y = 0 }
	vector.rotate(rotated_head_pos, head_pos, self.rot)

	local dir_x, dir_y =
		mouse_x - rotated_head_pos.x - pos.x,
		mouse_y + stage_vpos - rotated_head_pos.y - pos.y

	local head_rot = math.atan2(dir_y, dir_x)
	if head_rot < -math.pi / 4 + self.rot then
		head_rot = -math.pi / 4 + self.rot
	elseif head_rot > math.pi / 2 + self.rot then
		head_rot = math.pi / 2 + self.rot
	end
	self.head_rot = math.lerp(head_rot, self.head_rot, math.exp(-dt * 20))

	-- Shooting
	if love.mouse.isDown(1) then
		local charge = self.charge
		if charge == 0 then
			audio.fire_charge:play()
			self.charge_frame = -1
		end

		charge = charge + dt * FLASH_FPS / self.stats.shotHoldMax
		if charge > 1 then
			charge = 1
		end
		self.charge = charge
	elseif self.charge > 0 then
		local damage = self.charge * self.stats.shotStrengthMax
		local speed = (self.stats.shotStrength + self.charge * self.stats.shotStrengthMax) * FLASH_FPS
		local scale = 1 + self.charge * 3

		local cos = math.cos(self.head_rot)
		local sin = math.sin(self.head_rot)
		projectiles.new.fireball(
			cos * 15 + rotated_head_pos.x + pos.x,
			sin * 15 + rotated_head_pos.y + pos.y,
			cos * speed,
			sin * speed,
			scale,
			damage
		)
		audio.fire_charge:stop()

		local i = audio.fire_shoot.i
		local fire_shoot = audio.fire_shoot[i]
		fire_shoot:stop()
		fire_shoot:play()
		i = i + 1
		if i > #audio.fire_shoot then
			i = 1
		end
		audio.fire_shoot.i = i

		self.charge = 0
		self.charged = false
		self.charge_frame = 1
	end
end

function player:draw()
	gfx.push()
	gfx.translate(self.pos.x, self.pos.y)
	gfx.rotate(self.rot)
	gfx.setColor(1, 1, 1)

	local sprite = self.sprites[self.frame]
	gfx.draw(sprite, -75, -75)

	sprite = sprites.spyro.head
	local head_pos = head_locations[self.frame]
	gfx.translate(head_pos.x, head_pos.y)
	gfx.rotate(self.head_rot - self.rot)

	if self.charge_frame ~= 0 then
		gfx.push()
		if self.charge_frame < 0 then
			gfx.setColor(1, 1, 1, self.charge)
			gfx.translate(15, 0)
			gfx.scale(self.charge)
		else
			local t = (self.charge_frame) / 13
			gfx.setColor(1, 1, 1, 1 - t)
			gfx.translate(15 + t * 50, 0)
			gfx.scale(math.lerp(2, 1, t), math.lerp(0.5, 2, (1 - t) * (1 - t)))
		end

		gfx.draw(sprites.fire_charge.glow, 0, 0, 0, 1, 1, 41, 41)
		gfx.draw(sprites.fire_charge.core[self.charge_frame < 0 and -self.charge_frame or 1], 0, 0, 0, 1, 1, 14, 14)
		gfx.pop()
	end

	gfx.setColor(1, 1, 1)
	gfx.draw(sprite, 0, 0, 0, 1, 1, 96, 86)

	gfx.pop()

	if debug_mode then
		gfx.line(
			shape_transformed[1].x,
			shape_transformed[1].y,
			shape_transformed[2].x,
			shape_transformed[2].y,
			shape_transformed[3].x,
			shape_transformed[3].y,
			shape_transformed[4].x,
			shape_transformed[4].y,
			shape_transformed[1].x,
			shape_transformed[1].y
		)
	end
end

return player

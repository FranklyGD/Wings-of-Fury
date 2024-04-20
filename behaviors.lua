local motions = {}
local lerp = math.lerp

---@param enemy Enemy
---@param dt number
function motions.basic(enemy, dt)
	local pos = enemy.pos
	local vel = enemy.vel
	pos.x = pos.x + vel.x * dt
	pos.y = pos.y + vel.y * dt
end

---@param enemy Enemy
---@param dt number
function motions.path(enemy, dt)
	local speed = FLASH_FPS * enemy.spawn.attributes.speed / 1000
	local path_time = enemy.path_time + dt * speed

	if path_time > #enemy.spawn.path then
		if enemy.spawn.attributes.loop then
			enemy.path_time = path_time
		elseif enemy.spawn.attributes.remove_end then
			enemy.erase = true
		else
			enemy.motion = motions.basic
		end
	else
		local bezier = enemy.spawn.path[math.floor(path_time + 1)]
		local t = path_time - math.floor(path_time)

		local pos = enemy.pos
		pos.x, pos.y =
			enemy.spawn.pos.x + sample_bezier(
				bezier.p1.x,
				bezier.p2.x,
				bezier.p3.x,
				bezier.p4.x,
				t
			),
			enemy.spawn_vpos + sample_bezier(
				bezier.p1.y,
				bezier.p2.y,
				bezier.p3.y,
				bezier.p4.y,
				t
			)

		local vel = enemy.vel
		vel.x, vel.y =
			sample_bezier_tangent(
				bezier.p1.x,
				bezier.p2.x,
				bezier.p3.x,
				bezier.p4.x,
				t
			) * speed,
			sample_bezier_tangent(
				bezier.p1.y,
				bezier.p2.y,
				bezier.p3.y,
				bezier.p4.y,
				t
			) * speed
	end

	enemy.path_time = path_time
end

---@param enemy Enemy
---@param dt number
function motions.slow(enemy, dt)
	local vel = enemy.vel
	local fraction = math.exp(-dt)
	vel.x = vel.x * fraction
	vel.y = vel.y * fraction

	local pos = enemy.pos
	pos.x = pos.x + vel.x * dt
	pos.y = pos.y + vel.y * dt
end

---@param enemy Gobelin
---@param dt number
function motions.charge(enemy, dt)
	local vel = enemy.vel
	local tvel = enemy.tvel
	local fraction = math.exp(-dt * 5)
	vel.x = lerp(tvel.x, vel.x, fraction)
	vel.y = lerp(tvel.y, vel.y, fraction)

	local pos = enemy.pos
	pos.x = pos.x + vel.x * dt
	pos.y = pos.y + vel.y * dt
end

return {
	motions = motions
}

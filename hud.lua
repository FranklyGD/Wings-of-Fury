local gfx = love.graphics

local hud = {}

local score_font = gfx.newFont("TrajanPro-Bold.otf", 20)
local level_count_font = gfx.newFont("TrajanPro-Bold.otf", 55)
local sprites = {}

local current_level_count = 0
local level_count_display_time = 0

local last_health_display = 1
local health_display_delay = 0

---@param number number
---@return string
local function comma_seperated_number(number)
	local string_num = ""

	while number >= 1000 do
		local seperated_number = number
		number = math.floor(number / 1000)
		seperated_number = seperated_number - number * 1000
		string_num = "," .. ("%03d"):format(seperated_number) .. string_num
	end

	string_num = number .. string_num

	return string_num
end

function hud:load()
	sprites.next_level_panel = gfx.newImage("sprites/nextLevelPanel.png")
	sprites.hud_top = gfx.newImage("sprites/hudTop.png")
	sprites.player_bar_bg = gfx.newImage("sprites/playerBarBG.png")
	sprites.player_portrait_frame = gfx.newImage("sprites/playerPortraitFrame.png")
	sprites.spyro_portrait = gfx.newImage("sprites/spyroPortrait.png")
end

function hud:update(dt)
	if current_level_count ~= level.current_level then
		current_level_count = level.current_level
		level_count_display_time = 3
	end

	level_count_display_time = level_count_display_time - dt
	if level_count_display_time < 0 then
		level_count_display_time = 0
	end

	if player.health < last_health_display then
		health_display_delay = health_display_delay - dt
		if health_display_delay < 0 then
			last_health_display = last_health_display - dt * 0.5
			if last_health_display <= player.health then
				last_health_display = player.health
			end
		end
	else
		last_health_display = player.health
		health_display_delay = 0.5
	end
end

function hud:draw()
	if end_time > 0 then
		gfx.setColor(1, 1, 1)
		gfx.draw(sprites.hud_top, 10, 0)

		gfx.draw(sprites.player_bar_bg, 25, 10, 0, 0.5, 0.5)
		local w, h = sprites.spyro_portrait:getDimensions()
		w = 62 / w
		h = 62 / h

		gfx.setColor(0.25, 0.25, 0.25)
		gfx.circle("fill", 62, 50, 35)

		gfx.setColor(1, 1, 1)
		gfx.draw(sprites.spyro_portrait, 30, 18, 0, w, h)
		gfx.draw(sprites.player_portrait_frame, 10, 0, 0, 0.75, 0.75)
		-- Health Bar
		local health_bar_x, health_bar_y = 105, 30
		local health_bar_w, health_bar_h = 90, 7

		gfx.setColor(0.25, 0.25, 0.25)
		gfx.rectangle("fill", health_bar_x - 1, health_bar_y - 1, health_bar_w + 2, health_bar_h + 2)

		local special_pips_y = health_bar_y + 12
		for i = 1, 3 do
			gfx.circle("fill", health_bar_x + 4 + (i - 1) * 11, special_pips_y, 5)
		end

		gfx.setColor(1, 1, 1)
		gfx.rectangle("fill", health_bar_x, health_bar_y, health_bar_w * last_health_display, health_bar_h)
		gfx.setColor(1, 0.25, 0)
		gfx.rectangle("fill", health_bar_x, health_bar_y, health_bar_w * player.health, health_bar_h)

		gfx.setColor(0.25, 1, 0)
		for i = 1, player.specials do
			gfx.circle("fill", health_bar_x + 4 + (i - 1) * 11, special_pips_y, 4)
		end

		-- Score
		gfx.setColor(1, 0.8, 0)

		gfx.push()
		gfx.translate(365 + 183, 24)
		gfx.printf("Score", score_font, 0, 0, 200, "center", 0, 1, 1, 100)
		gfx.printf(comma_seperated_number(score), score_font, 0, 20, 200, "center", 0, 1, 1, 100)
		gfx.pop()

		local display_alpha = math.min(2 * (1.5 - math.abs(level_count_display_time - 1.5)), 1)

		gfx.push()
		gfx.translate(365, 225)

		gfx.setColor(1, 1, 1, display_alpha)
		gfx.draw(sprites.next_level_panel, 0, 0, 0, 1, 1, 150, 40)

		local text = "Level " .. level.current_level
		gfx.translate(0, -20)
		gfx.setColor(0, 0, 0, display_alpha * 0.75)
		gfx.printf(text, level_count_font, 3, 3, 500, "center", 0, 1, 1, 250)
		gfx.setColor(1, 1, 1, display_alpha)
		gfx.printf(text, level_count_font, -1, -1, 500, "center", 0, 1, 1, 250)
		gfx.setColor(1, 0.7, 0, display_alpha)
		gfx.printf(text, level_count_font, 0, 0, 500, "center", 0, 1, 1, 250)

		gfx.pop()
	else
		local w, h = gfx.getDimensions()
		gfx.setColor(0, 0, 0, 0.5)
		gfx.rectangle("fill", 0, 0, w, h)
	end
end

return hud

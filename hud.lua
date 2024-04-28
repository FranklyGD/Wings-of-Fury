local hud = {}

local score_font = love.graphics.newFont("TrajanPro-Bold.otf", 20)
local level_count_font = love.graphics.newFont("TrajanPro-Bold.otf", 55)
local sprites = {}

local current_level_count = 0
local level_count_display_time = 0

---@param number number
---@return string
local function comma_seperated_number(number)
	local string_num = ""

	while number > 999 do
		local seperated_number = number
		number = math.floor(number / 1000)
		seperated_number = seperated_number - number * 1000
		string_num = "," .. ("%03d"):format(seperated_number) .. string_num
	end

	string_num = number .. string_num

	return string_num
end

function hud:load()
	sprites.next_level_panel = love.graphics.newImage("sprites/nextLevelPanel.png")
	sprites.hud_top = love.graphics.newImage("sprites/hudTop.png")
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
end

function hud:draw()
	local w, h = love.graphics.getDimensions()
	if end_time > 0 then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(sprites.hud_top, 10, 0)

		love.graphics.setColor(1, 0.8, 0)

		love.graphics.push()
		love.graphics.translate(w / 2, 24)
		love.graphics.printf("Score", score_font, 0, 0, 200, "center", 0, 1, 1, 100)
		love.graphics.printf(comma_seperated_number(score), score_font, 0, 20, 200, "center", 0, 1, 1, 100)
		love.graphics.pop()

		local display_alpha = math.min(2 * (1.5 - math.abs(level_count_display_time - 1.5)), 1)

		love.graphics.push()
		love.graphics.translate(w / 2, h / 2)

		love.graphics.setColor(1, 1, 1, display_alpha)
		love.graphics.draw(sprites.next_level_panel, 0, 0, 0, 1, 1, 150, 40)

		local text = "Level " .. level.current_level
		love.graphics.translate(0, -20)
		love.graphics.setColor(0, 0, 0, display_alpha * 0.75)
		love.graphics.printf(text, level_count_font, 3, 3, 500, "center", 0, 1, 1, 250)
		love.graphics.setColor(1, 1, 1, display_alpha)
		love.graphics.printf(text, level_count_font, -1, -1, 500, "center", 0, 1, 1, 250)
		love.graphics.setColor(1, 0.7, 0, display_alpha)
		love.graphics.printf(text, level_count_font, 0, 0, 500, "center", 0, 1, 1, 250)

		love.graphics.pop()
	else
		local w, h = love.graphics.getDimensions()
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle("fill", 0, 0, w, h)
	end
end

return hud

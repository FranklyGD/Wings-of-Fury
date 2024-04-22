-- Debug (Using VSCode extension "Local Lua Debugger")
if arg[#arg] == "vsc_debug" then
	local lldebugger = require "lldebugger"
	lldebugger.start()
	local run = love.run
	function love.run(...)
		local f = lldebugger.call(run, false, ...)
		return function(...) return lldebugger.call(f, false, ...) end
	end
end

--
require "emath"
require "constants"
require "vector"

_G.debug_mode = false

---@type table<string, PlayerStats>
local players

---@type {time:number, event:Event, current_slice: number}[]
local active_events = {}
_G.load_sprites = require "sprites"
_G.shaders = require "shaders"
_G.level = require "level"
_G.player = require "player"
_G.enemies = require "enemies"
_G.projectiles = require "projectiles"
_G.scroller = require "scroller"

local bg1_scroller = scroller:new("sprites/bg1.png", 5)
local bg2_scroller = scroller:new("sprites/bg2.png", 15)
local bg3_scroller = scroller:new("sprites/bg3.png", 50)
local bg4_scroller = scroller:new("sprites/bg4.png", 250)
local bg5_scroller = scroller:new("sprites/bg5.png", 500)

_G.stage_vpos = 0

function love.load()
	local file_data = require "loader"

	level:load(file_data)

	projectiles.load()
	enemies.load()

	player:load(file_data)
	player:onNewGame("Spyro")
end

function love.update(dt)
	level:update(dt)
	projectiles.update(dt)
	enemies.update(dt)
	player:update(dt)

	stage_vpos = math.lerp(player.pos.y - STAGE_HEIGHT / 2, stage_vpos, math.pow(0.9, FLASH_FPS * dt))
	if stage_vpos < 0 then
		stage_vpos = 0
	elseif stage_vpos > WORLD_HEIGHT - STAGE_HEIGHT then
		stage_vpos = WORLD_HEIGHT - STAGE_HEIGHT
	end

	bg1_scroller:update(dt)
	bg2_scroller:update(dt)
	bg3_scroller:update(dt)
	bg4_scroller:update(dt)
	bg5_scroller:update(dt)

	bg1_scroller.pos.y = stage_vpos * 0.05
	bg2_scroller.pos.y = stage_vpos * 0.1
	bg3_scroller.pos.y = stage_vpos * 0.3 - 335
	bg4_scroller.pos.y = stage_vpos * 0.9 - 245
	bg5_scroller.pos.y = stage_vpos * 1.0 - 490
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	bg1_scroller:draw()
	bg2_scroller:draw()
	bg3_scroller:draw()
	bg4_scroller:draw()
	bg5_scroller:draw()

	if debug_mode then
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.line(0, WORLD_HEIGHT / 2 - stage_vpos, STAGE_WIDTH, WORLD_HEIGHT / 2 - stage_vpos)
		love.graphics.rectangle("line", 0, 0, STAGE_WIDTH, WORLD_HEIGHT - stage_vpos)

		love.graphics.setColor(0, 0, 0)
		love.graphics.print(("FPS: %.02f"):format(love.timer.getFPS()))
		love.graphics.print(("Level %d"):format(level.current_level), 10, 10)
		love.graphics.print(("Time Remaining %.02f"):format(level:getInfo().duration - level.time), 10, 20)
		love.graphics.print(("Enemies %d"):format(#enemies.pool), 10, 30)
		love.graphics.print(("Projectiles %d"):format(#projectiles.pool), 10, 40)
	end

	love.graphics.push()
	love.graphics.translate(0, -stage_vpos)

	enemies.draw()
	player:draw()
	projectiles.draw()

	love.graphics.pop()
end

function love.keypressed(key)
	if key == "`" then
		debug_mode = not debug_mode
	end
end

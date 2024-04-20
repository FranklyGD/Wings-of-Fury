---@alias EnemySpawn {type: string, pos:Vector, scale:Vector, path:Bezier[], attributes:table<string,any>}
---@alias Slice {time: number, repeat: number, switch: number, spawns: EnemySpawn[]}
---@alias Event {time: number, repeat: number, switch: number, slices: Slice[]}

---@class Level
---@field start number
---@field duration number
---@field timeline Event[]

---@type Level[]
local levels = {}

---@class PlayerStats
---@field speed number
---@field gravity number
---@field flapStrength number
---@field bodyFriction number
---@field bodyStiffness number
---@field windResistance number
---@field shotHoldMax number
---@field shotStrength number
---@field shotStrengthMax number

---@type table<string, PlayerStats>
local players = {}

local xml = require("xml")
local config_data = xml.read("levels/config.xml")

local players_data = config_data.config.inner.players.inner
for i, v in ipairs(players_data) do
	local player = {}

	for i, v in ipairs(v.inner) do
		player[v.type] = tonumber(v.inner)
	end

	players[v.type] = player
end

local current_level = tonumber(config_data.config.inner.levels.attributes.startLevel) + 1

local level_order = {}
local levels_data = config_data.config.inner.levels.inner
for i, v in ipairs(levels_data) do
	table.insert(level_order, v.inner)
end

for i, level_name in ipairs(level_order) do
	local level_data = xml.read("levels/" .. level_name .. ".xml")

	---@type Event[]
	local events = {}

	levels[i] = {
		start = tonumber(level_data.level.attributes.startTime),
		duration = tonumber(level_data.level.attributes.levelTime),
		timeline = events
	}

	for i, v in ipairs(level_data.level.inner.keyFrames.inner) do
		---@type Slice[]
		local slices = {}

		events[i] = {
			time = tonumber(v.attributes.time),
			["repeat"] = v.attributes.repeatCount,
			switch = v.attributes.repeatSwitch,
			slices = slices
		}

		if v.inner then
			for i, v in ipairs(v.inner) do
				---@type EnemySpawn[]
				local spawns = {}

				slices[i] = {
					time = tonumber(v.attributes.time),
					["repeat"] = v.attributes.repeatCount,
					switch = v.attributes.repeatSwitch,
					spawns = spawns
				}

				for i, v in ipairs(v.inner.objects.inner) do
					---@type Bezier[]
					local path = {}
					local attributes = {}

					spawns[i] = {
						type = v.attributes.type,
						pos = {
							x = tonumber(v.attributes.x),
							y = tonumber(v.attributes.y)
						},
						scale = {
							x = tonumber(v.attributes.scaleX),
							y = tonumber(v.attributes.scaleY)
						},
						path = path,
						attributes = attributes
					}

					if v.inner.attribs then
						for name, value in pairs(v.inner.attribs.attributes) do
							attributes[name] = tonumber(value) or value == "true" or value ~= "false" and value
						end
					end

					if v.inner.motion.inner then
						for i, v in ipairs(v.inner.motion.inner) do
							path[i] = {
								p1 = {
									x = tonumber(v.attributes.sx),
									y = tonumber(v.attributes.sy),
								},
								p2 = {
									x = tonumber(v.attributes.cx1),
									y = tonumber(v.attributes.cy1),
								},
								p3 = {
									x = tonumber(v.attributes.cx2),
									y = tonumber(v.attributes.cy2),
								},
								p4 = {
									x = tonumber(v.attributes.ex),
									y = tonumber(v.attributes.ey),
								}
							}
						end
					end
				end
			end
		end
	end
end

return {
	starting_level = current_level,
	players = players,
	levels = levels
}

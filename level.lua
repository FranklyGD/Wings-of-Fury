local level = {}
level.time = 0
level.current_level = 1
level.current_event = 1
level.active_events = {}

---@type Level[]
local levels

function level:getInfo()
	return levels[self.current_level]
end

function level:load(data)
	self.current_event = data.starting_level
	levels = data.levels
end

function level:update(dt)
	self.time = self.time + dt

	local level_info = levels[self.current_level]
	if self.time > level_info.duration then
		self.time = 0
		self.current_level = self.current_level + 1
		self.current_event = 1
	else
		local event = level_info.timeline[self.current_event]
		if event and level.time > event.time then
			table.insert(self.active_events, {
				time = self.time - event.time,
				event = event,
				current_slice = 1
			})
			level.current_event = level.current_event + 1
		end
	end

	for i = #self.active_events, 1, -1 do
		local active_event = self.active_events[i]
		active_event.time = active_event.time + dt
		local next_slice = active_event.event.slices[active_event.current_slice]
		if active_event.time > next_slice.time then
			for i, spawn in ipairs(next_slice.spawns) do
				enemies.new(spawn)
			end

			if active_event.current_slice == #active_event.event.slices then
				table.remove(self.active_events, i)
			else
				active_event.current_slice = active_event.current_slice + 1
			end
		end
	end
end

return level

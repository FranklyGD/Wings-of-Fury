---@param dir string
---@return love.Image[]
local function loadImages(dir)
	---@type string[]
	local sprite_files = love.filesystem.getDirectoryItems(dir)

	local images = {}
	for i, sprite_file in ipairs(sprite_files) do
		local frame = tonumber(sprite_file:sub(1, -5))

		images[frame] = love.graphics.newImage(dir .. "/" .. sprite_file)
	end

	return images
end

return loadImages

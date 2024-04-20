local function is_whitespace(str)
	return #str == 1 and (
		str == "\n" or
		str == "\r" or
		str == "\t" or
		str == " "
	)
end

local function is_quotes(str)
	return #str == 1 and (
		str == "\"" or
		str == "\'"
	)
end

local function read_string(str, i)
	local quote = str:sub(i, i)
	if not is_quotes(quote) then return end
	i = i + 1

	local string_start = i
	while i <= #str do
		i = i + 1
		local char = str:sub(i, i)
		if char == quote then break end
	end

	return str:sub(string_start, i - 1), i + 1
end

local function read_name(str, i)
	local start = i
	while i <= #str do
		local char = str:sub(i, i)
		if not (
				is_whitespace(char) or
				is_quotes(char) or
				char == "/" or
				char == ">" or
				char == "<" or
				char == "="
			) then
			i = i + 1
		else
			break
		end
	end

	return str:sub(start, i - 1), i
end

local function skip_whitespace(str, i)
	while i <= #str do
		local char = str:sub(i, i)
		if is_whitespace(char) then
			i = i + 1
		else
			break
		end
	end

	return i
end

local function read_attributes(str, i)
	local a = {}

	while i <= #str do
		local name, value
		name, i = read_name(str, i)
		i = skip_whitespace(str, i)
		if str:sub(i, i) ~= "=" then return end
		i = skip_whitespace(str, i + 1)
		value, i = read_string(str, i)
		a[name] = value

		i = skip_whitespace(str, i)
		local char = str:sub(i, i)
		if char == ">" or char == "/" then break end
	end

	return a, i
end

local function read_node_start(str, i)
	if str:sub(i, i) ~= "<" then return end

	i = skip_whitespace(str, i + 1)

	local name
	name, i = read_name(str, i)

	i = skip_whitespace(str, i)

	local attributes, single = nil, false

	while i <= #str do
		local char = str:sub(i, i)
		if char == "/" then
			i = i + 2
			single = true
			break
		elseif char == ">" then
			i = i + 1
			break
		else
			attributes, i = read_attributes(str, i)
		end
	end

	return {
		type = name,
		attributes = attributes
	}, i, single
end

local function read_node_end(str, i, name)
	if str:sub(i, i + 1) ~= "</" then return end


	i = skip_whitespace(str, i + 2)

	local end_name
	end_name, i = read_name(str, i)
	if name ~= end_name then return end

	i = skip_whitespace(str, i)
	return i + 1
end

local read_nodes

local function read_node(str, i)
	local node, single
	node, i, single = read_node_start(str, i)
	if not node then return end

	if not single then
		local start = i
		i = skip_whitespace(str, i)

		if str:sub(i, i) == "<" and str:sub(i + 1, i + 1) ~= "/" then
			node.inner, i = read_nodes(str, i)
		else
			local string_end = str:find("</", i)
			if string_end ~= i then
				node.inner = str:sub(start, string_end - 1)
				i = string_end
			end
		end

		i = read_node_end(str, i, node.type)
	end

	return node, i
end

function read_nodes(str, i)
	local inner = {}
	while i <= #str do
		if str:sub(i, i + 1) == "</" then
			break
		end

		local subnode
		subnode, i = read_node(str, i)
		table.insert(inner, subnode)
		inner[subnode.type] = subnode

		i = skip_whitespace(str, i)
	end
	return inner, i
end

local function read(file)
	---@type string
	local contents = love.filesystem.read(file)

	local i = skip_whitespace(contents, 1)

	if i > #contents then return end
	return read_nodes(contents, i)
end

return {
	read = read
}

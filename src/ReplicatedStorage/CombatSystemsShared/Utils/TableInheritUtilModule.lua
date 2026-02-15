local module = {}

local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then return value end

	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end

	return copy
end

local function deepMerge<T>(base: T, override: {}): T
	local result: T = deepCopy(base)

	for k, v in pairs(override) do
		if type(v) == "table" then
			local baseChild = base[k]
			if type(baseChild) == "table" then
				result[k] = deepMerge(baseChild, v)
			else
				result[k] = deepCopy(v)
			end
		else
			result[k] = v
		end
	end

	return result
end

-- configs: { mostSpecific, ..., mostGeneric }
function module.inheritConfig(configs: {}): {}
	assert(type(configs) == "table" and #configs > 0, "configs must be a non-empty array")

	local result: {} = deepCopy(configs[#configs])
	for i = #configs - 1, 1, -1 do
		local cfg = configs[i]
		if cfg ~= nil then
			assert(type(cfg) == "table", "Config at index " .. i .. " is not a table")
			result = deepMerge(result, cfg)
		end
	end

	return result
end

return module

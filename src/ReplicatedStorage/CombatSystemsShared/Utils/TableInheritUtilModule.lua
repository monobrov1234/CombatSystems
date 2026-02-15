--!strict

local module = {}

local function deepCopy(value: any): any
	if typeof(value) ~= "table" then return value end

	local copy: { [any]: any } = {}
	for k: any, v in pairs(value) do
		copy[k] = deepCopy(v)
	end

	return copy
end

local function deepMerge(base: any, override: { [any]: any }): any
	local result: any = deepCopy(base)

	for k: any, v in pairs(override) do
		if typeof(v) == "table" then
			local baseChild = base[k]
			if typeof(baseChild) == "table" then
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
function module.inheritConfig(configs: { { [any]: any } }): { [any]: any }
	assert(typeof(configs) == "table" and #configs > 0, "configs must be a non-empty array")

	local result: { [any]: any } = deepCopy(configs[#configs])
	for i = #configs - 1, 1, -1 do
		local cfg = configs[i]
		if cfg ~= nil then
			assert(typeof(cfg) == "table", "Config at index " .. tostring(i) .. " is not a table")
			result = deepMerge(result, cfg)
		end
	end

	return result
end

return module

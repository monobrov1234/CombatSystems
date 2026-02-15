-- by chatgpt
--!strict

local Logger = {}
Logger.__index = Logger

export type Level = "OFF" | "INFO" | "DEBUG" | "TRACE"
Logger.Level = "TRACE" :: Level

export type SelfObject = typeof(setmetatable({}, Logger)) & {
	name: string,
}

local function shouldLog(method: "INFO" | "DEBUG" | "TRACE"): boolean
	local lvl = Logger.Level
	if lvl == "OFF" then return false end
	if method == "TRACE" then return lvl == "TRACE" end
	if method == "DEBUG" then return lvl == "DEBUG" or lvl == "TRACE" end
	return lvl == "INFO" or lvl == "DEBUG" or lvl == "TRACE"
end

-- Tries to format the given value with a Lua string.format specifier.
-- Example spec: ".2f" => "%.2f"
-- If formatting fails (wrong type / invalid spec), falls back to tostring(value).
local function tryFormatWithSpec(value: any, spec: string): string
	-- spec is expected WITHOUT the leading "%", e.g. ".2f", "d", "s"
	local fmt = "%" .. spec

	-- Use pcall so invalid specs or wrong value types won't crash the logger.
	local ok, result = pcall(string.format, fmt, value)
	if ok then return result end
	return tostring(value)
end

-- Formats a template string by replacing placeholders with passed arguments.
-- Supported placeholders:
--   {}        -> tostring(arg)
--   {:...}    -> string.format("%" .. ..., arg)
-- Example:
--   formatTemplate("hp={:.2f} max={} name={}", 12.345, 100, "Car")
-- -> "hp=12.35 max=100 name=Car"
local function formatTemplate(template: string, ...: any): string
	-- Count how many arguments were passed.
	local argCount = select("#", ...)
	if argCount == 0 then
		-- No args => return template unchanged.
		return template
	end

	-- Pack varargs into a table so we can index them.
	local packedArgs = table.pack(...)

	-- We'll build the final string in parts, then concat once (fast & clean).
	local parts: { string } = {}

	-- Tracks which argument should be inserted next.
	local nextArgIndex = 1

	-- We'll scan the template character-by-character so we can support both {} and {:spec}.
	local i = 1
	local len = #template

	while i <= len do
		local ch = string.sub(template, i, i)

		if ch == "{" then
			-- Find the matching closing brace "}".
			local closeIndex = string.find(template, "}", i + 1, true)
			if closeIndex == nil then
				-- No closing brace => treat "{" as a normal character.
				parts[#parts + 1] = ch
				i += 1
				continue
			end

			-- Extract what's inside the braces, e.g. "" for {}, or ":.2f" for "{:.2f}"
			local inside = string.sub(template, i + 1, closeIndex - 1)

			-- Recognize supported placeholder types
			local isPlain = (inside == "") -- {}
			local isFormat = (string.sub(inside, 1, 1) == ":") -- {:...}

			-- If it's a recognized placeholder and we still have args to use
			if (isPlain or isFormat) and nextArgIndex <= argCount then
				local value = packedArgs[nextArgIndex]
				nextArgIndex += 1

				if isPlain then
					-- {} -> tostring
					parts[#parts + 1] = tostring(value)
				else
					-- {:spec} -> formatted string.format("%spec", value)
					local spec = string.sub(inside, 2) -- remove leading ':'
					if spec == "" then
						-- Edge case: "{:}" behaves like "{}"
						parts[#parts + 1] = tostring(value)
					else
						parts[#parts + 1] = tryFormatWithSpec(value, spec)
					end
				end

				-- Jump past the closing brace
				i = closeIndex + 1
				continue
			end

			-- If not recognized or out of args => keep placeholder unchanged
			parts[#parts + 1] = string.sub(template, i, closeIndex)
			i = closeIndex + 1
		else
			-- Regular character
			parts[#parts + 1] = ch
			i += 1
		end
	end

	-- If there are more args than placeholders, append them at the end.
	-- (Optional behavior; your original logger did this.)
	if nextArgIndex <= argCount then
		for idx = nextArgIndex, argCount do
			parts[#parts + 1] = " "
			parts[#parts + 1] = tostring(packedArgs[idx])
		end
	end

	return table.concat(parts)
end

local function emit(levelName: string, loggerName: string, message: string, useWarn: boolean)
	local line = string.format("[%s] [%s] %s", levelName, loggerName, message)
	if useWarn then
		warn(line)
	else
		print(line)
	end
end

function Logger.new(name: string): SelfObject
	local self = setmetatable({}, Logger) :: SelfObject
	self.name = name
	return self
end

function Logger:info(message: string, ...: any)
	local self = self :: SelfObject
	if not shouldLog("INFO") then return end
	emit("INFO", self.name, formatTemplate(message, ...), false)
end

function Logger:warn(message: string, ...: any)
	local self = self :: SelfObject
	if not shouldLog("INFO") then return end
	emit("WARN", self.name, formatTemplate(message, ...), true)
end

function Logger:error(message: string, ...: any)
	local self = self :: SelfObject
	if not shouldLog("INFO") then return end
	emit("ERROR", self.name, formatTemplate(message, ...), true)
end

function Logger:debug(message: string, ...: any)
	local self = self :: SelfObject
	if not shouldLog("DEBUG") then return end
	emit("DEBUG", self.name, formatTemplate(message, ...), false)
end

function Logger:trace(message: string, ...: any)
	local self = self :: SelfObject
	if not shouldLog("TRACE") then return end
	emit("TRACE", self.name, formatTemplate(message, ...), false)
end

return Logger

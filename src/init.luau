local animations = require("@self/animations")
local process = require("@lune/process")
local stdio = require("@lune/stdio")
local task = require("@lune/task")

local write = stdio.write
local spawn = task.spawn
local wait = task.wait

local IS_CI = process.env.CI ~= nil
local CLEAR_LINE = "\x1b[2K\r"

type spinner = {
	frames: { string },
	-- in milliseconds
	interval: number,
}

type Renderer = {
	animation: spinner,
	formatter: ((frame: string, text: string) -> string)?,
}

-- used to convert intervals
local function msToSeconds(ms: number)
	return ms / 1000
end

local spin = {}
spin.animations = animations

-- Creates a reusable renderer with optional custom formatter
function spin.render(animation: spinner, formatter: ((frame: string, text: string) -> string)?): Renderer
	return {
		animation = animation,
		formatter = formatter,
	}
end

-- Starts a spinner with manual control, returns (setText, stop)
function spin.start(renderer: Renderer | spinner, initialText: string?, ci: boolean?): ((text: string) -> (), () -> ())
	local animation: spinner
	local formatter: ((frame: string, text: string) -> string)?

	-- Handle both renderer object and raw animation
	if type(renderer) == "table" and (renderer :: any).frames then
		animation = renderer :: spinner
		formatter = nil
	else
		local r = renderer :: Renderer
		animation = r.animation
		formatter = r.formatter
	end

	local currentText = initialText or ""
	local currentFrame = animation.frames[1]
	local running = true
	local interval = msToSeconds(animation.interval)
	local inCI = ci or IS_CI

	-- Default formatter
	local finalFormatter = formatter or function(frame: string, text: string)
		return frame .. " " .. text
	end

	-- Shared render function
	local function render()
		if not inCI then
			local output = finalFormatter(currentFrame, currentText)
			write(CLEAR_LINE .. output)
		end
	end

	-- setText function - now updates immediately
	local function setText(newText: string)
		currentText = newText

		-- In CI, just print the update
		if inCI then
			print(newText)
		else
			-- Immediately update the terminal
			render()
		end
	end

	-- stop function
	local function stop()
		if not running then
			return
		end

		running = false

		-- Clear the line unless in CI
		if not inCI then
			write(CLEAR_LINE)
		end
	end

	-- Don't animate in CI
	if not inCI then
		-- Render initial state
		render()

		spawn(function()
			local frameIndex = 1
			while running do
				if not running then
					break
				end

				currentFrame = animation.frames[frameIndex]
				render()

				wait(interval)

				if not running then
					break
				end

				-- Advance to next frame
				frameIndex = frameIndex % #animation.frames + 1
			end
			if not inCI then
				write(CLEAR_LINE)
			end
		end)
	end

	return setText, stop
end

-- Auto-managed wrapper that starts spinner, runs callback, then stops
function spin.wrap<R...>(renderer: Renderer | spinner, callback: (setText: (text: string) -> ()) -> R..., ci: boolean?): R...
	local setText, stop = spin.start(renderer, "", ci)

	local success, result = pcall(function()
		return { callback(setText) }
	end)

	stop()

	if not success then
		error(result)
	end

	return table.unpack(result) :: any
end

return spin

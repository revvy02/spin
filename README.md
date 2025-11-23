# spin

Terminal spinners for the [Lune](https://lune-org.github.io/docs/) Runtime with dynamic text updates and CI support.

## Features

- **Dynamic text updates** - Change spinner text while running
- **CI-aware** - Automatically detects CI environments and adapts output
- **Custom formatters** - Style your spinner output however you want
- **89 pre-built animations** - From minimal dots to elaborate emoji sequences
- **Type-safe** - Full Luau type definitions included

## Installation

```bash
pesde add revvy02/spin
```

## Quick Start

```luau
local spin = require('@pkg/spin')

-- Simple: auto-managed with callback
spin.wrap(spin.animations.dots, function(setText)
    setText("Loading...")
    task.wait(1)
    setText("Almost done...")
    task.wait(1)
end)
print("Complete!")
```

## API Reference

### `spin.animations`

Table of 89 pre-built animations. Default is `animations.line`.

**Examples:** `dots`, `line`, `arc`, `arrow`, `circle`, `bounce`, `earth`, `moon`, `hearts`

### `spin.render(animation, formatter?)`

Creates a reusable renderer with optional custom formatting.

**Parameters:**
- `animation: spinner` - The spinner animation to use
- `formatter?: (frame: string, text: string) -> string` - Custom output formatter

**Returns:** `Renderer`

**Example:**
```luau
local renderer = spin.render(spin.animations.dots, function(frame, text)
    return "[" .. frame .. "] " .. text
end)
```

### `spin.start(renderer, initialText?, ci?)`

Starts a spinner with manual control. Returns functions to update text and stop.

**Parameters:**
- `renderer: Renderer | spinner` - Renderer object or raw animation
- `initialText?: string` - Initial text to display
- `ci?: boolean` - Override CI detection (defaults to `process.env.CI`)

**Returns:** `(setText, stop)` where:
- `setText: (text: string) -> ()` - Update the displayed text
- `stop: () -> ()` - Stop and clear the spinner

**Example:**
```luau
local setText, stop = spin.start(spin.animations.dots, "Starting...")

task.wait(1)
setText("Loading...")
task.wait(1)
setText("Processing...")
task.wait(1)

stop()
```

### `spin.wrap(renderer, callback, ci?)`

Auto-managed spinner that runs a callback with text control, then automatically stops.

**Parameters:**
- `renderer: Renderer | spinner` - Renderer object or raw animation
- `callback: (setText: (text: string) -> ()) -> R...` - Function that receives `setText`
- `ci?: boolean` - Override CI detection

**Returns:** All values returned by the callback

**Example:**
```luau
local result = spin.wrap(spin.animations.arc, function(setText)
    setText("Step 1/3")
    task.wait(0.5)
    setText("Step 2/3")
    task.wait(0.5)
    setText("Step 3/3")
    task.wait(0.5)
    return "Done!"
end)

print(result) -- "Done!"
```

## Usage Examples

### Basic Usage

```luau
local spin = require('@pkg/spin')

-- Simplest form: just show a spinner during work
spin.wrap(spin.animations.dots, function(setText)
    setText("Working...")
    -- do your work here
    task.wait(2)
end)
```

### Multi-Step Process

```luau
local spin = require('@pkg/spin')

spin.wrap(spin.animations.dots, function(setText)
    setText("Downloading dependencies...")
    -- download code
    task.wait(1)

    setText("Installing packages...")
    -- install code
    task.wait(1)

    setText("Building project...")
    -- build code
    task.wait(1)
end)

print("Build complete!")
```

### Manual Control

```luau
local spin = require('@pkg/spin')

local setText, stop = spin.start(spin.animations.line)

-- Update text dynamically as your code runs
for i = 1, 10 do
    setText(`Processing item {i}/10...`)
    -- process item
    task.wait(0.5)
end

stop()
print("All items processed!")
```

### Custom Formatter

```luau
local spin = require('@pkg/spin')

local renderer = spin.render(spin.animations.dots, function(frame, text)
    return `[{frame}] {text} [{os.clock()}s]`
end)

spin.wrap(renderer, function(setText)
    setText("Running...")
    task.wait(2)
end)
```

### With Return Values

```luau
local spin = require('@pkg/spin')

local data = spin.wrap(spin.animations.arc, function(setText)
    setText("Fetching data...")
    task.wait(1)

    return { users = 42, active = 17 }
end)

print(`Found {data.users} users, {data.active} active`)
```

### Error Handling

```luau
local spin = require('@pkg/spin')

local success, result = pcall(function()
    return spin.wrap(spin.animations.dots, function(setText)
        setText("Attempting operation...")

        if math.random() > 0.5 then
            error("Something went wrong!")
        end

        return "Success!"
    end)
end)

if success then
    print("Result:", result)
else
    print("Error:", result)
end
```

### Custom Animation

```luau
local spin = require('@pkg/spin')

local customSpinner = {
    interval = 100, -- milliseconds
    frames = { "▹▹▹▹▹", "▸▹▹▹▹", "▸▸▹▹▹", "▸▸▸▹▹", "▸▸▸▸▹", "▸▸▸▸▸" }
}

spin.wrap(customSpinner, function(setText)
    setText("Loading with custom animation...")
    task.wait(2)
end)
```

## Available Animations

The library includes **89 pre-built animations** from [cli-spinners](https://github.com/sindresorhus/cli-spinners).

**Character-based:**
`dots`, `dots2`, `dots3`, `line`, `line2`, `arc`, `arrow`, `circle`, `circleQuarters`, `circleHalves`, `squareCorners`, `triangle`, `bounce`, `bouncingBar`, `bouncingBall`, `toggle`, `star`, `star2`, `flip`, `hamburger`, `growVertical`, `growHorizontal`, `pipe`, `simpleDots`, `simpleDotsScrolling`, `aesthetic`, `dwarfFortress`, `material`, and many more

**Emoji-based:**
`earth`, `moon`, `runner`, `pong`, `shark`, `hearts`, `clock`, `monkey`, `smiley`, `christmas`, `grenade`, `point`, `layer`

**Default:** `spin.animations.line`

## Types

```luau
type spinner = {
    frames: { string },   -- Array of animation frames
    interval: number,     -- Frame duration in milliseconds
}

type Renderer = {
    animation: spinner,
    formatter: ((frame: string, text: string) -> string)?,
}
```

## CI/CD Support

The `start()` and `wrap()` functions automatically detect CI environments by checking `process.env.CI`:

- **In CI mode:** Animations are disabled, only text updates are printed
- **In terminal mode:** Full animations are shown
- **Override:** Pass `ci` parameter to force a specific mode

```luau
-- Force CI mode even in terminal
spin.wrap(spin.animations.dots, function(setText)
    setText("Running tests...")
end, true)
```

## How It Works

This library uses ANSI escape sequences (`\x1b[2K\r`) to clear and rewrite the current line. This approach:
- Works reliably across all modern terminals
- Handles Unicode/emoji correctly
- Resistant to cursor position changes
- Properly cleans up on completion

## Contributing

Issues and pull requests are welcome! Terminal tools can be tricky, so any improvements to compatibility or features are appreciated.

## Credits

All default animations adapted from [cli-spinners](https://github.com/sindresorhus/cli-spinners) by Sindre Sorhus.

## License

MIT

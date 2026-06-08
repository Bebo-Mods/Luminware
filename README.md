# Luminware

Luminware is a reusable Roblox UI library with Fluent-style presentation, Linoria-style state and API reliability, and the original frosted home-control concept as its only visual shell.

## Architecture

- Registry-driven themes update every live registered component.
- Options own their values, setters, callbacks, visibility, disabled state, and serialization.
- Popups are bounded, window-owned, correctly layered, and closed during navigation/lifecycle changes.
- Cards and columns use measured automatic layouts with bounded scrolling.
- Every connection, popup, window, blur effect, and callback has explicit cleanup ownership.
- Windows drag from empty header space with mouse or touch and remain clamped to the viewport.

## Features

- Concept navigation rail, header subtabs, search, profile, and glass cards
- Fluent-style tabs and sections
- Linoria-style left/right groupboxes, tabboxes, labels, dividers, chained buttons, and dependency boxes
- Toggles, sliders, single/multi dropdowns, inputs, keybinds, and full HSV color pickers
- Dialogs, notifications, watermark, themes, acrylic, configs, autoload, and interface settings
- `Library.Options`, `Library.Toggles`, `OnChanged`, `OnClick`, `SetValue`, `SetVisible`, and `SetDisabled`

## Load

```lua
local Library=loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/Library.lua"
))()

local Window=Library:CreateWindow({
    Size=UDim2.fromOffset(900,600),
    Acrylic=true,
})

local Home=Window:AddTab({Title="Home",IconText="S"})
local Main=Home:AddSubtab("Subtab 1")
local Controls=Main.Right:AddCard("Controls")

Controls:AddToggle("Enabled",{Text="Toggle",Default=true})
Controls:AddSlider("Amount",{Text="Slider",Min=0,Max=100,Default=50,Rounding=0})
```

See [`Example.lua`](Example.lua) for the complete showcase covering controls, layouts, state APIs, dependencies, feedback, themes, configs, and lifecycle features.

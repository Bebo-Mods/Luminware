# Luminware Concept Library

Luminware is a reusable Roblox UI library built directly from the original frosted home-control concept.

There is no legacy dashboard shell. Every window uses:

- A floating rounded glass panel
- An inset rounded navigation rail
- Header subtabs with an underline
- Search and player profile controls
- Soft translucent rounded cards
- The original muted gray palette and blue accent

## Features

- Tabs, subtabs, sections, cards, and two-column layouts
- Paragraphs, buttons, toggles, sliders, dropdowns, multi dropdowns
- Inputs, keybinds, and color pickers
- Dialogs, notifications, search, acrylic blur, and transparency controls
- Global options, configuration saving, themes, and interface settings
- Fluent-style method names for easier migration

## Load

```lua
local Luminware=loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/Library.lua"
))()

local Window=Luminware:CreateWindow({
    Size=UDim2.fromOffset(900,600),
    Acrylic=true,
})

local Home=Window:AddTab({Title="Home",IconText="S"})
local Main=Home:AddSubtab("Subtab 1")
local Controls=Main.Right:AddCard("Controls")

Controls:AddToggle("Enabled",{Title="Toggle",Default=true})
Controls:AddSlider("Amount",{Title="Slider",Min=0,Max=100,Default=50})
```

See [`Example.lua`](Example.lua) for the full feature set.

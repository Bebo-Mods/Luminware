# Luminware

Luminware is a Roblox UI library built around a compact frosted home-control design.

It provides a Fluent-style public API while also supporting concept-specific subtabs, left/right panes, and cards.

`HomeControl.lua` remains the pixel-focused concept demo. `Library.lua` turns that visual language into a reusable API.

## Features

- Acrylic windows, draggable UI, minimize and unload controls
- Tabs, subtabs, sections, cards, and two-column layouts
- Paragraphs, buttons, toggles, sliders, dropdowns, multi dropdowns, inputs, keybinds, and color pickers
- Dialogs, notifications, themes, global option state, config saving, and interface settings
- Mouse, touch, and gamepad-friendly `Activated` click handling

## Load

```lua
local Luminware=loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/Library.lua"
))()

local Window=Luminware:CreateWindow({
    Title="My Script",
    Size=UDim2.fromOffset(900,560),
    Acrylic=true,
    Theme="FROST",
})

local Main=Window:AddTab({Name="Main"})
local Controls=Main:AddSection("Controls")

Controls:AddToggle("Enabled",{Title="Enabled",Default=true})
Controls:AddSlider("Amount",{Title="Amount",Min=0,Max=100,Default=50})
```

See [`Example.lua`](Example.lua) for every major feature and both supported layout styles.

## Layout APIs

Fluent-style:

```lua
local Tab=Window:AddTab({Name="Features"})
local Section=Tab:AddSection("Controls")
Section:AddToggle("Enabled",{Title="Enabled"})
```

Home-control style:

```lua
local Tab=Window:AddTab({Name="Home"})
local Subtab=Tab:AddSubtab("Subtab 1")
local Card=Subtab.Left:AddCard("Things")
Card:AddToggle("Thing1",{Title="Thing 1"})
```

The library stores controls in `Luminware.Options` and toggles in `Luminware.Toggles`.

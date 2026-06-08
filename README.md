# Luminware Home Control

Luminware is a compact frosted home-control dashboard modeled after the supplied reference.

## Home Control

Execute `HomeControl.lua` directly. It supports Roblox Studio `LocalScript` usage and executor environments with `gethui()`.

Controls report changes through one optional callback:

```lua
getgenv().HomeControlCallbacks = {
    OnChanged = function(name, value)
        print(name, value)
    end,
}

loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/HomeControl.lua"
))()
```

Set `BACKGROUND_IMAGE` near the top of `HomeControl.lua` to an uploaded `rbxassetid://...` image when a fixed room backdrop is desired. When left empty, the live game world remains visible behind the frosted panel.

## Compatibility

All clickable controls use `GuiButton.Activated`, which works across mouse, touch, and gamepad input.

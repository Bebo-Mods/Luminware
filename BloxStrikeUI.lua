--[[
    BloxStrike UI-only Luminware port

    This file ports the original menu structure and control coverage to
    Luminware. Controls update local preview state only. It intentionally
    contains no game hooks, remote calls, executor checks, or gameplay mods.
]]

local baseUrl = "https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/"

local Library = loadstring(game:HttpGet(baseUrl .. "Library.lua"))()
local Icons = loadstring(game:HttpGet(baseUrl .. "Icons.lua"))()
local SaveManager = loadstring(game:HttpGet(baseUrl .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(baseUrl .. "addons/ThemeManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(baseUrl .. "addons/InterfaceManager.lua"))()

Library:SetIcons(Icons)

local environment = typeof(getgenv) == "function" and getgenv() or {}
local mobileMode = environment.LuminwareMobileMode
if mobileMode == nil then
    mobileMode = game:GetService("UserInputService").TouchEnabled
end

local State = {
    AimPreview = false,
    TeamCheck = true,
    WallCheck = false,
    HitPart = "Head",
    HitChance = 100,
    FOVEnabled = true,
    FOVSize = 150,
    FOVThickness = 2,
    FOVFilled = false,
    FOVColor = Color3.fromRGB(180, 0, 255),
    ESPPreview = false,
    TeamESPPreview = false,
    BoxType = "2D",
    BoxColor = Color3.fromRGB(180, 0, 255),
    Tracers = false,
    Skeleton = false,
    Names = true,
    Health = true,
    Weapon = true,
    Distance = true,
    Crosshair = true,
    CrosshairColor = Color3.fromRGB(180, 0, 255),
    BulletTracerPreview = false,
    HitMarkerPreview = false,
    MovementPreview = false,
    SkinPreview = false,
}

local Loader = Library:CreateLoader({
    Title = "BloxStrike",
    Subtitle = "Building Luminware interface",
    MinimumDuration = 2.5,
})

Loader:SetProgress(0.15, "Creating window")

local Window = Library:CreateWindow({
    Size = UDim2.fromOffset(980, 650),
    MobileSize = UDim2.fromOffset(820, 520),
    MobileMode = mobileMode,
    Acrylic = true,
    SmallIcon = true,
    Visible = false,
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home" }),
    Aim = Window:AddTab({ Title = "Aim" }),
    Visuals = Window:AddTab({ Title = "Visuals" }),
    TeamVisuals = Window:AddTab({ Title = "Team Visuals", Icon = Icons.Visuals }),
    BulletFX = Window:AddTab({ Title = "Bullet FX", Icon = Icons.Misc }),
    Weapons = Window:AddTab({ Title = "Weapons", Icon = Icons.Controls }),
    Movement = Window:AddTab({ Title = "Movement" }),
    Skins = Window:AddTab({ Title = "Skins", Icon = Icons.Layouts }),
    Debug = Window:AddTab({ Title = "Debug", Icon = Icons.State }),
    Settings = Window:AddTab({ Title = "Settings", Settings = true }),
}

Loader:SetProgress(0.35, "Building controls")

local function bindToggle(card, index, title, key, default)
    return card:AddToggle(index, {
        Text = title,
        Default = default,
        Callback = function(value)
            State[key] = value
        end,
    })
end

local function bindSlider(card, index, title, key, minimum, maximum, default, suffix)
    return card:AddSlider(index, {
        Text = title,
        Min = minimum,
        Max = maximum,
        Default = default,
        Rounding = 0,
        Suffix = suffix,
        Callback = function(value)
            State[key] = value
        end,
    })
end

local function bindColor(card, index, title, key, default)
    card:AddLabel(title):AddColorPicker(index, {
        Default = default,
        Callback = function(value)
            State[key] = value
        end,
    })
end

-- Home ------------------------------------------------------------------------

local Dashboard = Tabs.Home:AddSubtab("Dashboard")
local Session = Dashboard.Left:AddCard("Session")
local SessionInfo = Library:GetSessionInfo()

Session:AddStat("Player", SessionInfo.DisplayName)
Session:AddStat("Username", "@" .. SessionInfo.Username)
Session:AddStat("Executor", SessionInfo.Executor)
Session:AddStat("Experience", SessionInfo.Experience, true)
Session:AddStat("Players", ("%d / %d"):format(SessionInfo.Players, SessionInfo.MaxPlayers))

local Status = Dashboard.Right:AddCard("Interface status")
Status:AddParagraph({
    Title = "UI-only port",
    Content = "This showcase mirrors the original menu organization while all controls only update local preview state.",
})
Status:AddStat("Library", "Luminware " .. Library.Version)
Status:AddStat("Input", SessionInfo.Device)
Status:AddStat("Mobile mode", tostring(mobileMode))
Status:AddButton({
    Title = "Inspect local state",
    Action = "Print",
    Callback = function()
        for key, value in pairs(State) do
            print("[BloxStrike UI]", key, value)
        end
    end,
})

-- Aim -------------------------------------------------------------------------

local AimMain = Tabs.Aim:AddSubtab("Main")
local AimControls = AimMain.Left:AddCard("Aim preview")
bindToggle(AimControls, "AimPreview", "Enabled", "AimPreview", false)
bindToggle(AimControls, "AimTeamCheck", "Team check", "TeamCheck", true)
bindToggle(AimControls, "AimWallCheck", "Wall check", "WallCheck", false)
bindSlider(AimControls, "AimHitChance", "Hit chance", "HitChance", 1, 100, 100, "%")
AimControls:AddDropdown("AimHitPart", {
    Text = "Hit part",
    Values = { "Head", "UpperTorso", "HumanoidRootPart", "Random" },
    Default = "Head",
    Callback = function(value)
        State.HitPart = value
    end,
})

local FOV = AimMain.Right:AddCard("FOV preview")
bindToggle(FOV, "FOVEnabled", "Show FOV", "FOVEnabled", true)
bindSlider(FOV, "FOVSize", "Radius", "FOVSize", 20, 500, 150)
bindSlider(FOV, "FOVThickness", "Thickness", "FOVThickness", 1, 6, 2)
bindToggle(FOV, "FOVFilled", "Filled", "FOVFilled", false)
bindColor(FOV, "FOVColor", "FOV color", "FOVColor", State.FOVColor)

local Crosshair = AimMain.Right:AddCard("Crosshair preview")
bindToggle(Crosshair, "CrosshairEnabled", "Enabled", "Crosshair", true)
bindSlider(Crosshair, "CrosshairSize", "Size", "CrosshairSize", 5, 60, 20)
bindSlider(Crosshair, "CrosshairGap", "Gap", "CrosshairGap", 0, 100, 30, "%")
bindColor(Crosshair, "CrosshairColor", "Color", "CrosshairColor", State.CrosshairColor)

-- Visuals ---------------------------------------------------------------------

local PlayerESP = Tabs.Visuals:AddSubtab("Player ESP")
local ESPMain = PlayerESP.Left:AddCard("Player overlay preview")
bindToggle(ESPMain, "ESPPreview", "Enabled", "ESPPreview", false)
bindToggle(ESPMain, "ESPNames", "Names", "Names", true)
bindToggle(ESPMain, "ESPHealth", "Health", "Health", true)
bindToggle(ESPMain, "ESPWeapon", "Weapon", "Weapon", true)
bindToggle(ESPMain, "ESPDistance", "Distance", "Distance", true)

local ESPStyle = PlayerESP.Right:AddCard("Style")
ESPStyle:AddDropdown("ESPBoxType", {
    Text = "Box type",
    Values = { "2D", "Corner", "3D" },
    Default = "2D",
    Callback = function(value)
        State.BoxType = value
    end,
})
bindSlider(ESPStyle, "ESPBoxThickness", "Box thickness", "BoxThickness", 1, 5, 1)
bindColor(ESPStyle, "ESPBoxColor", "Box color", "BoxColor", State.BoxColor)
bindToggle(ESPStyle, "ESPTracers", "Tracers", "Tracers", false)
bindToggle(ESPStyle, "ESPSkeleton", "Skeleton", "Skeleton", false)

local TeamMain = Tabs.TeamVisuals:AddSubtab("Team")
local TeamCard = TeamMain.Left:AddCard("Team overlay preview")
bindToggle(TeamCard, "TeamESPPreview", "Enabled", "TeamESPPreview", false)
bindToggle(TeamCard, "TeamNames", "Names", "TeamNames", true)
bindToggle(TeamCard, "TeamHealth", "Health", "TeamHealth", true)
bindToggle(TeamCard, "TeamTracers", "Tracers", "TeamTracers", false)
bindColor(TeamCard, "TeamColor", "Team color", "TeamColor", Color3.fromRGB(0, 255, 100))

-- Bullet FX -------------------------------------------------------------------

local BulletMain = Tabs.BulletFX:AddSubtab("Effects")
local HitEffects = BulletMain.Left:AddCard("Hit feedback preview")
bindToggle(HitEffects, "HitSoundPreview", "Hit sound", "HitSoundPreview", false)
bindSlider(HitEffects, "HitSoundVolume", "Volume", "HitSoundVolume", 0, 100, 50, "%")
bindToggle(HitEffects, "HitMarkerPreview", "Hit marker", "HitMarkerPreview", false)
bindSlider(HitEffects, "HitMarkerSize", "Marker size", "HitMarkerSize", 3, 30, 10)
bindColor(HitEffects, "HitMarkerColor", "Marker color", "HitMarkerColor", Color3.new(1, 1, 1))

local TracerEffects = BulletMain.Right:AddCard("Tracer preview")
bindToggle(TracerEffects, "BulletTracerPreview", "Bullet tracer", "BulletTracerPreview", false)
TracerEffects:AddDropdown("TracerOrigin", {
    Text = "Origin",
    Values = { "Muzzle", "Top", "Bottom", "Center" },
    Default = "Muzzle",
    Callback = function(value)
        State.TracerOrigin = value
    end,
})
bindSlider(TracerEffects, "TracerWidth", "Width", "TracerWidth", 1, 20, 2)
bindSlider(TracerEffects, "TracerLifetime", "Lifetime", "TracerLifetime", 1, 20, 3)
bindColor(TracerEffects, "TracerColor", "Color", "TracerColor", Color3.fromRGB(180, 0, 255))

-- Weapons and Movement ---------------------------------------------------------

local WeaponMain = Tabs.Weapons:AddSubtab("Preview")
local WeaponCard = WeaponMain.Left:AddCard("Weapon settings preview")
bindToggle(WeaponCard, "WeaponRecoilPreview", "Recoil option", "WeaponRecoilPreview", false)
bindToggle(WeaponCard, "WeaponSpreadPreview", "Spread option", "WeaponSpreadPreview", false)
bindToggle(WeaponCard, "WeaponReloadPreview", "Reload option", "WeaponReloadPreview", false)
bindSlider(WeaponCard, "WeaponRatePreview", "Rate value", "WeaponRatePreview", 1, 30, 10)
WeaponCard:AddParagraph({
    Title = "Preview controls",
    Content = "These controls demonstrate the intended menu layout and do not modify weapons.",
})

local MoveMain = Tabs.Movement:AddSubtab("Movement")
local MoveCard = MoveMain.Left:AddCard("Movement preview")
bindToggle(MoveCard, "MovementPreview", "Enable preview", "MovementPreview", false)
bindToggle(MoveCard, "MovementJumpPreview", "Jump option", "MovementJumpPreview", false)
bindToggle(MoveCard, "MovementCollisionPreview", "Collision option", "MovementCollisionPreview", false)
bindSlider(MoveCard, "MovementSpeedPreview", "Speed value", "MovementSpeedPreview", 1, 100, 24)

local WorldCard = MoveMain.Right:AddCard("World appearance")
bindToggle(WorldCard, "SkyTintPreview", "Sky tint preview", "SkyTintPreview", false)
bindSlider(WorldCard, "BrightnessPreview", "Brightness", "BrightnessPreview", 0, 10, 2)
bindColor(WorldCard, "SkyColorPreview", "Sky color", "SkyColorPreview", Color3.fromRGB(100, 150, 255))

-- Skins and Debug --------------------------------------------------------------

local SkinMain = Tabs.Skins:AddSubtab("Selection")
local SkinCard = SkinMain.Left:AddCard("Skin selection preview")
bindToggle(SkinCard, "SkinPreview", "Enable preview", "SkinPreview", false)
SkinCard:AddDropdown("SkinWeapon", {
    Text = "Weapon",
    Values = { "AK-47", "M4A4", "AWP", "Karambit", "Butterfly Knife" },
    Default = "AK-47",
    Callback = function(value)
        State.SkinWeapon = value
    end,
})
SkinCard:AddDropdown("SkinWear", {
    Text = "Wear",
    Values = { "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred" },
    Default = "Factory New",
    Callback = function(value)
        State.SkinWear = value
    end,
})

local DebugMain = Tabs.Debug:AddSubtab("Diagnostics")
local DebugCard = DebugMain.Left:AddCard("Diagnostics")
DebugCard:AddButton("Print state", function()
    for key, value in pairs(State) do
        print("[BloxStrike UI]", key, value)
    end
end)
DebugCard:AddButton("Reset preview state", function()
    Library:Notify({
        Title = "BloxStrike",
        Content = "Reload the UI to reset all preview controls.",
        Duration = 4,
    })
end)
DebugCard:AddStat("Executor", SessionInfo.Executor)
DebugCard:AddStat("Device", SessionInfo.Device)
DebugCard:AddStat("Locale", SessionInfo.Locale)

-- Settings --------------------------------------------------------------------

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("BloxStrike/configs")
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("BloxStrike")
ThemeManager:BuildSection(Tabs.Settings)

InterfaceManager:SetLibrary(Library)
InterfaceManager:SetFolder("BloxStrike")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Loader:SetProgress(0.9, "Applying interface settings")
Window:SelectTab("Home")

Library:SetWatermark("BloxStrike UI")
Library:SetWatermarkVisibility(true)

Loader:Complete("Interface ready", function()
    Window:SetVisible(true)
    Library:Notify({
        Title = "BloxStrike UI",
        Content = "Luminware UI-only port loaded.",
        Duration = 5,
    })
end)

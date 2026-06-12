--[[
    Luminware Complete Example

    This is a readable reference implementation showing:
    - Recommended loading and startup flow
    - Live Home dashboard
    - Every common control
    - Layouts, dependencies, and state APIs
    - Visual-only overlay previews
    - Config, theme, and interface addons
]]

-- Dependencies -----------------------------------------------------------------

local baseUrl = "https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/"

local Library = loadstring(game:HttpGet(baseUrl .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(baseUrl .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(baseUrl .. "addons/ThemeManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(baseUrl .. "addons/InterfaceManager.lua"))()

-- Boot Configuration -----------------------------------------------------------

-- These globals may be set before loading this example.
local environment = typeof(getgenv) == "function" and getgenv() or {}

local bootMobileMode = environment.LuminwareMobileMode
if bootMobileMode == nil then
    bootMobileMode = game:GetService("UserInputService").TouchEnabled
end

local bootSmallIcon = environment.LuminwareSmallIcon ~= false

-- Startup Loader ---------------------------------------------------------------

-- The window remains hidden until the loader fully finishes.
local Loader = Library:CreateLoader({
    Title = "Luminware",
    Subtitle = "Preparing interface",
    MinimumDuration = 3,
})

Loader:SetProgress(0.12, "Creating responsive window")
task.wait(0.1)

-- Window and Navigation --------------------------------------------------------

local Window = Library:CreateWindow({
    Size = UDim2.fromOffset(900, 600),
    Acrylic = true,
    MobileMode = bootMobileMode,
    SmallIcon = bootSmallIcon,
    Visible = false,
})

local Tabs = {
    Home = Window:AddTab({ Title = "Home" }),
    Aim = Window:AddTab({ Title = "Aim" }),
    Movement = Window:AddTab({ Title = "Movement" }),
    Misc = Window:AddTab({ Title = "Misc" }),
    Farms = Window:AddTab({ Title = "Farms" }),
    Settings = Window:AddTab({
        Title = "Settings",
        Settings = true,
    }),
}

Loader:SetProgress(0.32, "Building dashboard and controls")
task.wait(0.08)

-- Home Dashboard ---------------------------------------------------------------

local Dashboard = Tabs.Home:AddSubtab("Dashboard")

local Identity = Dashboard.Left:AddCard("Identity")
local PlayerName = Identity:AddStat("Display name", "")
local Username = Identity:AddStat("Username", "")
local UserId = Identity:AddStat("User ID", "")
local AccountAge = Identity:AddStat("Account age", "")
local Membership = Identity:AddStat("Membership", "")
local Team = Identity:AddStat("Team", "")
local Health = Identity:AddStat("Health", "")

local Access = Dashboard.Left:AddCard("Access")
local PlayerExecutor = Access:AddStat("Executor", "")
local Subscription = Access:AddStat("Subscription", "")
local SubscriptionLife = Access:AddStat("Time remaining", "")

local Performance = Dashboard.Right:AddCard("Performance")
local FPS = Performance:AddStat("Client FPS", "")
local Ping = Performance:AddStat("Network ping", "")
local InputDevice = Performance:AddStat("Input device", "")
local Locale = Performance:AddStat("Locale", "")

local Server = Dashboard.Right:AddCard("Server")
local Experience = Server:AddStat("Experience", "", true)
local ServerPopulation = Server:AddStat("Players", "")
local Uptime = Server:AddStat("Uptime", "")
local PlaceId = Server:AddStat("Place ID", "")
local JobId = Server:AddStat("Job ID", "", true)

local function formatDuration(seconds)
    return ("%02d:%02d:%02d"):format(
        math.floor(seconds / 3600),
        math.floor(seconds / 60) % 60,
        seconds % 60
    )
end

local function refreshDashboard()
    local info = Library:GetSessionInfo()

    PlayerName:SetValue(info.DisplayName)
    Username:SetValue("@" .. info.Username)
    UserId:SetValue(info.UserId)
    AccountAge:SetValue(info.AccountAge .. " days")
    Membership:SetValue(info.Membership)
    Team:SetValue(info.Team)
    Health:SetValue(("%d / %d"):format(info.Health, info.MaxHealth))

    PlayerExecutor:SetValue(info.Executor)
    Subscription:SetValue(info.Subscription)
    SubscriptionLife:SetValue(info.SubscriptionLife)

    FPS:SetValue(info.FPS)
    Ping:SetValue(info.Ping .. " ms")
    InputDevice:SetValue(info.Device)
    Locale:SetValue(info.Locale)

    Experience:SetValue(info.Experience)
    ServerPopulation:SetValue(("%d / %d"):format(info.Players, info.MaxPlayers))
    Uptime:SetValue(formatDuration(info.ServerUptime))
    PlaceId:SetValue(info.PlaceId)
    JobId:SetValue(info.JobId ~= "" and info.JobId or "Studio / unavailable")
end

refreshDashboard()

task.spawn(function()
    while not Library.Unloaded and Window.Root.Parent do
        refreshDashboard()
        task.wait(1)
    end
end)

-- Aim Tab: Controls ------------------------------------------------------------

local BasicControls = Tabs.Aim:AddLeftGroupbox("Basic controls")

BasicControls:AddLabel("Labels can be short.")
BasicControls:AddLabel(
    "Labels can also wrap across multiple lines when the second argument is true.",
    true
)
BasicControls:AddDivider()

BasicControls:AddToggle("DemoToggle", {
    Text = "Toggle",
    Default = true,
    Tooltip = "Every option owns its state.",
})

BasicControls:AddSlider("DemoSlider", {
    Text = "Slider",
    Min = -10,
    Max = 10,
    Default = 2.5,
    Rounding = 1,
    Suffix = "x",
})

BasicControls:AddButton({
    Text = "Single-click button",
    Action = "Run",
    Func = function()
        Library:Notify({
            Title = "Button",
            Content = "Single-click callback fired.",
        })
    end,
})

BasicControls:AddButton({
    Text = "Double-click button",
    Action = "Run",
    DoubleClick = true,
    Func = function()
        Library:Notify({
            Title = "Button",
            Content = "Double-click callback fired.",
        })
    end,
})

local Inputs = Tabs.Aim:AddRightGroupbox("Inputs and selection")

Inputs:AddDropdown("SingleDropdown", {
    Text = "Dropdown",
    Values = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" },
    Default = 1,
})

Inputs:AddDropdown("MultiDropdown", {
    Text = "Multi dropdown",
    Values = { "One", "Two", "Three", "Four" },
    Multi = true,
    Default = { "One", "Three" },
})

Inputs:AddDropdown("PlayerDropdown", {
    Text = "Player dropdown",
    SpecialType = "Player",
    AllowNull = true,
})

Inputs:AddInput("TextInput", {
    Text = "Text input",
    Placeholder = "Type here",
    MaxLength = 32,
})

Inputs:AddInput("NumericInput", {
    Text = "Numeric input",
    Placeholder = "123",
    Numeric = true,
})

Inputs:AddLabel("Keybind"):AddKeyPicker("Key", {
    Text = "Keybind",
    Default = "RightShift",
    Mode = "Toggle",
})

Inputs:AddLabel("Color"):AddColorPicker("Color", {
    Title = "Color picker",
    Default = Color3.fromRGB(35, 184, 241),
})

local Feedback = Tabs.Aim:AddRightGroupbox("Feedback")

Feedback:AddButton({
    Text = "Open dialog",
    Action = "Open",
    Func = function()
        Window:Dialog({
            Title = "Concept dialog",
            Content = "Dialogs, popups, and notifications are owned by their window.",
            Buttons = {
                { Title = "Okay" },
            },
        })
    end,
})

Feedback:AddButton({
    Text = "Show notification",
    Action = "Show",
    Func = function()
        Library:Notify({
            Title = "Notification",
            Content = "Everything is still inside the concept.",
        })
    end,
})

-- Movement Tab: Layouts --------------------------------------------------------

local LeftLayout = Tabs.Movement:AddLeftGroupbox("Left groupbox")

LeftLayout:AddParagraph({
    Title = "Groupboxes",
    Content = "Linoria-style left and right groupboxes render inside the Luminware concept.",
})

LeftLayout:AddToggle("LeftToggle", {
    Text = "Left toggle",
    Default = true,
})

local RightLayout = Tabs.Movement:AddRightGroupbox("Right groupbox")

RightLayout:AddSlider("RightSlider", {
    Text = "Right slider",
    Min = 0,
    Max = 100,
    Default = 50,
    Rounding = 0,
})

local LeftTabbox = Tabs.Movement:AddLeftTabbox()
LeftTabbox:AddTab("Tab A"):AddLabel("This is tab A.")
LeftTabbox:AddTab("Tab B"):AddToggle("TabBToggle", {
    Text = "Tab B toggle",
})

local RightTabbox = Tabs.Movement:AddRightTabbox()
RightTabbox:AddTab("Page One"):AddInput("TabboxInput", {
    Text = "Tabbox input",
})
RightTabbox:AddTab("Page Two"):AddDropdown("TabboxDropdown", {
    Text = "Tabbox dropdown",
    Values = { "A", "B", "C" },
    Default = 1,
})

-- Misc Tab: Visual-Only Previews -----------------------------------------------

-- These overlays demonstrate styling only. They do not inspect or target players.
local FOVPreview = Library:CreateFOVCircle({
    Radius = 120,
})

local ESPPreview = Library:CreateESPPreview({
    Text = "VISUAL PREVIEW",
})

local VisualControls = Tabs.Misc:AddLeftGroupbox("Overlay previews")

VisualControls:AddParagraph({
    Title = "Visual demonstrations",
    Content = "Static UI previews for styling and configuration testing.",
})

VisualControls:AddToggle("ShowFOVPreview", {
    Text = "Show FOV circle",
    Callback = function(value)
        FOVPreview:SetVisible(value)
    end,
})

VisualControls:AddSlider("FOVRadius", {
    Text = "FOV circle radius",
    Min = 40,
    Max = 300,
    Default = 120,
    Rounding = 0,
    Callback = function(value)
        FOVPreview:SetRadius(value)
    end,
})

VisualControls:AddToggle("ShowESPPreview", {
    Text = "Show ESP-style preview",
    Callback = function(value)
        ESPPreview:SetVisible(value)
    end,
})

VisualControls:AddSlider("PreviewHealth", {
    Text = "Preview health",
    Min = 0,
    Max = 100,
    Default = 78,
    Rounding = 0,
    Callback = function(value)
        ESPPreview:SetHealth(value / 100)
    end,
})

local PreviewNotes = Tabs.Misc:AddRightGroupbox("Preview notes")
PreviewNotes:AddParagraph({
    Title = "Display only",
    Content = "These overlays are visual examples only and contain no targeting or player inspection logic.",
})

Loader:SetProgress(0.62, "Connecting state and previews")
task.wait(0.08)

-- Farms Tab: Dependencies and State API ----------------------------------------

local Dependencies = Tabs.Farms:AddLeftGroupbox("Dependencies")

Dependencies:AddToggle("DependencyToggle", {
    Text = "Show dependent controls",
    Default = true,
})

local DependencyBox = Dependencies:AddDependencyBox()

DependencyBox:AddSlider("DependentSlider", {
    Text = "Dependent slider",
    Min = 0,
    Max = 10,
    Default = 5,
    Rounding = 1,
})

DependencyBox:AddInput("DependentInput", {
    Text = "Dependent input",
})

DependencyBox:SetupDependencies({
    { Library.Toggles.DependencyToggle, true },
})

local StateAPI = Tabs.Farms:AddRightGroupbox("State API")

StateAPI:AddButton("Set toggle false", function()
    Library.Toggles.DemoToggle:SetValue(false)
end)

StateAPI:AddButton("Set slider to 7.5", function()
    Library.Options.DemoSlider:SetValue(7.5)
end)

StateAPI:AddButton("Select dropdown Three", function()
    Library.Options.SingleDropdown:SetValue("Three")
end)

StateAPI:AddButton("Hide dependent input", function()
    Library.Options.DependentInput:SetVisible(false)
end)

StateAPI:AddButton("Show dependent input", function()
    Library.Options.DependentInput:SetVisible(true)
end)

StateAPI:AddButton("Disable numeric input", function()
    Library.Options.NumericInput:SetDisabled(true)
end)

StateAPI:AddButton("Enable numeric input", function()
    Library.Options.NumericInput:SetDisabled(false)
end)

-- Option Events ----------------------------------------------------------------

Library.Toggles.DemoToggle:OnChanged(function(value)
    print("DemoToggle changed:", value)
end)

Library.Options.DemoSlider:OnChanged(function(value)
    print("DemoSlider changed:", value)
end)

Library.Options.SingleDropdown:OnChanged(function(value)
    print("SingleDropdown changed:", value)
end)

Library.Options.Key:OnClick(function(value)
    print("Keybind clicked:", value)
end)

-- Settings Addons --------------------------------------------------------------

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("Luminware/configs")
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("Luminware")
ThemeManager:BuildSection(Tabs.Settings)

InterfaceManager:SetLibrary(Library)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Loader:SetProgress(0.9, "Applying settings")
task.wait(0.08)

-- Final Reveal -----------------------------------------------------------------

Window:SelectTab(1)

Library:SetWatermark("Luminware " .. Library.Version)
Library:SetWatermarkVisibility(true)

Loader:Complete("Interface ready", function()
    Window:SetVisible(true)

    Library:Notify({
        Title = "Luminware",
        Content = "Complete concept library loaded.",
        Duration = 5,
    })
end)

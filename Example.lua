--[[
    Luminware complete example

    This file demonstrates the recommended startup flow, dashboard,
    controls, layouts, visual previews, state APIs, and settings addons.
]]

-- Dependencies ----------------------------------------------------------------
local base="https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/"
local Library=loadstring(game:HttpGet(base.."Library.lua"))()
local Icons=loadstring(game:HttpGet(base.."Icons.lua"))()
Library:SetIcons(Icons)
local SaveManager=loadstring(game:HttpGet(base.."addons/SaveManager.lua"))()
local ThemeManager=loadstring(game:HttpGet(base.."addons/ThemeManager.lua"))()
local InterfaceManager=loadstring(game:HttpGet(base.."addons/InterfaceManager.lua"))()
-- Boot configuration -----------------------------------------------------------
-- These globals may be set before loading Example.lua to customize startup.
local Global=typeof(getgenv)=="function" and getgenv() or {}
local BootMobile=Global.LuminwareMobileMode
if BootMobile==nil then BootMobile=game:GetService("UserInputService").TouchEnabled end
local BootSmallIcon=Global.LuminwareSmallIcon~=false

-- Startup loader ---------------------------------------------------------------
-- The main window starts hidden and is revealed only after Loader:Complete.
local Loader=Library:CreateLoader({Title="Luminware",Subtitle="Preparing concept interface",MinimumDuration=3})
Loader:SetProgress(0.12,"Creating responsive window")
task.wait(0.1)

-- Window and navigation --------------------------------------------------------
local Window=Library:CreateWindow({
    Size=UDim2.fromOffset(900,600),
    Acrylic=true,
    MobileMode=BootMobile,
    SmallIcon=BootSmallIcon,
    Visible=false,
})

local Tabs={
    Home=Window:AddTab({Title="Home"}),
    Aim=Window:AddTab({Title="Aim"}),
    Movement=Window:AddTab({Title="Movement"}),
    Misc=Window:AddTab({Title="Misc"}),
    Farms=Window:AddTab({Title="Farms"}),
    Settings=Window:AddTab({Title="Settings",Settings=true}),
}
-- Aliases keep the showcase sections below easy to understand.
Tabs.Controls=Tabs.Aim
Tabs.Layouts=Tabs.Movement
Tabs.Visuals=Tabs.Misc
Tabs.State=Tabs.Farms
Loader:SetProgress(0.32,"Building controls")
task.wait(0.08)

-- Home dashboard ---------------------------------------------------------------
local Dashboard=Tabs.Home:AddSubtab("Dashboard")
local Identity=Dashboard.Left:AddCard("Identity")
local PlayerName=Identity:AddStat("Display name","")
local Username=Identity:AddStat("Username","")
local UserId=Identity:AddStat("User ID","")
local AccountAge=Identity:AddStat("Account age","")
local Membership=Identity:AddStat("Membership","")
local Team=Identity:AddStat("Team","")
local Health=Identity:AddStat("Health","")

local Access=Dashboard.Left:AddCard("Access")
local PlayerExecutor=Access:AddStat("Executor","")
local Subscription=Access:AddStat("Subscription","")
local SubscriptionLife=Access:AddStat("Time remaining","")

local PerformanceCard=Dashboard.Right:AddCard("Performance")
local FPS=PerformanceCard:AddStat("Client FPS","")
local Ping=PerformanceCard:AddStat("Network ping","")
local Environment=PerformanceCard:AddStat("Input device","")
local Locale=PerformanceCard:AddStat("Locale","")

local Server=Dashboard.Right:AddCard("Server")
local Experience=Server:AddStat("Experience","",true)
local ServerPopulation=Server:AddStat("Players","")
local Uptime=Server:AddStat("Uptime","")
local Place=Server:AddStat("Place ID","")
local Job=Server:AddStat("Job ID","",true)

local function refreshDashboard()
    local info=Library:GetSessionInfo()
    PlayerName:SetValue(info.DisplayName)
    Username:SetValue("@"..info.Username)
    UserId:SetValue(info.UserId)
    AccountAge:SetValue(info.AccountAge.." days")
    Membership:SetValue(info.Membership)
    Team:SetValue(info.Team)
    Health:SetValue(("%d / %d"):format(info.Health,info.MaxHealth))
    PlayerExecutor:SetValue(info.Executor)
    Subscription:SetValue(info.Subscription)
    SubscriptionLife:SetValue(info.SubscriptionLife)
    FPS:SetValue(info.FPS)
    Ping:SetValue(info.Ping.." ms")
    Environment:SetValue(info.Device)
    Locale:SetValue(info.Locale)
    Experience:SetValue(info.Experience)
    ServerPopulation:SetValue(("%d / %d"):format(info.Players,info.MaxPlayers))
    Uptime:SetValue(("%02d:%02d:%02d"):format(math.floor(info.ServerUptime/3600),math.floor(info.ServerUptime/60)%60,info.ServerUptime%60))
    Place:SetValue(info.PlaceId)
    Job:SetValue(info.JobId~="" and info.JobId or "Studio / unavailable")
end
refreshDashboard()
task.spawn(function() while not Library.Unloaded and Library.Window and Library.Window.Root.Parent do refreshDashboard();task.wait(1) end end)

-- Aim tab: complete controls showcase ------------------------------------------
local Basic=Tabs.Controls:AddLeftGroupbox("Basic controls")
Basic:AddLabel("Labels can be short.")
Basic:AddLabel("Labels can also wrap across multiple lines when the second argument is true.",true)
Basic:AddDivider()
Basic:AddToggle("DemoToggle",{Text="Toggle",Default=true,Tooltip="Every option owns its state."})
Basic:AddSlider("DemoSlider",{Text="Slider",Min=-10,Max=10,Default=2.5,Rounding=1,Suffix="x"})
Basic:AddButton({Text="Single-click button",Action="Run",Func=function()
    Library:Notify({Title="Button",Content="Single-click callback fired."})
end})
Basic:AddButton({Text="Double-click button",Action="Run",DoubleClick=true,Func=function()
    Library:Notify({Title="Button",Content="Double-click callback fired."})
end})

local Inputs=Tabs.Controls:AddRightGroupbox("Inputs and selection")
Inputs:AddDropdown("SingleDropdown",{Text="Dropdown",Values={"One","Two","Three","Four","Five","Six","Seven","Eight","Nine"},Default=1})
Inputs:AddDropdown("MultiDropdown",{Text="Multi dropdown",Values={"One","Two","Three","Four"},Multi=true,Default={"One","Three"}})
Inputs:AddDropdown("PlayerDropdown",{Text="Player dropdown",SpecialType="Player",AllowNull=true})
Inputs:AddInput("TextInput",{Text="Input",Placeholder="Type here",MaxLength=32})
Inputs:AddInput("NumericInput",{Text="Numeric input",Placeholder="123",Numeric=true})
Inputs:AddLabel("Keybind"):AddKeyPicker("Key",{Text="Keybind",Default="RightShift",Mode="Toggle"})
Inputs:AddLabel("Color"):AddColorPicker("Color",{Title="Color picker",Default=Color3.fromRGB(35,184,241)})

local Feedback=Tabs.Controls:AddRightGroupbox("Feedback")
Feedback:AddButton({Text="Open dialog",Action="Open",Func=function()
    Window:Dialog({
        Title="Concept dialog",
        Content="Dialogs, popups, and notifications are owned by their window.",
        Buttons={{Title="Okay"}},
    })
end}):AddButton({Text="Notify",Action="Show",Func=function()
    Library:Notify({Title="Notification",Content="Everything is still inside the concept."})
end})

-- Movement tab: layout showcase ------------------------------------------------
local LeftLayout=Tabs.Layouts:AddLeftGroupbox("Left groupbox")
LeftLayout:AddParagraph({Title="Groupboxes",Content="Linoria-style left and right groupboxes render inside the concept."})
LeftLayout:AddToggle("LeftToggle",{Text="Left toggle",Default=true})

local RightLayout=Tabs.Layouts:AddRightGroupbox("Right groupbox")
RightLayout:AddSlider("RightSlider",{Text="Right slider",Min=0,Max=100,Default=50,Rounding=0})

local LeftTabbox=Tabs.Layouts:AddLeftTabbox()
LeftTabbox:AddTab("Tab A"):AddLabel("This is tab A.")
LeftTabbox:AddTab("Tab B"):AddToggle("TabBToggle",{Text="Tab B toggle"})

local RightTabbox=Tabs.Layouts:AddRightTabbox()
RightTabbox:AddTab("Page One"):AddInput("TabboxInput",{Text="Tabbox input"})
RightTabbox:AddTab("Page Two"):AddDropdown("TabboxDropdown",{Text="Tabbox dropdown",Values={"A","B","C"},Default=1})

-- Misc tab: visual-only previews -----------------------------------------------
-- These overlays do not target or inspect players.
local FOVPreview=Library:CreateFOVCircle({Radius=120})
local ESPPreview=Library:CreateESPPreview({Text="VISUAL PREVIEW"})
local VisualControls=Tabs.Visuals:AddLeftGroupbox("Overlay previews")
VisualControls:AddParagraph({Title="Visual demonstrations",Content="Static UI previews for styling and configuration testing."})
VisualControls:AddToggle("ShowFOVPreview",{Text="Show FOV circle",Callback=function(value)FOVPreview:SetVisible(value)end})
VisualControls:AddSlider("FOVRadius",{Text="FOV circle radius",Min=40,Max=300,Default=120,Rounding=0,Callback=function(value)FOVPreview:SetRadius(value)end})
VisualControls:AddToggle("ShowESPPreview",{Text="Show ESP-style preview",Callback=function(value)ESPPreview:SetVisible(value)end})
VisualControls:AddSlider("PreviewHealth",{Text="Preview health",Min=0,Max=100,Default=78,Rounding=0,Callback=function(value)ESPPreview:SetHealth(value/100)end})
Tabs.Visuals:AddRightGroupbox("Preview notes"):AddParagraph({Title="Display only",Content="These overlays are visual examples only and contain no targeting or player inspection logic."})
Loader:SetProgress(0.62,"Connecting state and previews")
task.wait(0.08)

-- Farms tab: state and API showcase --------------------------------------------
local Dependencies=Tabs.State:AddLeftGroupbox("Dependencies")
Dependencies:AddToggle("DependencyToggle",{Text="Show dependent controls",Default=true})
local Depbox=Dependencies:AddDependencyBox()
Depbox:AddSlider("DependentSlider",{Text="Dependent slider",Min=0,Max=10,Default=5,Rounding=1})
Depbox:AddInput("DependentInput",{Text="Dependent input"})
Depbox:SetupDependencies({{Library.Toggles.DependencyToggle,true}})

local StateAPI=Tabs.State:AddRightGroupbox("State API")
StateAPI:AddButton("Set toggle false",function() Library.Toggles.DemoToggle:SetValue(false) end)
StateAPI:AddButton("Set slider to 7.5",function() Library.Options.DemoSlider:SetValue(7.5) end)
StateAPI:AddButton("Select dropdown Three",function() Library.Options.SingleDropdown:SetValue("Three") end)
StateAPI:AddButton("Hide dependent input",function() Library.Options.DependentInput:SetVisible(false) end)
StateAPI:AddButton("Show dependent input",function() Library.Options.DependentInput:SetVisible(true) end)
StateAPI:AddButton("Disable numeric input",function() Library.Options.NumericInput:SetDisabled(true) end)
StateAPI:AddButton("Enable numeric input",function() Library.Options.NumericInput:SetDisabled(false) end)

Library.Toggles.DemoToggle:OnChanged(function(value)
    print("DemoToggle changed:",value)
end)
Library.Options.DemoSlider:OnChanged(function(value)
    print("DemoSlider changed:",value)
end)
Library.Options.SingleDropdown:OnChanged(function(value)
    print("SingleDropdown changed:",value)
end)
Library.Options.Key:OnClick(function(value)
    print("Keybind clicked:",value)
end)

-- Settings addons --------------------------------------------------------------
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("Luminware/configs")
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("Luminware")
ThemeManager:BuildSection(Tabs.Settings)

InterfaceManager:SetLibrary(Library)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
Loader:SetProgress(0.9,"Applying settings")
task.wait(0.08)

-- Final reveal -----------------------------------------------------------------
Window:SelectTab(1)
Library:SetWatermark("Luminware "..Library.Version)
Library:SetWatermarkVisibility(true)
Loader:Complete("Interface ready",function()
    Window:SetVisible(true)
    Library:Notify({Title="Luminware",Content="Complete concept library loaded",Duration=5})
end)

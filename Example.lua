local base="https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/"
local Library=loadstring(game:HttpGet(base.."Library.lua"))()
local SaveManager=loadstring(game:HttpGet(base.."addons/SaveManager.lua"))()
local ThemeManager=loadstring(game:HttpGet(base.."addons/ThemeManager.lua"))()
local InterfaceManager=loadstring(game:HttpGet(base.."addons/InterfaceManager.lua"))()
local Global=typeof(getgenv)=="function" and getgenv() or {}
local BootMobile=Global.LuminwareMobileMode
if BootMobile==nil then BootMobile=game:GetService("UserInputService").TouchEnabled end
local BootSmallIcon=Global.LuminwareSmallIcon~=false

local Loader=Library:CreateLoader({Title="Luminware",Subtitle="Preparing concept interface"})
Loader:SetProgress(0.12,"Creating responsive window")
task.wait(0.1)

local Window=Library:CreateWindow({
    Size=UDim2.fromOffset(900,600),
    Acrylic=true,
    MobileMode=BootMobile,
    SmallIcon=BootSmallIcon,
})

local Tabs={
    Home=Window:AddTab({Title="Home",IconText="S"}),
    Controls=Window:AddTab({Title="Controls",IconText="C"}),
    Layouts=Window:AddTab({Title="Layouts",IconText="L"}),
    Visuals=Window:AddTab({Title="Visuals",IconText="V"}),
    State=Window:AddTab({Title="State",IconText="D"}),
    Settings=Window:AddTab({Title="Settings",IconText="G"}),
}
Loader:SetProgress(0.32,"Building controls")
task.wait(0.08)

-- Original concept layout
local Main=Tabs.Home:AddSubtab("Subtab 1")
local Second=Tabs.Home:AddSubtab("Subtab 2")

local Things=Main.Left:AddCard("Things")
Things:AddToggle("Thing1",{Text="Thing 1",Default=true})
Things:AddToggle("Thing2",{Text="Thing 2",Default=false})
Things:AddSlider("Thing3",{Text="Thing 3",Min=0,Max=100,Default=72,Rounding=0})

local Controls=Main.Right:AddCard("Controls")
Controls:AddToggle("Enabled",{Text="Toggle",Default=true})
Controls:AddSlider("Amount",{Text="Slider",Min=0,Max=100,Default=64,Rounding=0})
Controls:AddButton("Button",function() Library:Notify({Title="Action",Content="Button pressed"}) end)

local Modules=Main.Right:AddCard("Module One")
Modules:AddLabel("Actions")
Modules:AddDropdown("ModuleAction",{Text="Action",Values={"One","Two","Three","Four"},Default=2})

Second.Left:AddCard("Second page"):AddParagraph({
    Title="Subtabs",
    Content="Every navigation page can contain multiple concept-style subtabs.",
})

-- Complete controls showcase
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

-- Layout showcase
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

-- Visual-only overlay previews; these do not target or inspect players.
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

-- State and API showcase
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

Window:SelectTab(1)
Library:SetWatermark("Luminware "..Library.Version)
Library:SetWatermarkVisibility(true)
Loader:Complete("Interface ready")
Library:Notify({Title="Luminware",Content="Complete concept library loaded",Duration=5})

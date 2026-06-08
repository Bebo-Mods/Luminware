local base="https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/"
local Library=loadstring(game:HttpGet(base.."Library.lua"))()
local SaveManager=loadstring(game:HttpGet(base.."addons/SaveManager.lua"))()
local ThemeManager=loadstring(game:HttpGet(base.."addons/ThemeManager.lua"))()
local InterfaceManager=loadstring(game:HttpGet(base.."addons/InterfaceManager.lua"))()

local Window=Library:CreateWindow({
    Size=UDim2.fromOffset(900,600),
    Acrylic=true,
})

local Tabs={
    Home=Window:AddTab({Title="Home",IconText="S"}),
    Features=Window:AddTab({Title="Features",IconText="P"}),
    Settings=Window:AddTab({Title="Settings",IconText="G"}),
}

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

-- Linoria-style API and functionality
local Inputs=Tabs.Features:AddLeftGroupbox("Inputs")
Inputs:AddLabel("All controls below own their state and callbacks.")
Inputs:AddDivider()
Inputs:AddDropdown("SingleDropdown",{Text="Dropdown",Values={"One","Two","Three"},Default=1})
Inputs:AddDropdown("MultiDropdown",{Text="Multi dropdown",Values={"One","Two","Three"},Multi=true,Default={"One"}})
Inputs:AddInput("TextInput",{Text="Input",Placeholder="Type here",MaxLength=32})
Inputs:AddLabel("Keybind"):AddKeyPicker("Key",{Text="Keybind",Default="RightShift",Mode="Toggle"})
Inputs:AddLabel("Color"):AddColorPicker("Color",{Title="Color picker",Default=Color3.fromRGB(35,184,241)})

local Feedback=Tabs.Features:AddRightGroupbox("Feedback")
Feedback:AddButton({Text="Open dialog",Action="Open",Func=function()
    Window:Dialog({
        Title="Concept dialog",
        Content="Dialogs, popups, and notifications are owned by their window.",
        Buttons={{Title="Okay"}},
    })
end}):AddButton({Text="Notify",Action="Show",Func=function()
    Library:Notify({Title="Notification",Content="Everything is still inside the concept."})
end})

local Dependencies=Tabs.Features:AddRightGroupbox("Dependencies")
Dependencies:AddToggle("DependencyToggle",{Text="Show dependent controls",Default=true})
local Depbox=Dependencies:AddDependencyBox()
Depbox:AddSlider("DependentSlider",{Text="Dependent slider",Min=0,Max=10,Default=5,Rounding=1})
Depbox:AddInput("DependentInput",{Text="Dependent input"})
Depbox:SetupDependencies({{Library.Toggles.DependencyToggle,true}})

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("Luminware/configs")
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("Luminware")
ThemeManager:BuildSection(Tabs.Settings)

InterfaceManager:SetLibrary(Library)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)
Library:SetWatermark("Luminware "..Library.Version)
Library:SetWatermarkVisibility(true)
Library:Notify({Title="Luminware",Content="Complete concept library loaded",Duration=5})

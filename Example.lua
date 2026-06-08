local base="https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/"
local Luminware=loadstring(game:HttpGet(base.."Library.lua"))()
local SaveManager=loadstring(game:HttpGet(base.."addons/SaveManager.lua"))()
local InterfaceManager=loadstring(game:HttpGet(base.."addons/InterfaceManager.lua"))()

local Window=Luminware:CreateWindow({
    Title="Luminware "..Luminware.Version,
    Size=UDim2.fromOffset(900,560),
    Acrylic=true,
    Theme="FROST",
})

local Tabs={
    Home=Window:AddTab({Name="Home",Icon="home"}),
    Features=Window:AddTab({Name="Features",Icon="settings"}),
    Settings=Window:AddTab({Name="Settings",Icon="settings"}),
}

local Main=Tabs.Home:AddSubtab("Subtab 1")
local Alternate=Tabs.Home:AddSubtab("Subtab 2")

local Things=Main.Left:AddCard("Things")
Things:AddToggle("Thing1",{Title="Thing 1",Default=true})
Things:AddToggle("Thing2",{Title="Thing 2",Default=false})
Things:AddSlider("Thing3",{Title="Thing 3",Min=0,Max=100,Default=72})

local Controls=Main.Right:AddCard("Controls")
Controls:AddToggle("Enabled",{Title="Toggle",Default=true})
Controls:AddSlider("Amount",{Title="Slider",Min=0,Max=100,Default=64})
Controls:AddButton({Title="Button",Action="Action",Callback=function()
    Luminware:Notify({Title="Action",Content="Button pressed",Duration=3})
end})

local FluentStyle=Tabs.Features:AddSection("Fluent-compatible controls")
FluentStyle:AddParagraph({Title="Paragraph",Content="Luminware supports Fluent-style sections and controls."})
FluentStyle:AddDropdown("Mode",{Title="Dropdown",Values={"One","Two","Three","Four"},Default=1})
FluentStyle:AddDropdown("Multi",{Title="Multi dropdown",Values={"One","Two","Three"},Multi=true,Default={"One"}})
FluentStyle:AddInput("Name",{Title="Input",Placeholder="Type here"})
FluentStyle:AddKeybind("MenuBind",{Title="Keybind",Default="RightShift",Mode="Toggle"})
FluentStyle:AddColorpicker("Accent",{Title="Color picker",Default=Color3.fromRGB(35,184,241)})

Alternate.Left:AddCard("Second page"):AddParagraph({
    Title="Subtabs",
    Content="Use subtabs and left/right cards for the home-control dashboard layout.",
})

SaveManager:SetLibrary(Luminware)
SaveManager:SetFolder("Luminware/configs")
SaveManager:BuildConfigSection(Tabs.Settings)

InterfaceManager:SetLibrary(Luminware)
InterfaceManager:SetFolder("Luminware")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)
Luminware:Notify({Title="Luminware",Content="Library loaded",Duration=5})

local base="https://raw.githubusercontent.com/Bebo-Mods/Luminware/main/"
local Luminware=loadstring(game:HttpGet(base.."Library.lua"))()
local SaveManager=loadstring(game:HttpGet(base.."addons/SaveManager.lua"))()
local ThemeManager=loadstring(game:HttpGet(base.."addons/ThemeManager.lua"))()
local InterfaceManager=loadstring(game:HttpGet(base.."addons/InterfaceManager.lua"))()

local Window=Luminware:CreateWindow({
    Size=UDim2.fromOffset(900,600),
    Acrylic=true,
})

local Home=Window:AddTab({Title="Home",IconText="S"})
local Features=Window:AddTab({Title="Features",IconText="P"})
local Settings=Window:AddTab({Title="Settings",IconText="G"})

local Main=Home:AddSubtab("Subtab 1")
local Second=Home:AddSubtab("Subtab 2")

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

local Modules=Main.Right:AddCard("Module One")
Modules:AddParagraph({Title="Actions",Content="Choose an action below."})
Modules:AddDropdown("ModuleAction",{Title="Action",Values={"One","Two","Three","Four"},Default=2})

Second.Left:AddCard("Second page"):AddParagraph({
    Title="Subtabs",
    Content="Every tab can contain multiple concept-style subtabs.",
})

local Inputs=Features:AddSection("Inputs")
Inputs:AddDropdown("Multi",{Title="Multi dropdown",Values={"One","Two","Three"},Multi=true,Default={"One"}})
Inputs:AddInput("Name",{Title="Input",Placeholder="Type here"})
Inputs:AddKeybind("Key",{Title="Keybind",Default="RightShift",Mode="Toggle"})
Inputs:AddColorpicker("Color",{Title="Color picker",Default=Color3.fromRGB(35,184,241)})

local Feedback=Features:AddSection("Feedback")
Feedback:AddParagraph({Title="Paragraph",Content="The complete feature set lives inside the original concept."})
Feedback:AddButton({Title="Open dialog",Action="Open",Callback=function()
    Window:Dialog({
        Title="Concept dialog",
        Content="Dialogs use the same soft glass cards.",
        Buttons={{Title="Okay"}},
    })
end})

SaveManager:SetLibrary(Luminware)
SaveManager:SetFolder("Luminware/configs")
SaveManager:BuildConfigSection(Settings)

ThemeManager:SetLibrary(Luminware)
ThemeManager:BuildSection(Settings)

InterfaceManager:SetLibrary(Luminware)
InterfaceManager:BuildInterfaceSection(Settings)

Window:SelectTab(1)
Luminware:ToggleAcrylic(true)
Luminware:Notify({Title="Luminware",Content="Concept library loaded",Duration=5})

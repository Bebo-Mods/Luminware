local IM={Library=nil,Folder="Luminware"}

function IM:SetLibrary(library) self.Library=library end
function IM:SetFolder(folder) self.Folder=folder end

function IM:BuildInterfaceSection(target)
    local L=self.Library
    assert(L,"SetLibrary first")
    local section=target.AddSection and target:AddSection("Interface") or target.Left:AddCard("Interface")
    section:AddDropdown("LW_Theme",{
        Title="Theme",
        Values={"FROST","VENOM","BLOOD","EMBER","ACID","GHOST"},
        Default=L._currentTheme,
        Callback=function(value) L:SetTheme(value) end,
    })
    section:AddToggle("LW_Acrylic",{
        Title="Acrylic",
        Default=true,
        Callback=function(value) L:ToggleAcrylic(value) end,
    })
    section:AddKeybind("LW_MenuKey",{
        Title="Menu key",
        Default="RightShift",
        Mode="Toggle",
        Callback=function() if L.Window then L.Window:Toggle() end end,
    })
    section:AddButton({
        Title="Unload interface",
        Action="Unload",
        Callback=function() L:Unload() end,
    })
    return section
end

return IM

local InterfaceManager={Library=nil,Folder="Luminware"}

function InterfaceManager:SetLibrary(library) self.Library=library end
function InterfaceManager:SetFolder(folder) self.Folder=folder end

function InterfaceManager:BuildInterfaceSection(target)
    local L=self.Library
    assert(L,"SetLibrary first")
    local section=target.AddSection and target:AddSection("Interface") or target.Left:AddCard("Interface")
    section:AddKeybind("LW_MenuKey",{
        Title="Menu key",
        Default="RightShift",
        Mode="Toggle",
        Callback=function() if L.Window then L.Window:Toggle() end end,
    })
    section:AddButton({Title="Unload interface",Action="Unload",Callback=function() L:Unload() end})
    return section
end

return InterfaceManager

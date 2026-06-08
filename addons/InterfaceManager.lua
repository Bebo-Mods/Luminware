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
    section:AddToggle("LW_MobileMode",{Title="Mobile mode",Default=L.Window and L.Window.MobileMode or false,Callback=function(value)L:SetMobileMode(value)end})
    section:AddToggle("LW_SmallIcon",{Title="Hidden restore icon",Default=L.Window==nil or L.Window.SmallIconEnabled,Callback=function(value)L:SetSmallIconEnabled(value)end})
    section:AddToggle("LW_Watermark",{Title="Watermark and performance",Default=true,Callback=function(value)L:SetWatermarkVisibility(value)end})
    section:AddButton({Title="Unload interface",Action="Unload",Callback=function() L:Unload() end})
    return section
end

return InterfaceManager

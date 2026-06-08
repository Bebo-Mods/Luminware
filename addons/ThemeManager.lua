local ThemeManager={Library=nil,Folder="Luminware"}

function ThemeManager:SetLibrary(library) self.Library=library end
function ThemeManager:SetFolder(folder) self.Folder=folder end

function ThemeManager:BuildSection(target)
    local L=self.Library
    assert(L,"SetLibrary first")
    local section=target.AddSection and target:AddSection("Appearance") or target.Left:AddCard("Appearance")
    section:AddDropdown("LW_Theme",{
        Title="Theme",
        Values={"Concept","Warm","Plum"},
        Default=L.Theme or "Concept",
        Callback=function(value) L:SetTheme(value) end,
    })
    section:AddToggle("LW_Acrylic",{
        Title="Acrylic blur",
        Default=true,
        Callback=function(value) L:ToggleAcrylic(value) end,
    })
    section:AddToggle("LW_Transparent",{
        Title="More transparent",
        Default=false,
        Callback=function(value) L:ToggleTransparency(value) end,
    })
    return section
end

ThemeManager.ApplyToTab=ThemeManager.BuildSection
return ThemeManager

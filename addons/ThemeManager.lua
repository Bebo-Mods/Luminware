local HttpService=game:GetService("HttpService")
local ThemeManager={Library=nil,Folder="Luminware",Memory={}}
local fields={"Accent","Panel","Card","Rail","Control","Text","Muted","Dark","White"}
local hasFiles=typeof(writefile)=="function" and typeof(readfile)=="function" and typeof(isfile)=="function"

local function ensure(path)
    if hasFiles and typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(path) then pcall(makefolder,path) end
end
local function path(self,name) return self.Folder.."/themes/"..name..".json" end

function ThemeManager:SetLibrary(library) self.Library=library end
function ThemeManager:SetFolder(folder) self.Folder=folder;ensure(folder);ensure(folder.."/themes") end
function ThemeManager:ApplyTheme(name)
    local L=self.Library
    local builtIn=L.Themes[name]
    local theme=builtIn or self:GetCustomTheme(name)
    if theme then
        if builtIn then L:SetTheme(name) else L:SetTheme(theme);L.Theme=name end
        for _,field in ipairs(fields) do local option=L.Options["LW_Color_"..field];if option then option:SetValueRGB(L.Colors[field]) end end
    end
end
function ThemeManager:SaveCustomTheme(name)
    if not name or name:gsub("%s","")=="" then return false,"missing name" end
    local data={} for _,field in ipairs(fields) do data[field]=self.Library.Colors[field]:ToHex() end
    local encoded=HttpService:JSONEncode(data)
    if hasFiles then ensure(self.Folder.."/themes");writefile(path(self,name),encoded) else self.Memory[name]=encoded end
    return true
end
function ThemeManager:GetCustomTheme(name)
    local encoded=hasFiles and isfile(path(self,name)) and readfile(path(self,name)) or self.Memory[name]
    if not encoded then return nil end
    local ok,data=pcall(HttpService.JSONDecode,HttpService,encoded);if not ok then return nil end
    local theme={} for field,hex in next,data do theme[field]=Color3.fromHex(hex) end
    return theme
end
function ThemeManager:ReloadCustomThemes()
    local out={}
    if hasFiles and typeof(listfiles)=="function" then for _,file in ipairs(listfiles(self.Folder.."/themes")) do local name=file:match("([^/\\]+)%.json$");if name then table.insert(out,name) end end
    else for name in next,self.Memory do table.insert(out,name) end end
    table.sort(out);return out
end
function ThemeManager:SaveDefault(name)
    if hasFiles then ensure(self.Folder.."/themes");writefile(self.Folder.."/themes/default.txt",name) else self.Memory.__default=name end
end
function ThemeManager:LoadDefault()
    local name=hasFiles and isfile(self.Folder.."/themes/default.txt") and readfile(self.Folder.."/themes/default.txt") or self.Memory.__default
    if name then self:ApplyTheme(name) end
end

function ThemeManager:BuildSection(target)
    local L=self.Library;assert(L,"SetLibrary first")
    self:SetFolder(self.Folder)
    local section=target.AddSection and target:AddSection("Appearance") or target.Left:AddCard("Appearance")
    local builtins={} for name in next,L.Themes do table.insert(builtins,name) end table.sort(builtins)
    local theme=section:AddDropdown("LW_Theme",{Text="Built-in theme",Values=builtins,Default=L.Theme})
    theme:OnChanged(function(value) self:ApplyTheme(value) end)
    local customName=section:AddInput("LW_CustomThemeName",{Text="Custom theme name",Placeholder="my-theme"})
    local custom=section:AddDropdown("LW_CustomThemeList",{Text="Custom themes",Values=self:ReloadCustomThemes(),AllowNull=true})
    section:AddButton("Save custom theme",function() self:SaveCustomTheme(customName.Value);custom:SetValues(self:ReloadCustomThemes()) end)
    section:AddButton("Load custom theme",function() self:ApplyTheme(custom.Value) end)
    section:AddButton("Set selected default",function() self:SaveDefault(custom.Value or theme.Value) end)
    for _,field in ipairs(fields) do
        section:AddColorPicker("LW_Color_"..field,{Text=field,Default=L.Colors[field],Callback=function(color)
            L.Colors[field]=color;L:UpdateColorsUsingRegistry()
        end})
    end
    section:AddToggle("LW_Acrylic",{Text="Acrylic blur",Default=true,Callback=function(value)L:ToggleAcrylic(value)end})
    section:AddToggle("LW_Transparent",{Text="More transparent",Default=false,Callback=function(value)L:ToggleTransparency(value)end})
    self:LoadDefault()
    return section
end

ThemeManager.ApplyToTab=ThemeManager.BuildSection
return ThemeManager

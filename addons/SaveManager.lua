local HttpService=game:GetService("HttpService")
local SaveManager={Library=nil,Folder="Luminware/configs",Ignore={}}
local memory={}
local hasFiles=typeof(writefile)=="function" and typeof(readfile)=="function" and typeof(isfile)=="function"

local function ensure(folder)
    if hasFiles and typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(folder) then pcall(makefolder,folder) end
end
local function path(self,name) return self.Folder.."/"..name..".json" end

function SaveManager:SetLibrary(library) self.Library=library end
function SaveManager:SetFolder(folder) self.Folder=folder;ensure(folder) end
function SaveManager:SetIgnoreIndexes(indexes) for _,index in ipairs(indexes or {}) do self.Ignore[index]=true end end
function SaveManager:SetIgnore(indexes) self:SetIgnoreIndexes(indexes) end
function SaveManager:IgnoreThemeSettings() self:SetIgnoreIndexes({"LW_Theme","LW_Acrylic","LW_Transparent","LW_MenuKey"}) end

function SaveManager:Gather()
    local output={}
    for index,option in next,self.Library.Options do
        if not self.Ignore[index] then
            local value=option.Value
            if option.Type=="ColorPicker" then value={Hex=option.Value:ToHex(),Transparency=option.Transparency}
            elseif option.Type=="KeyPicker" then value={Key=option.Value,Mode=option.Mode} end
            output[index]={Type=option.Type,Value=value}
        end
    end
    return output
end

function SaveManager:Apply(data)
    for index,saved in next,data or {} do
        local option=self.Library.Options[index]
        if option and option.SetValue then
            if saved.Type=="ColorPicker" then option:SetValueRGB(Color3.fromHex(saved.Value.Hex),saved.Value.Transparency)
            elseif saved.Type=="KeyPicker" then option:SetValue(saved.Value.Key,saved.Value.Mode)
            else option:SetValue(saved.Value) end
        end
    end
end

function SaveManager:Save(name)
    if not name or name=="" then return false,"missing name" end
    local encoded=HttpService:JSONEncode(self:Gather())
    if hasFiles then ensure(self.Folder);writefile(path(self,name),encoded) else memory[name]=encoded end
    return true
end
function SaveManager:Load(name)
    if not name or name=="" then return false,"missing name" end
    local encoded=hasFiles and isfile(path(self,name)) and readfile(path(self,name)) or memory[name]
    if not encoded then return false,"not found" end
    self:Apply(HttpService:JSONDecode(encoded));return true
end
function SaveManager:Delete(name)
    if hasFiles and typeof(delfile)=="function" and isfile(path(self,name)) then delfile(path(self,name)) else memory[name]=nil end
end
function SaveManager:RefreshConfigList()
    local list={}
    if hasFiles and typeof(listfiles)=="function" then
        for _,file in ipairs(listfiles(self.Folder)) do local name=file:match("([^/\\]+)%.json$");if name then table.insert(list,name) end end
    else for name in next,memory do table.insert(list,name) end end
    table.sort(list);return list
end
SaveManager.List=SaveManager.RefreshConfigList
function SaveManager:SetAutoload(name) if hasFiles then writefile(self.Folder.."/autoload.txt",name) else memory.__autoload=name end end
function SaveManager:LoadAutoloadConfig()
    local name=hasFiles and isfile(self.Folder.."/autoload.txt") and readfile(self.Folder.."/autoload.txt") or memory.__autoload
    if name then self:Load(name) end
end
SaveManager.LoadAutoload=SaveManager.LoadAutoloadConfig

function SaveManager:BuildConfigSection(target)
    local section=target.AddSection and target:AddSection("Configuration") or target.Left:AddCard("Configuration")
    local name=section:AddInput("SaveManager_Name",{Title="Config name",Placeholder="my-config"})
    local list=section:AddDropdown("SaveManager_List",{Title="Saved configs",Values=self:RefreshConfigList()})
    section:AddButton({Title="Save config",Action="Save",Callback=function() self:Save(name.Value);list:SetValues(self:RefreshConfigList()) end})
    section:AddButton({Title="Load config",Action="Load",Callback=function() self:Load(list.Value) end})
    section:AddButton({Title="Set autoload",Action="Set",Callback=function() self:SetAutoload(list.Value) end})
    section:AddButton({Title="Delete config",Action="Delete",Callback=function() self:Delete(list.Value);list:SetValues(self:RefreshConfigList()) end})
    self:SetIgnoreIndexes({"SaveManager_Name","SaveManager_List"})
    return section
end
SaveManager.BuildSection=SaveManager.BuildConfigSection

return SaveManager

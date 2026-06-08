--[[
    LUMINWARE — SaveManager v2.0
    Standalone config save/load system.

    USAGE:
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("Luminware/configs")
        SaveManager:BuildSection(settingsTab)
        SaveManager:LoadAutoload()
]]

local SaveManager = { Library = nil, Folder = "Luminware/configs", Ignore = {} }

local HttpService = game:GetService("HttpService")
local hasFS = (typeof(writefile)=="function") and (typeof(readfile)=="function")
    and (typeof(isfile)=="function") and (typeof(listfiles)=="function")
local _mem = {}

local function ensureFolder(f)
    if not hasFS then return end
    pcall(function()
        if typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(f) then
            makefolder(f)
        end
    end)
end

function SaveManager:SetLibrary(lib) self.Library = lib end
function SaveManager:SetFolder(f) self.Folder = f; ensureFolder(f) end
function SaveManager:SetIgnore(list) for _,k in next,list do self.Ignore[k]=true end end
function SaveManager:IgnoreThemeSettings()
    self:SetIgnore({"LW_Theme","LW_Accent","LW_Glow"})
end

local function cfgPath(self, name) return self.Folder.."/"..name..".json" end

local function getToggles(self)
    local L = self.Library
    return (L and L.Toggles) or (typeof(getgenv)=="function" and getgenv().Toggles) or {}
end
local function getOptions(self)
    local L = self.Library
    return (L and L.Options) or (typeof(getgenv)=="function" and getgenv().Options) or {}
end

function SaveManager:Gather()
    local data = { toggles={}, options={} }
    for idx, t in next, getToggles(self) do
        if not self.Ignore[idx] then data.toggles[idx] = t.Value end
    end
    for idx, o in next, getOptions(self) do
        if not self.Ignore[idx] then
            if o.Type == "Toggle"      then data.options[idx] = { kind="bool",   val=o.Value }
            elseif o.Type == "Slider"  then data.options[idx] = { kind="num",    val=o.Value }
            elseif o.Type == "Input"   then data.options[idx] = { kind="str",    val=o.Value }
            elseif o.Type == "Dropdown" then data.options[idx] = { kind="str",    val=o.Value }
            elseif o.Type == "KeyPicker" then data.options[idx] = { kind="key",  key=o.Value, mode=o.Mode }
            elseif o.Type == "ColorPicker" then
                data.options[idx] = { kind="color", hex=o.Value:ToHex(), t=o.Transparency or 0 }
            end
        end
    end
    return data
end

function SaveManager:Apply(data)
    for idx, v in next, (data.toggles or {}) do
        local t = getToggles(self)[idx]
        if t then pcall(function() t:SetValue(v) end) end
    end
    for idx, entry in next, (data.options or {}) do
        local o = getOptions(self)[idx]
        if o then
            pcall(function()
                if entry.kind == "color" then
                    local ok,col = pcall(Color3.fromHex, entry.hex)
                    if ok and o.SetValueRGB then o:SetValueRGB(col, entry.t or 0) end
                elseif entry.kind == "key" then
                    if o.SetValue then o:SetValue({entry.key, entry.mode}) end
                else
                    if o.SetValue then o:SetValue(entry.val) end
                end
            end)
        end
    end
end

function SaveManager:Save(name)
    if not name or name=="" then return false,"no name" end
    local ok, json = pcall(HttpService.JSONEncode, HttpService, self:Gather())
    if not ok then return false,"encode error" end
    if hasFS then pcall(writefile, cfgPath(self,name), json)
    else _mem[name] = json end
    return true
end

function SaveManager:Load(name)
    if not name or name=="" then return false,"no name" end
    local contents
    if hasFS then
        if not isfile(cfgPath(self,name)) then return false,"not found" end
        local ok,c = pcall(readfile, cfgPath(self,name))
        if not ok then return false,"read error" end
        contents = c
    else contents = _mem[name] end
    if not contents then return false,"not found" end
    local ok,data = pcall(HttpService.JSONDecode, HttpService, contents)
    if not ok then return false,"decode error" end
    self:Apply(data)
    return true
end

function SaveManager:Delete(name)
    if hasFS and typeof(delfile)=="function" then pcall(delfile, cfgPath(self,name))
    else _mem[name] = nil end
    return true
end

function SaveManager:List()
    local out = {}
    if hasFS then
        local ok,files = pcall(listfiles, self.Folder)
        if ok and files then
            for _,f in next,files do
                local n = tostring(f):match("([^/\\]+)%.json$")
                if n and n~="_autoload" then table.insert(out,n) end
            end
        end
    else for k in next,_mem do if k~="_autoload" then table.insert(out,k) end end end
    return out
end

function SaveManager:SetAutoload(name)
    if hasFS then pcall(writefile, self.Folder.."/_autoload.txt", name)
    else _mem["_autoload"] = name end
end

function SaveManager:GetAutoload()
    if hasFS and typeof(isfile)=="function" and isfile(self.Folder.."/_autoload.txt") then
        local ok,c = pcall(readfile, self.Folder.."/_autoload.txt")
        if ok then return c end
    end
    return _mem["_autoload"]
end

function SaveManager:LoadAutoload()
    local name = self:GetAutoload()
    if name then
        local ok,err = self:Load(name)
        if self.Library then
            if ok then self.Library:Notify({ Title="Config loaded", Body=name, Duration=3 })
            else self.Library:Notify({ Title="Autoload failed", Body=tostring(err), Duration=3 }) end
        end
    end
end

function SaveManager:BuildSection(tab)
    assert(self.Library, "Call SaveManager:SetLibrary first")
    local L = self.Library
    local sec = tab:AddSection("Configuration")

    local nameInput = sec:AddInput("LW_CfgName", {
        Label = "Config Name", Placeholder = "my_config", Finished = true,
    })

    local listDD = sec:AddDropdown("LW_CfgList", {
        Label = "Saved Configs", Values = self:List(), Default = nil,
    })
    if listDD and not listDD.Value and #(self:List()) > 0 then
        listDD:SetValue(self:List()[1])
    end

    sec:AddButton({ Label = "Save Config",   Action = "Save",    Callback = function()
        local ok, err = self:Save(nameInput.Value)
        if ok then L:Notify({ Title="Saved", Body=nameInput.Value, Duration=3 })
        else L:Notify({ Title="Save failed", Body=tostring(err), Duration=3 }) end
        if listDD then listDD:SetValues(self:List()) end
    end })

    sec:AddButton({ Label = "Load Config",   Action = "Load",    Callback = function()
        local ok, err = self:Load(listDD and listDD.Value)
        if ok then L:Notify({ Title="Loaded", Body=tostring(listDD and listDD.Value), Duration=3 })
        else L:Notify({ Title="Load failed", Body=tostring(err), Duration=3 }) end
    end })

    sec:AddButton({ Label = "Set Autoload",  Action = "Set",     Callback = function()
        if listDD and listDD.Value then
            self:SetAutoload(listDD.Value)
            L:Notify({ Title="Autoload set", Body=listDD.Value, Duration=3 })
        end
    end })

    sec:AddButton({ Label = "Refresh List",  Action = "Refresh", Callback = function()
        if listDD then listDD:SetValues(self:List()) end
    end })

    sec:AddButton({ Label = "Delete Config", Action = "Delete",  Callback = function()
        if listDD and listDD.Value then
            self:Delete(listDD.Value)
            if listDD then listDD:SetValues(self:List()) end
            L:Notify({ Title="Deleted", Body=tostring(listDD and listDD.Value), Duration=3 })
        end
    end })

    return sec
end

return SaveManager
local SaveManager = {
    Folder  = "Luminware";
    Library = nil;
    Ignore  = {};       -- option indexes to skip
    Parser  = {};       -- per-type serialize/deserialize
}

-- ── Safe filesystem layer ───────────────────────────────
local hasFS = (typeof(writefile)=="function") and (typeof(readfile)=="function")
    and (typeof(isfile)=="function") and (typeof(listfiles)=="function")
local HttpService = game:GetService("HttpService")
local memStore = {}

local function ensureFolder(path)
    if not hasFS then return end
    pcall(function()
        if typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(path) then
            makefolder(path)
        end
    end)
end

-- ── Per-type (de)serialization ──────────────────────────
SaveManager.Parser = {
    Toggle = {
        Save = function(idx, obj) return { type="Toggle", idx=idx, value=obj.Value } end,
        Load = function(idx, data) if SaveManager.Toggles[idx] then SaveManager.Toggles[idx]:SetValue(data.value) end end,
    },
    Slider = {
        Save = function(idx, obj) return { type="Slider", idx=idx, value=tostring(obj.Value) } end,
        Load = function(idx, data) if SaveManager.Options[idx] then SaveManager.Options[idx]:SetValue(data.value) end end,
    },
    Input = {
        Save = function(idx, obj) return { type="Input", idx=idx, text=obj.Value } end,
        Load = function(idx, data) if SaveManager.Options[idx] then SaveManager.Options[idx]:SetValue(data.text) end end,
    },
    Dropdown = {
        Save = function(idx, obj) return { type="Dropdown", idx=idx, value=obj.Value, multi=obj.Multi } end,
        Load = function(idx, data) if SaveManager.Options[idx] then SaveManager.Options[idx]:SetValue(data.value) end end,
    },
    ColorPicker = {
        Save = function(idx, obj) return { type="ColorPicker", idx=idx, value=obj.Value:ToHex(), transparency=obj.Transparency } end,
        Load = function(idx, data)
            if SaveManager.Options[idx] then
                local ok, col = pcall(Color3.fromHex, data.value)
                if ok then SaveManager.Options[idx]:SetValueRGB(col, data.transparency or 0) end
            end
        end,
    },
    KeyPicker = {
        Save = function(idx, obj) return { type="KeyPicker", idx=idx, key=obj.Value, mode=obj.Mode } end,
        Load = function(idx, data) if SaveManager.Options[idx] then SaveManager.Options[idx]:SetValue({ data.key, data.mode }) end end,
    },
}

function SaveManager:SetLibrary(lib)
    self.Library = lib
    -- pull the live Toggles/Options tables out of the library
    self.Toggles = (getgenv and getgenv().Toggles) or lib.Toggles or {}
    self.Options = (getgenv and getgenv().Options) or lib.Options or {}
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    ensureFolder(folder)
end

function SaveManager:SetIgnoreIndexes(list)
    for _, key in next, list do self.Ignore[key] = true end
end

function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({
        "LW_Theme", "LW_Accent", "LW_Watermark", "LW_Keybinds",
        "LW_CfgName", "LW_CfgList",
    })
end

local function path(self, name) return self.Folder .. "/" .. name .. ".json" end

-- ── Core save/load ──────────────────────────────────────
function SaveManager:Save(name)
    if not name or name == "" then return false, "no config name" end
    local payload = { objects = {} }

    for idx, obj in next, self.Toggles do
        if not self.Ignore[idx] and self.Parser.Toggle then
            table.insert(payload.objects, self.Parser.Toggle.Save(idx, obj))
        end
    end
    for idx, obj in next, self.Options do
        if not self.Ignore[idx] then
            local p = self.Parser[obj.Type]
            if p then table.insert(payload.objects, p.Save(idx, obj)) end
        end
    end

    local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
    if not ok then return false, "encode failed" end

    if hasFS then
        local w = pcall(writefile, path(self, name), encoded)
        if not w then return false, "write failed" end
    else
        memStore[name] = encoded
    end
    return true
end

function SaveManager:Load(name)
    if not name or name == "" then return false, "no config name" end
    local contents
    if hasFS then
        if not isfile(path(self, name)) then return false, "config does not exist" end
        local ok, c = pcall(readfile, path(self, name))
        if not ok then return false, "read failed" end
        contents = c
    else
        contents = memStore[name]
        if not contents then return false, "config does not exist" end
    end

    local ok, decoded = pcall(function() return HttpService:JSONDecode(contents) end)
    if not ok then return false, "decode failed" end

    for _, item in next, decoded.objects do
        local p = self.Parser[item.type]
        if p then pcall(p.Load, item.idx, item) end
    end
    return true
end

function SaveManager:Delete(name)
    if hasFS and typeof(delfile)=="function" then
        pcall(delfile, path(self, name))
    else
        memStore[name] = nil
    end
    return true
end

function SaveManager:Refresh()
    local out = {}
    if hasFS then
        local ok, files = pcall(listfiles, self.Folder)
        if ok and files then
            for _, f in next, files do
                local nm = tostring(f):match("([^/\\]+)%.json$")
                if nm and nm ~= "_autoload" then table.insert(out, nm) end
            end
        end
    else
        for k in next, memStore do
            if k ~= "_autoload" then table.insert(out, k) end
        end
    end
    return out
end

-- ── Autoload ────────────────────────────────────────────
function SaveManager:SetAutoload(name)
    if hasFS then
        pcall(writefile, self.Folder .. "/_autoload.txt", name)
    else
        memStore["_autoload"] = name
    end
end

function SaveManager:GetAutoload()
    if hasFS then
        if isfile(self.Folder .. "/_autoload.txt") then
            local ok, c = pcall(readfile, self.Folder .. "/_autoload.txt")
            if ok then return c end
        end
    else
        return memStore["_autoload"]
    end
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoload()
    if name then
        local ok, err = self:Load(name)
        if self.Library then
            if ok then self.Library:Notify("Autoloaded config: " .. name, 3)
            else self.Library:Notify("Autoload failed: " .. tostring(err), 3) end
        end
    end
end

-- ── UI builder ──────────────────────────────────────────
function SaveManager:BuildConfigSection(tab)
    assert(self.Library, "SaveManager:SetLibrary(lib) must be called first")
    local box = tab:AddRightGroupbox("Configuration")

    local nameInput = box:AddInput("LW_CfgName", {
        Text = "Config Name", Placeholder = "my_config", Finished = true,
    })

    local listDD = box:AddDropdown("LW_CfgList", {
        Text = "Saved Configs", Values = self:Refresh(), AllowNull = true, Default = nil,
    })

    box:AddButton({ Text = "Create / Save", Func = function()
        local ok, err = self:Save(nameInput.Value)
        if ok then self.Library:Notify("Saved '"..nameInput.Value.."'", 3)
        else self.Library:Notify("Save failed: "..tostring(err), 3) end
        listDD:SetValues(self:Refresh())
    end })

    box:AddButton({ Text = "Load", Func = function()
        local ok, err = self:Load(listDD.Value)
        if ok then self.Library:Notify("Loaded '"..tostring(listDD.Value).."'", 3)
        else self.Library:Notify("Load failed: "..tostring(err), 3) end
    end })

    box:AddButton({ Text = "Refresh List", Func = function()
        listDD:SetValues(self:Refresh())
        self.Library:Notify("Config list refreshed", 2)
    end })

    box:AddButton({ Text = "Set as Autoload", Func = function()
        if listDD.Value then
            self:SetAutoload(listDD.Value)
            self.Library:Notify("Autoload set to '"..listDD.Value.."'", 3)
        end
    end })

    box:AddButton({ Text = "Delete", DoubleClick = true, Func = function()
        if listDD.Value then
            self:Delete(listDD.Value)
            listDD:SetValues(self:Refresh())
            self.Library:Notify("Deleted config", 3)
        end
    end })

    return box
end

return SaveManager

--[[
    LUMINWARE — ThemeManager v2.0
    Standalone theme system for the acrylic UI library.

    USAGE:
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder("Luminware")
        ThemeManager:BuildSection(settingsTab)
        ThemeManager:LoadDefault()
]]

local ThemeManager = { Library = nil, Folder = "Luminware" }

local HttpService = game:GetService("HttpService")
local hasFS = (typeof(writefile)=="function") and (typeof(readfile)=="function")

local function ensureFolder(f)
    if not hasFS then return end
    pcall(function()
        if typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(f) then
            makefolder(f)
        end
    end)
end

function ThemeManager:SetLibrary(lib) self.Library = lib end
function ThemeManager:SetFolder(f) self.Folder = f; ensureFolder(f) end

function ThemeManager:SaveDefault(themeName)
    local data = HttpService:JSONEncode({ theme = themeName })
    if hasFS then pcall(writefile, self.Folder.."/_theme.json", data)
    else self._mem = data end
end

function ThemeManager:LoadDefault()
    local contents
    if hasFS and typeof(isfile)=="function" and isfile(self.Folder.."/_theme.json") then
        local ok,c = pcall(readfile, self.Folder.."/_theme.json")
        if ok then contents = c end
    else contents = self._mem end
    if not contents then return end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, contents)
    if ok and data and data.theme then
        if self.Library then self.Library:SetTheme(data.theme) end
    end
end

function ThemeManager:BuildSection(tab)
    assert(self.Library, "Call ThemeManager:SetLibrary first")
    local L = self.Library
    local sec = tab:AddSection("Appearance")

    -- Theme picker dropdown
    sec:AddDropdown("LW_Theme", {
        Label  = "Color Theme",
        Values = { "FROST","VENOM","BLOOD","EMBER","ACID","GHOST" },
        Default = "FROST",
        Callback = function(v)
            L:SetTheme(v)
            L:Notify({ Title = "Theme changed", Body = v, Duration = 2 })
        end,
    })

    -- Custom accent color picker
    sec:AddColorPicker("LW_Accent", {
        Title    = "Custom Accent",
        Default  = L.Accent,
        Callback = function(col)
            L.Accent     = col
            if typeof(L.GetDarkerColor) == "function" then
                L.AccentDark = L:GetDarkerColor(col)
            end
            for _, entry in next, L.Registry do
                if entry.key == "Accent" and entry.inst and entry.inst.Parent then
                    pcall(function() entry.inst[entry.prop] = col end)
                end
            end
        end,
    })

    -- Glow toggle
    sec:AddToggle("LW_Glow", {
        Label   = "Window Glow",
        Default = true,
        Callback = function(v)
            if L.SetGlowEnabled then L:SetGlowEnabled(v) end
        end,
    })

    -- Save as default
    sec:AddButton({
        Label    = "Save as Default",
        Action   = "Save",
        Callback = function()
            local tname = L._currentTheme or "FROST"
            self:SaveDefault(tname)
            L:Notify({ Title = "Theme saved", Body = tname.." set as default", Duration = 3 })
        end,
    })

    return sec
end

-- Shortcut
function ThemeManager:ApplyToTab(tab) return self:BuildSection(tab) end

return ThemeManager
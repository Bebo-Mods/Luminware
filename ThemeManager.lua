local ThemeManager = {
    Folder  = "Luminware";
    Library = nil;
    BuiltInThemes = {
        VENOM = Color3.fromRGB(168, 85,  247);
        FROST = Color3.fromRGB(0,   207, 255);
        ACID  = Color3.fromRGB(200, 255, 0  );
        BLOOD = Color3.fromRGB(255, 45,  45 );
        GHOST = Color3.fromRGB(224, 224, 224);
        EMBER = Color3.fromRGB(255, 140, 0  );
    };
}

local hasFS = (typeof(writefile)=="function") and (typeof(readfile)=="function")
    and (typeof(isfile)=="function")
local HttpService = game:GetService("HttpService")
local memTheme = nil

local function ensureFolder(path)
    if not hasFS then return end
    pcall(function()
        if typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(path) then
            makefolder(path)
        end
    end)
end

function ThemeManager:SetLibrary(lib)
    self.Library = lib
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    ensureFolder(folder)
end

-- Ordered theme name list for dropdowns
function ThemeManager:GetThemeList()
    return { "VENOM", "FROST", "ACID", "BLOOD", "GHOST", "EMBER" }
end

function ThemeManager:ApplyTheme(nameOrColor)
    if self.Library and self.Library.SetTheme then
        self.Library:SetTheme(nameOrColor)
    end
end

-- ── Persist the chosen accent as the default ────────────
local function themePath(self) return self.Folder .. "/_theme.json" end

function ThemeManager:SaveDefault(color)
    local data = { hex = color:ToHex() }
    local encoded = HttpService:JSONEncode(data)
    if hasFS then
        pcall(writefile, themePath(self), encoded)
    else
        memTheme = encoded
    end
end

function ThemeManager:LoadDefault()
    local contents
    if hasFS then
        if isfile(themePath(self)) then
            local ok, c = pcall(readfile, themePath(self))
            if ok then contents = c end
        end
    else
        contents = memTheme
    end
    if not contents then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(contents) end)
    if ok and data.hex then
        local cok, col = pcall(Color3.fromHex, data.hex)
        if cok then self:ApplyTheme(col) end
    end
end

-- ── UI builder ──────────────────────────────────────────
function ThemeManager:ApplyToTab(tab)
    assert(self.Library, "ThemeManager:SetLibrary(lib) must be called first")
    local box = tab:AddLeftGroupbox("Theme")

    local themeDD = box:AddDropdown("LW_Theme", {
        Text    = "Accent Theme",
        Values  = self:GetThemeList(),
        Default = "VENOM",
        Callback = function(v) self:ApplyTheme(v) end,
    })

    local accentCP = box:AddLabel("Custom Accent"):AddColorPicker("LW_Accent", {
        Title   = "Custom Accent",
        Default = self.Library.AccentColor,
        Callback = function(col) self:ApplyTheme(col) end,
    })

    box:AddButton({ Text = "Set as Default", Func = function()
        self:SaveDefault(self.Library.AccentColor)
        self.Library:Notify("Saved as default theme", 3)
    end })

    box:AddToggle("LW_Watermark", {
        Text = "Show Watermark", Default = true,
        Callback = function(v) self.Library:SetWatermarkVisibility(v) end,
    })

    box:AddToggle("LW_Keybinds", {
        Text = "Show Keybind List", Default = true,
        Callback = function(v)
            if self.Library.KeybindFrame then self.Library.KeybindFrame.Visible = v end
        end,
    })

    return box
end

function ThemeManager:ApplyToGroupbox(box)
    assert(self.Library, "ThemeManager:SetLibrary(lib) must be called first")
    box:AddDropdown("LW_Theme", {
        Text = "Accent Theme", Values = self:GetThemeList(), Default = "VENOM",
        Callback = function(v) self:ApplyTheme(v) end,
    })
    box:AddLabel("Custom Accent"):AddColorPicker("LW_Accent", {
        Title = "Custom Accent", Default = self.Library.AccentColor,
        Callback = function(col) self:ApplyTheme(col) end,
    })
    return box
end

return ThemeManager

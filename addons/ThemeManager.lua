local TM={Library=nil,Folder="Luminware"}
local HS=game:GetService("HttpService")
local hasFS=(typeof(writefile)=="function") and (typeof(readfile)=="function")
local _mem
local function mkf(f) if not hasFS then return end
    pcall(function() if typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(f) then makefolder(f) end end) end
function TM:SetLibrary(l) self.Library=l end
function TM:SetFolder(f) self.Folder=f; mkf(f) end
function TM:SaveDefault(n)
    local d=HS:JSONEncode({theme=n})
    if hasFS then pcall(writefile,self.Folder.."/_theme.json",d) else _mem=d end
end
function TM:LoadDefault()
    local c; if hasFS and typeof(isfile)=="function" and isfile(self.Folder.."/_theme.json") then
        local ok,s=pcall(readfile,self.Folder.."/_theme.json"); if ok then c=s end
    else c=_mem end
    if not c then return end
    local ok,d=pcall(HS.JSONDecode,HS,c)
    if ok and d and d.theme and self.Library then self.Library:SetTheme(d.theme) end
end
-- BuildSection accepts either a Subtab (has .Left/.Right) or a Tab (same API)
function TM:BuildSection(subtab)
    local L=self.Library; assert(L,"SetLibrary first")
    local card=subtab.AddSection and subtab:AddSection("Appearance") or subtab.Left:AddCard("Appearance")
    card:AddDropdown("LW_Theme",{Label="Color Theme",
        Values={"FROST","VENOM","BLOOD","EMBER","ACID","GHOST"},Default=L._currentTheme or "FROST",
        Callback=function(v) L:SetTheme(v) end})
    card:AddColorPicker("LW_Accent",{Label="Custom Accent",Default=L.Accent,
        Callback=function(col) L.Accent=col
            for _,r in next,L.Registry do if r.key=="Accent" and r.inst and r.inst.Parent then
                pcall(function()r.inst[r.prop]=col end) end end end})
    card:AddButton({Label="Save as Default",Action="Save",
        Callback=function() self:SaveDefault(L._currentTheme or "FROST")
            L:Notify({Title="Theme saved",Duration=2}) end})
    return card
end
function TM:ApplyToTab(t) return self:BuildSection(t) end
return TM

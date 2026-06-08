local SM={Library=nil,Folder="Luminware/configs",Ignore={}}
local HS=game:GetService("HttpService")
local hasFS=(typeof(writefile)=="function") and (typeof(readfile)=="function")
    and (typeof(isfile)=="function") and (typeof(listfiles)=="function")
local _mem={}
local function mkf(f) if not hasFS then return end
    pcall(function() if typeof(makefolder)=="function" and typeof(isfolder)=="function" and not isfolder(f) then makefolder(f) end end) end
function SM:SetLibrary(l) self.Library=l end
function SM:SetFolder(f) self.Folder=f; mkf(f) end
function SM:SetIgnore(list) for _,k in next,list do self.Ignore[k]=true end end
function SM:IgnoreThemeSettings() self:SetIgnore({"LW_Theme","LW_Accent","LW_Glow"}) end
local function gT(sm) return (sm.Library and sm.Library.Toggles) or (typeof(getgenv)=="function" and getgenv().Toggles) or {} end
local function gO(sm) return (sm.Library and sm.Library.Options)  or (typeof(getgenv)=="function" and getgenv().Options)  or {} end
local function path(sm,n) return sm.Folder.."/"..n..".json" end
function SM:Gather()
    local d={t={},o={}}
    for i,t in next,gT(self) do if not self.Ignore[i] then d.t[i]=t.Value end end
    for i,o in next,gO(self) do if not self.Ignore[i] then
        if o.Type=="Toggle" then d.o[i]={k="b",v=o.Value}
        elseif o.Type=="Slider" then d.o[i]={k="n",v=o.Value}
        elseif o.Type=="Input" or o.Type=="Dropdown" then d.o[i]={k="s",v=o.Value}
        elseif o.Type=="KeyPicker" then d.o[i]={k="kp",key=o.Value,mode=o.Mode}
        elseif o.Type=="ColorPicker" then d.o[i]={k="c",hex=o.Value:ToHex(),t=o.Transparency or 0} end
    end end
    return d
end
function SM:Apply(data)
    for i,v in next,(data.t or {}) do local t=gT(self)[i]; if t then pcall(function()t:SetValue(v)end) end end
    for i,e in next,(data.o or {}) do local o=gO(self)[i]; if o then pcall(function()
        if e.k=="c" then local ok,c=pcall(Color3.fromHex,e.hex); if ok and o.SetValueRGB then o:SetValueRGB(c,e.t or 0) end
        elseif e.k=="kp" then if o.SetValue then o:SetValue({e.key,e.mode}) end
        else if o.SetValue then o:SetValue(e.v) end end
    end) end end
end
function SM:Save(n)
    if not n or n=="" then return false,"no name" end
    local ok,j=pcall(HS.JSONEncode,HS,self:Gather()); if not ok then return false,"encode" end
    if hasFS then pcall(writefile,path(self,n),j) else _mem[n]=j end; return true
end
function SM:Load(n)
    if not n or n=="" then return false,"no name" end
    local c; if hasFS then if not isfile(path(self,n)) then return false,"not found" end
        local ok,s=pcall(readfile,path(self,n)); if not ok then return false,"read" end; c=s
    else c=_mem[n] end
    if not c then return false,"not found" end
    local ok,d=pcall(HS.JSONDecode,HS,c); if not ok then return false,"decode" end
    self:Apply(d); return true
end
function SM:Delete(n)
    if hasFS and typeof(delfile)=="function" then pcall(delfile,path(self,n)) else _mem[n]=nil end; return true
end
function SM:List()
    local out={}
    if hasFS then local ok,f=pcall(listfiles,self.Folder); if ok and f then for _,x in next,f do
        local nm=tostring(x):match("([^/\\]+)%.json$"); if nm and nm~="_autoload" then table.insert(out,nm) end
    end end else for k in next,_mem do if k~="_autoload" then table.insert(out,k) end end end
    return out
end
function SM:SetAutoload(n) if hasFS then pcall(writefile,self.Folder.."/_autoload.txt",n) else _mem["_autoload"]=n end end
function SM:GetAutoload()
    if hasFS and typeof(isfile)=="function" and isfile(self.Folder.."/_autoload.txt") then
        local ok,c=pcall(readfile,self.Folder.."/_autoload.txt"); if ok then return c end end
    return _mem["_autoload"]
end
function SM:LoadAutoload()
    local n=self:GetAutoload(); if not n then return end
    local ok,err=self:Load(n); local L=self.Library
    if L then if ok then L:Notify({Title="Config loaded",Content=n,Duration=3})
    else L:Notify({Title="Autoload failed",Content=tostring(err),Duration=3}) end end
end
function SM:BuildSection(subtab)
    local L=self.Library; assert(L,"SetLibrary first")
    local card=subtab.Left:AddCard("Configuration")
    local nameIn=card:AddInput("LW_CfgName",{Label="Config Name",Placeholder="my_config",Finished=true})
    local listDD=card:AddDropdown("LW_CfgList",{Label="Saved Configs",Values=self:List(),Default=nil})
    card:AddButton({Label="Save Config",  Action="Save",    Callback=function()
        local ok,err=self:Save(nameIn.Value)
        if ok then L:Notify({Title="Saved",Content=nameIn.Value,Duration=3})
        else L:Notify({Title="Save failed",Content=tostring(err),Duration=3}) end
        if listDD then listDD:SetValues(self:List()) end end})
    card:AddButton({Label="Load Config",  Action="Load",    Callback=function()
        local ok,err=self:Load(listDD and listDD.Value)
        if ok then L:Notify({Title="Loaded",Content=tostring(listDD and listDD.Value),Duration=3})
        else L:Notify({Title="Load failed",Content=tostring(err),Duration=3}) end end})
    card:AddButton({Label="Set Autoload", Action="Set",     Callback=function()
        if listDD and listDD.Value then self:SetAutoload(listDD.Value)
            L:Notify({Title="Autoload set",Content=listDD.Value,Duration=3}) end end})
    card:AddButton({Label="Refresh List", Action="Refresh", Callback=function()
        if listDD then listDD:SetValues(self:List()) end end})
    card:AddButton({Label="Delete",       Action="Delete",  Callback=function()
        if listDD and listDD.Value then self:Delete(listDD.Value)
            if listDD then listDD:SetValues(self:List()) end
            L:Notify({Title="Deleted",Content=tostring(listDD and listDD.Value),Duration=3}) end end})
    return card
end
return SM

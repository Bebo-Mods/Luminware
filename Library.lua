-- Luminware Concept UI Library
-- A reusable Roblox UI library built directly from the frosted home-control concept.

local TS=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")

local Player=Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse=Player:GetMouse()
local Parent=Player:WaitForChild("PlayerGui")
pcall(function() if typeof(gethui)=="function" then Parent=gethui() end end)

local old=Parent:FindFirstChild("LuminwareConcept")
if old then old:Destroy() end

local Screen=Instance.new("ScreenGui")
Screen.Name="LuminwareConcept"
Screen.IgnoreGuiInset=true
Screen.ResetOnSpawn=false
Screen.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
Screen.Parent=Parent

local L={
    Version="3.0.0",
    Options={},
    Toggles={},
    Signals={},
    Windows={},
    Registry={},
    Popups={},
    OnUnloadCallbacks={},
    Unloaded=false,
    Theme="Concept",
    Colors={
        Accent=Color3.fromRGB(35,184,241),
        Panel=Color3.fromRGB(45,43,39),
        Rail=Color3.fromRGB(117,115,108),
        Card=Color3.fromRGB(111,109,103),
        Control=Color3.fromRGB(140,139,133),
        Text=Color3.fromRGB(246,246,244),
        Muted=Color3.fromRGB(190,189,184),
        Dark=Color3.fromRGB(25,24,21),
        White=Color3.fromRGB(250,250,248),
    },
    Themes={
        Concept={Accent=Color3.fromRGB(35,184,241),Panel=Color3.fromRGB(45,43,39),Card=Color3.fromRGB(111,109,103),Rail=Color3.fromRGB(117,115,108),Control=Color3.fromRGB(140,139,133),Text=Color3.fromRGB(246,246,244),Muted=Color3.fromRGB(190,189,184),Dark=Color3.fromRGB(25,24,21),White=Color3.fromRGB(250,250,248)},
        Warm={Accent=Color3.fromRGB(235,174,92),Panel=Color3.fromRGB(52,45,38),Card=Color3.fromRGB(119,105,91),Rail=Color3.fromRGB(124,111,98),Control=Color3.fromRGB(148,132,113),Text=Color3.fromRGB(255,248,238),Muted=Color3.fromRGB(205,190,173),Dark=Color3.fromRGB(31,25,20),White=Color3.fromRGB(255,251,244)},
        Plum={Accent=Color3.fromRGB(178,118,235),Panel=Color3.fromRGB(44,38,49),Card=Color3.fromRGB(101,89,108),Rail=Color3.fromRGB(106,94,112),Control=Color3.fromRGB(133,118,141),Text=Color3.fromRGB(250,246,252),Muted=Color3.fromRGB(198,187,204),Dark=Color3.fromRGB(27,23,30),White=Color3.fromRGB(253,250,255)},
    },
}

local function themeValue(key) return L.Colors[key] or key end
local function bind(object,properties)
    L.Registry[object]=properties
    for property,key in next,properties do object[property]=themeValue(key) end
    return object
end
local function unbind(object) L.Registry[object]=nil end
local function closePopups(except)
    for popup,owner in next,L.Popups do
        if popup~=except and popup.Parent then popup.Visible=false end
    end
end
local function ownPopup(popup,window)
    L.Popups[popup]=window
    popup.Destroying:Connect(function() L.Popups[popup]=nil end)
    return popup
end

local function new(class,props,parent)
    local object=Instance.new(class)
    for key,value in next,props or {} do
        if key~="Parent" then pcall(function() object[key]=value end) end
    end
    object.Parent=parent or props and props.Parent
    return object
end
local function corner(parent,r) return new("UICorner",{CornerRadius=UDim.new(0,r or 12)},parent) end
local function stroke(parent,t) return bind(new("UIStroke",{Color=L.Colors.White,Transparency=t or 0.78,Thickness=1},parent),{Color="White"}) end
local function pad(parent,l,r,t,b) return new("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0)},parent) end
local function tween(object,props,d)
    if object and object.Parent then TS:Create(object,TweenInfo.new(d or 0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play() end
end
local function callback(fn,...) if typeof(fn)=="function" then task.spawn(fn,...) end end
function L:SafeCallback(fn,...)
    if typeof(fn)~="function" then return end
    local args=table.pack(...)
    task.spawn(function()
        local ok,err=pcall(fn,table.unpack(args,1,args.n))
        if not ok then L:Notify({Title="Callback error",Content=tostring(err),Duration=6}) end
    end)
end
local function text(parent,value,size,color,bold)
    local label=new("TextLabel",{BackgroundTransparency=1,Font=bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        Text=value or "",TextColor3=color or L.Colors.Text,TextSize=size or 12,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},parent)
    if color==L.Colors.Muted then bind(label,{TextColor3="Muted"}) elseif color==nil or color==L.Colors.Text then bind(label,{TextColor3="Text"}) end
    return label
end
local register
local function drag(handle,target)
    local active,dragInput,start,startCenter=false
    register(handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            active=true;dragInput=i;start=i.Position;startCenter=target.AbsolutePosition+(target.AbsoluteSize/2)
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then active=false;dragInput=nil end end)
        end
    end))
    register(handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dragInput=i end
    end))
    register(UIS.InputChanged:Connect(function(i)
        if active and i==dragInput then
            local d=i.Position-start
            local viewport=workspace.CurrentCamera.ViewportSize
            local x=math.clamp(startCenter.X+d.X,-target.AbsoluteSize.X/2+20,viewport.X+target.AbsoluteSize.X/2-20)
            local y=math.clamp(startCenter.Y+d.Y,-target.AbsoluteSize.Y/2+20,viewport.Y+target.AbsoluteSize.Y/2-20)
            target.Position=UDim2.fromOffset(x,y)
        end
    end))
    register(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then active=false;dragInput=nil end end))
end
register=function(signal) table.insert(L.Signals,signal);return signal end

local Notifications=new("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),
    Size=UDim2.fromOffset(300,500),BackgroundTransparency=1,ZIndex=300},Screen)
new("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Right,
    Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},Notifications)
register(UIS.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        local point=input.Position
        for popup in next,L.Popups do
            if popup.Visible then
                local p,s=popup.AbsolutePosition,popup.AbsoluteSize
                if point.X>=p.X and point.X<=p.X+s.X and point.Y>=p.Y and point.Y<=p.Y+s.Y then return end
            end
        end
        closePopups()
    end
end))

local Watermark=bind(new("Frame",{Visible=false,Position=UDim2.fromOffset(12,12),Size=UDim2.fromOffset(240,30),
    BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.12,ZIndex=290},Screen),{BackgroundColor3="Card"})
corner(Watermark,13);stroke(Watermark,0.68)
local WatermarkText=text(Watermark,"Luminware",10,L.Colors.Text,true);WatermarkText.Position=UDim2.fromOffset(11,0);WatermarkText.Size=UDim2.new(1,-22,1,0)
function L:SetWatermark(value) WatermarkText.Text=tostring(value) end
function L:SetWatermarkVisibility(value) Watermark.Visible=not not value end
function L:OnUnload(fn) table.insert(self.OnUnloadCallbacks,fn) end

local KeybindFrame=bind(new("Frame",{Visible=false,Position=UDim2.fromOffset(12,52),Size=UDim2.fromOffset(220,0),
    AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.12,ZIndex=289},Screen),{BackgroundColor3="Card"})
corner(KeybindFrame,14);stroke(KeybindFrame,0.68);pad(KeybindFrame,10,10,8,8)
new("UIListLayout",{Padding=UDim.new(0,4)},KeybindFrame)
L.KeybindFrame=KeybindFrame

function L:Notify(info)
    info=type(info)=="string" and {Title=info} or info or {}
    local box=bind(new("Frame",{BackgroundColor3=self.Colors.Card,BackgroundTransparency=0.12,
        Size=UDim2.fromOffset(290,info.Content and 72 or 50),ZIndex=301},Notifications),{BackgroundColor3="Card"})
    corner(box,15);stroke(box,0.72)
    local title=text(box,info.Title or "Notification",12,self.Colors.Text,true)
    title.Position=UDim2.fromOffset(15,8);title.Size=UDim2.new(1,-30,0,20)
    if info.Content or info.SubContent then
        local body=text(box,info.Content or info.SubContent,10,self.Colors.Muted)
        body.Position=UDim2.fromOffset(15,29);body.Size=UDim2.new(1,-30,0,28);body.TextWrapped=true
    end
    box.BackgroundTransparency=1;tween(box,{BackgroundTransparency=0.12},0.2)
    task.delay(info.Duration or 4,function() tween(box,{BackgroundTransparency=1},0.2);task.wait(0.25);unbind(box);box:Destroy() end)
end

local function makeToggle(parent,initial,changed)
    local state=not not initial
    local track=new("TextButton",{AutoButtonColor=false,Text="",BackgroundColor3=state and L.Colors.Accent or L.Colors.Control,
        Size=UDim2.fromOffset(46,25)},parent);corner(track,13)
    local knob=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=L.Colors.White,
        Position=UDim2.fromOffset(state and 33.5 or 12.5,12.5),Size=UDim2.fromOffset(19,19)},track);corner(knob,10)
    local api={Value=state,Type="Toggle"}
    function api:SetValue(v)
        self.Value=not not v
        tween(track,{BackgroundColor3=self.Value and L.Colors.Accent or L.Colors.Control})
        tween(knob,{Position=UDim2.fromOffset(self.Value and 33.5 or 12.5,12.5)})
        callback(changed,self.Value);callback(self.Changed,self.Value)
    end
    function api:RefreshTheme() track.BackgroundColor3=self.Value and L.Colors.Accent or L.Colors.Control;knob.BackgroundColor3=L.Colors.White end
    function api:SetDisabled(v) self.Disabled=not not v;track.Active=not self.Disabled;track.BackgroundTransparency=self.Disabled and 0.55 or 0 end
    function api:SetVisible(v) track.Parent.Visible=not not v end
    function api:OnChanged(fn) self.Changed=fn;fn(self.Value) end
    track.Activated:Connect(function() if not api.Disabled then api:SetValue(not api.Value) end end)
    return api,track
end

local function finishOption(option,root)
    option.Root=root
    function option:SetVisible(value) root.Visible=not not value end
    function option:SetDisabled(value) self.Disabled=not not value;root.Active=not self.Disabled;root.BackgroundTransparency=self.Disabled and 0.45 or 1 end
    return option
end

local function createCard(column,title,window)
    local card=bind(new("Frame",{BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.27,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},column)
        ,{BackgroundColor3="Card"})
    card:SetAttribute("SearchText",title or "")
    corner(card,17);stroke(card,0.76);pad(card,14,14,12,14)
    local layout=new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},card)
    local api={Title=title or "",Root=card,Window=window}
    if title and title~="" then
        local header=text(card,title,13,L.Colors.Text,true);header.Size=UDim2.new(1,0,0,22);header.LayoutOrder=-100
    end
    local function row(height)
        return new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 38)},card)
    end
    local function rowTitle(r,info)
        local label=text(r,info.Title or info.Text or info.Label or "",12,L.Colors.Text)
        label.Size=UDim2.new(0.58,0,1,0)
        if info.Tooltip then
            local tip=ownPopup(bind(new("Frame",{Visible=false,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.08,
                Size=UDim2.fromOffset(220,36),ZIndex=230},Screen),{BackgroundColor3="Card"}),window)
            corner(tip,11);stroke(tip,0.68)
            local tipText=text(tip,info.Tooltip,10,L.Colors.Text);tipText.Position=UDim2.fromOffset(10,0);tipText.Size=UDim2.new(1,-20,1,0);tipText.TextWrapped=true
            label.Active=true
            label.MouseEnter:Connect(function() closePopups(tip);tip.Position=UDim2.fromOffset(Mouse.X+12,Mouse.Y+12);tip.Visible=true end)
            label.MouseLeave:Connect(function() tip.Visible=false end)
        end
        return label
    end

    function api:AddParagraph(info)
        info=type(info)=="string" and {Title=info} or info or {}
        local r=row(info.Content and 58 or 30)
        local a=text(r,info.Title or "Paragraph",12,L.Colors.Text,true);a.Size=UDim2.new(1,0,0,22)
        if info.Content then
            local b=text(r,info.Content,10,L.Colors.Muted);b.Position=UDim2.fromOffset(0,23);b.Size=UDim2.new(1,0,1,-23);b.TextWrapped=true;b.TextYAlignment=Enum.TextYAlignment.Top
        end
        return r
    end
    function api:AddLabel(value,wrap)
        local r=row(wrap and 54 or 28)
        local label=text(r,value,11,L.Colors.Text);label.Size=UDim2.fromScale(1,1);label.TextWrapped=not not wrap;label.TextYAlignment=Enum.TextYAlignment.Top
        local result={Root=r}
        function result:SetText(v) label.Text=tostring(v) end
        function result:AddColorPicker(index,info) return api:AddColorpicker(index,info) end
        function result:AddKeyPicker(index,info) return api:AddKeybind(index,info) end
        return result
    end
    function api:AddDivider()
        local r=row(9)
        local line=bind(new("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.new(1,0,0,1),BackgroundTransparency=0.72},r),{BackgroundColor3="Muted"})
        return line
    end
    function api:AddButton(info,second)
        info=type(info)=="string" and {Title=info,Callback=second} or info or {}
        local r=row(38);rowTitle(r,info)
        local b=bind(new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(92,30),
            AutoButtonColor=false,BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.25,
            Font=Enum.Font.Gotham,Text=info.Action or "Action",TextColor3=L.Colors.Text,TextSize=11},r),{BackgroundColor3="Control",TextColor3="Text"})
        corner(b,15);stroke(b,0.78)
        local clicks=0
        b.Activated:Connect(function()
            if info.DoubleClick then clicks+=1;if clicks<2 then task.delay(0.35,function()clicks=0 end);return end;clicks=0 end
            tween(b,{BackgroundColor3=L.Colors.Accent},0.08);task.delay(0.18,function()tween(b,{BackgroundColor3=L.Colors.Control})end);L:SafeCallback(info.Callback or info.Func)
        end)
        local result={Root=b}
        function result:AddButton(nextInfo,nextCallback) return api:AddButton(type(nextInfo)=="table" and nextInfo or {Title=nextInfo,Callback=nextCallback}) end
        return result
    end
    function api:AddToggle(index,info)
        info=info or {};local r=row(38);rowTitle(r,info)
        local option,track=makeToggle(r,info.Default,function(v) callback(info.Callback,v) end)
        finishOption(option,r)
        track.AnchorPoint=Vector2.new(1,0.5);track.Position=UDim2.new(1,0,0.5,0)
        L.Options[index]=option;L.Toggles[index]=option;return option
    end
    function api:AddSlider(index,info)
        info=info or {};local min,max=info.Min or 0,info.Max or 100
        local option={Value=info.Default or min,Min=min,Max=max,Type="Slider"}
        local r=row(45);rowTitle(r,info)
        finishOption(option,r)
        local value=text(r,"",10,L.Colors.Muted);value.AnchorPoint=Vector2.new(1,0);value.Position=UDim2.new(1,0,0,0);value.Size=UDim2.fromOffset(44,18);value.TextXAlignment=Enum.TextXAlignment.Right
        local track=new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,25),Size=UDim2.new(0.58,0,0,9),BackgroundColor3=L.Colors.Control},r);corner(track,5)
        local fill=new("Frame",{BackgroundColor3=L.Colors.Accent,Size=UDim2.fromScale(0,1)},track);corner(fill,5)
        local knob=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=L.Colors.White},track);corner(knob,7)
        function option:SetValue(v)
            local n=math.clamp(tonumber(v) or min,min,max)
            local rounding=info.Rounding or 0;n=tonumber(string.format("%."..rounding.."f",n))
            self.Value=n;local p=(n-min)/(max-min);fill.Size=UDim2.fromScale(p,1);knob.Position=UDim2.fromScale(p,0.5);value.Text=tostring(n)..(info.Suffix or "")
            callback(info.Callback,n);callback(self.Changed,n)
        end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() track.BackgroundColor3=L.Colors.Control;fill.BackgroundColor3=L.Colors.Accent;knob.BackgroundColor3=L.Colors.White end
        local down=false
        track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then down=true end end)
        register(UIS.InputChanged:Connect(function(i) if down and i.UserInputType==Enum.UserInputType.MouseMovement then option:SetValue(min+math.clamp((Mouse.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(max-min)) end end))
        register(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then down=false end end))
        option:SetValue(option.Value);L.Options[index]=option;return option
    end
    function api:AddDropdown(index,info)
        info=info or {};local values=info.Values or {};local initial=info.Default
        if info.SpecialType=="Player" then values={} for _,player in ipairs(Players:GetPlayers()) do table.insert(values,player.Name) end table.sort(values) end
        if not info.Multi and type(initial)=="number" then initial=values[initial] end
        if info.Multi then local m={} for _,v in ipairs(initial or {}) do m[v]=true end initial=m end
        local option={Value=initial,Values=values,Multi=not not info.Multi,Type="Dropdown"}
        local r=row(62);local t=rowTitle(r,info);t.Size=UDim2.new(1,0,0,20)
        local box=bind(new("TextButton",{AutoButtonColor=false,Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,31),
            BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,Font=Enum.Font.Gotham,Text="",TextColor3=L.Colors.Text,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},r),{BackgroundColor3="Control",TextColor3="Text"});corner(box,12);stroke(box,0.8);pad(box,11,11)
        finishOption(option,r)
        local pop=ownPopup(bind(new("ScrollingFrame",{Visible=false,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.08,
            Size=UDim2.fromOffset(180,0),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ScrollBarThickness=2,ScrollBarImageColor3=L.Colors.Accent,BorderSizePixel=0,ZIndex=200},Screen),{BackgroundColor3="Card",ScrollBarImageColor3="Accent"}),window);corner(pop,12);stroke(pop,0.7);pad(pop,5,5,5,5)
        local popLayout=new("UIListLayout",{Padding=UDim.new(0,3)},pop)
        local function display()
            if not option.Multi then return tostring(option.Value or "Select") end
            local out={} for _,v in ipairs(option.Values) do if option.Value[v] then table.insert(out,tostring(v)) end end
            return #out>0 and table.concat(out,", ") or "Select"
        end
        local function render()
            box.Text=display()
            for _,c in ipairs(pop:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _,v in ipairs(option.Values) do
                local selected=option.Multi and option.Value[v] or option.Value==v
                local item=new("TextButton",{AutoButtonColor=false,BackgroundColor3=selected and L.Colors.White or L.Colors.Control,
                    BackgroundTransparency=selected and 0 or 0.35,Size=UDim2.new(1,0,0,28),Font=Enum.Font.Gotham,Text=tostring(v),
                    TextColor3=selected and L.Colors.Dark or L.Colors.Text,TextSize=10,ZIndex=201},pop);corner(item,9)
                item.Activated:Connect(function()
                    if option.Multi then option.Value[v]=not option.Value[v] else option.Value=v;pop.Visible=false end
                    render();callback(info.Callback,option.Value);callback(option.Changed,option.Value)
                end)
            end
        end
        function option:SetValue(v) self.Value=v or (self.Multi and {} or nil);render();callback(info.Callback,self.Value);callback(self.Changed,self.Value) end
        function option:SetValues(v) self.Values=v or {};render() end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() box.BackgroundColor3=L.Colors.Control;pop.BackgroundColor3=L.Colors.Card;render() end
        box.Activated:Connect(function()
            local opening=not pop.Visible;closePopups(pop)
            local maxHeight=math.min(#option.Values*31+10,190)
            local x=math.clamp(box.AbsolutePosition.X,8,workspace.CurrentCamera.ViewportSize.X-box.AbsoluteSize.X-8)
            local y=math.clamp(box.AbsolutePosition.Y+35,8,workspace.CurrentCamera.ViewportSize.Y-maxHeight-8)
            pop.Position=UDim2.fromOffset(x,y);pop.Size=UDim2.fromOffset(box.AbsoluteSize.X,maxHeight);pop.Visible=opening
        end)
        render();L.Options[index]=option;return option
    end
    function api:AddInput(index,info)
        info=info or {};local option={Value=tostring(info.Default or ""),Type="Input"}
        local r=row(62);local t=rowTitle(r,info);t.Size=UDim2.new(1,0,0,20)
        finishOption(option,r)
        local box=bind(new("TextBox",{Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,31),BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,
            ClearTextOnFocus=false,Font=Enum.Font.Gotham,Text=option.Value,PlaceholderText=info.Placeholder or "",TextColor3=L.Colors.Text,
            PlaceholderColor3=L.Colors.Muted,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},r),{BackgroundColor3="Control",TextColor3="Text",PlaceholderColor3="Muted"});corner(box,12);stroke(box,0.8);pad(box,11,11)
        function option:SetValue(v) self.Value=tostring(v or "");box.Text=self.Value end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() box.BackgroundColor3=L.Colors.Control end
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if info.MaxLength and #box.Text>info.MaxLength then box.Text=box.Text:sub(1,info.MaxLength) end
            if info.Numeric and box.Text~="" and not tonumber(box.Text) then box.Text=option.Value else option.Value=box.Text;if not info.Finished then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end end
        end)
        box.FocusLost:Connect(function(enter) if info.Finished and enter then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end end)
        L.Options[index]=option;return option
    end
    function api:AddKeybind(index,info)
        info=info or {};local option={Value=info.Default or "None",Mode=info.Mode or "Toggle",Toggled=false,Type="KeyPicker"}
        local r=row(38);rowTitle(r,info)
        finishOption(option,r)
        local button=bind(new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(90,29),
            BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,Font=Enum.Font.Gotham,Text=option.Value,TextColor3=L.Colors.Text,TextSize=10},r),{BackgroundColor3="Control",TextColor3="Text"});corner(button,12);stroke(button,0.8)
        local picking=false
        local display
        if not info.NoUI then
            display=text(KeybindFrame,(info.Text or info.Title or index).." ["..option.Value.."]",10,L.Colors.Text)
            display.Size=UDim2.new(1,0,0,20)
        end
        local function name(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then return "MB1" elseif i.UserInputType==Enum.UserInputType.MouseButton2 then return "MB2" elseif i.UserInputType==Enum.UserInputType.Keyboard then return i.KeyCode.Name end end
        function option:SetValue(v,mode) self.Value=type(v)=="table" and v[1] or v;self.Mode=mode or (type(v)=="table" and v[2]) or self.Mode;button.Text=self.Value;if display then display.Text=(info.Text or info.Title or index).." ["..self.Value.."]" end;callback(info.ChangedCallback,self.Value);callback(self.Changed,self.Value) end
        function option:GetState() return self.Mode=="Always" or self.Toggled end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:OnClick(fn) self.Clicked=fn end
        function option:RefreshTheme() button.BackgroundColor3=L.Colors.Control end
        button.Activated:Connect(function() picking=true;button.Text="...";local c;c=UIS.InputBegan:Connect(function(i) local n=name(i);if n then picking=false;c:Disconnect();option:SetValue(n) end end) end)
        register(UIS.InputBegan:Connect(function(i,gp) if not gp and not picking and name(i)==option.Value then option.Toggled=option.Mode=="Toggle" and not option.Toggled or true;if display then display.TextColor3=option.Toggled and L.Colors.Accent or L.Colors.Text end;callback(info.Callback,option.Toggled);callback(option.Clicked,option.Toggled) end end))
        register(UIS.InputEnded:Connect(function(i) if option.Mode=="Hold" and name(i)==option.Value then option.Toggled=false;if display then display.TextColor3=L.Colors.Text end;callback(info.Callback,false) end end))
        L.Options[index]=option;return option
    end
    function api:AddColorpicker(index,info)
        info=info or {};local option={Value=info.Default or L.Colors.Accent,Transparency=info.Transparency or 0,Type="ColorPicker"}
        local r=row(38);rowTitle(r,info)
        finishOption(option,r)
        local swatch=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(46,25),Text="",BackgroundColor3=option.Value},r);corner(swatch,13);stroke(swatch,0.65)
        local hue,sat,val=Color3.toHSV(option.Value)
        local pop=ownPopup(bind(new("Frame",{Visible=false,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.04,Size=UDim2.fromOffset(240,250),ZIndex=200},Screen),{BackgroundColor3="Card"}),window);corner(pop,16);stroke(pop,0.6);pad(pop,12,12,12,12)
        local title=text(pop,info.Title or info.Text or "Color picker",12,L.Colors.Text,true);title.Size=UDim2.new(1,0,0,22)
        local sv=new("ImageLabel",{Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,-25,0,150),Image="rbxassetid://4155801252",BackgroundColor3=Color3.fromHSV(hue,1,1),ZIndex=201},pop);corner(sv,8)
        local svCursor=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(12,12),BackgroundColor3=L.Colors.White,ZIndex=202},sv);corner(svCursor,6);stroke(svCursor,0.1)
        local hueBar=new("Frame",{Position=UDim2.new(1,-17,0,30),Size=UDim2.fromOffset(17,150),ZIndex=201},pop);corner(hueBar,8)
        local hueKeys={} for i=0,10 do table.insert(hueKeys,ColorSequenceKeypoint.new(i/10,Color3.fromHSV(i/10,1,1))) end
        new("UIGradient",{Color=ColorSequence.new(hueKeys),Rotation=90},hueBar)
        local hueCursor=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,hue),Size=UDim2.fromOffset(21,5),BackgroundColor3=L.Colors.White,ZIndex=202},hueBar);corner(hueCursor,3)
        local hex=new("TextBox",{ClearTextOnFocus=false,Position=UDim2.fromOffset(0,190),BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.2,Size=UDim2.new(1,0,0,32),
            Font=Enum.Font.Gotham,Text="#"..option.Value:ToHex(),TextColor3=L.Colors.Text,TextSize=11,ZIndex=201},pop);corner(hex,10)
        local function render(fire)
            option.Value=Color3.fromHSV(hue,sat,val);swatch.BackgroundColor3=option.Value;sv.BackgroundColor3=Color3.fromHSV(hue,1,1)
            svCursor.Position=UDim2.fromScale(sat,1-val);hueCursor.Position=UDim2.fromScale(0.5,hue);hex.Text="#"..option.Value:ToHex()
            if fire then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end
        end
        function option:SetValueRGB(c,t) self.Transparency=t or self.Transparency;hue,sat,val=Color3.toHSV(c);render(true) end
        function option:SetValue(hsv,t)
            if typeof(hsv)=="Color3" then return self:SetValueRGB(hsv,t) end
            hue,sat,val=hsv[1],hsv[2],hsv[3];self.Transparency=t or self.Transparency;render(true)
        end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:RefreshTheme() pop.BackgroundColor3=L.Colors.Card end
        hex.FocusLost:Connect(function() local ok,c=pcall(Color3.fromHex,hex.Text);if ok then option:SetValueRGB(c) end end)
        local svDown,hueDown=false,false
        local function updateSV() sat=math.clamp((Mouse.X-sv.AbsolutePosition.X)/sv.AbsoluteSize.X,0,1);val=1-math.clamp((Mouse.Y-sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y,0,1);render(true) end
        local function updateHue() hue=math.clamp((Mouse.Y-hueBar.AbsolutePosition.Y)/hueBar.AbsoluteSize.Y,0,1);render(true) end
        sv.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDown=true;updateSV() end end)
        hueBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hueDown=true;updateHue() end end)
        register(UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then if svDown then updateSV() elseif hueDown then updateHue() end end end))
        register(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDown=false;hueDown=false end end))
        swatch.Activated:Connect(function()
            local opening=not pop.Visible;closePopups(pop)
            pop.Position=UDim2.fromOffset(math.clamp(swatch.AbsolutePosition.X-194,8,workspace.CurrentCamera.ViewportSize.X-248),math.clamp(swatch.AbsolutePosition.Y+32,8,workspace.CurrentCamera.ViewportSize.Y-258));pop.Visible=opening
        end)
        render(false)
        L.Options[index]=option;return option
    end
    api.AddColorPicker=api.AddColorpicker
    api.AddKeyPicker=api.AddKeybind
    function api:SetVisible(value) card.Visible=not not value end
    function api:AddDependencyBox()
        local dep=createCard(card,"",window)
        dep.Root.BackgroundTransparency=1
        function dep:SetupDependencies(dependencies)
            local function update()
                local visible=true
                for _,dependency in ipairs(dependencies or {}) do
                    if dependency[1].Value~=dependency[2] then visible=false;break end
                end
                dep.Root.Visible=visible
            end
            for _,dependency in ipairs(dependencies or {}) do
                if dependency[1].OnChanged then dependency[1]:OnChanged(update) end
            end
            update()
        end
        return dep
    end
    return api
end

local function makeColumn(parent,x,w,window)
    local col=new("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(x,0,0,0),Size=UDim2.new(w,-6,1,0),
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=L.Colors.Accent},parent)
    new("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},col)
    return {Root=col,AddCard=function(_,title)return createCard(col,title,window)end}
end

function L:CreateWindow(config)
    config=config or {};local width=config.Size and config.Size.X.Offset or 900;local height=config.Size and config.Size.Y.Offset or 600
    local window={Tabs={},TabOrder={}}
    local root=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(width,height),BackgroundTransparency=1},Screen)
    local scale=new("UIScale",{Scale=1},root)
    local panel=bind(new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=self.Colors.Panel,BackgroundTransparency=0.17,ClipsDescendants=true},root),{BackgroundColor3="Panel"});corner(panel,28);stroke(panel,0.78)
    local rail=bind(new("Frame",{Position=UDim2.fromOffset(14,14),Size=UDim2.new(0,72,1,-28),BackgroundColor3=self.Colors.Rail,BackgroundTransparency=0.28},panel),{BackgroundColor3="Rail"});corner(rail,22);stroke(rail,0.8)
    local nav=new("Frame",{Position=UDim2.fromOffset(10,12),Size=UDim2.new(1,-20,1,-70),BackgroundTransparency=1},rail)
    new("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},nav)
    local power=bind(new("TextButton",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-12),Size=UDim2.fromOffset(42,36),BackgroundTransparency=1,
        Font=Enum.Font.GothamMedium,Text="O",TextColor3=self.Colors.Text,TextSize=16},rail),{TextColor3="Text"})
    local content=new("Frame",{Position=UDim2.fromOffset(104,14),Size=UDim2.new(1,-118,1,-28),BackgroundTransparency=1},panel)
    local header=new("Frame",{Size=UDim2.new(1,0,0,54),BackgroundTransparency=1},content)
    local dragSurface=new("TextButton",{AutoButtonColor=false,Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1},header);drag(dragSurface,root)
    local subtabs=new("Frame",{Position=UDim2.fromOffset(0,4),Size=UDim2.new(1,-245,0,42),BackgroundTransparency=1,ZIndex=2},header)
    local subLayout=new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},subtabs)
    local search=bind(new("TextBox",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-68,0,5),Size=UDim2.fromOffset(170,35),BackgroundColor3=self.Colors.Dark,BackgroundTransparency=0.5,
        ClearTextOnFocus=false,Font=Enum.Font.Gotham,PlaceholderText="Q  Search",PlaceholderColor3=self.Colors.Muted,Text="",TextColor3=self.Colors.Text,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2},header),{BackgroundColor3="Dark",PlaceholderColor3="Muted",TextColor3="Text"});corner(search,16);pad(search,13,8)
    local initial=(Player.DisplayName~="" and Player.DisplayName or Player.Name):sub(1,1):upper()
    local initialLabel=text(header,initial,12,self.Colors.Text,true);initialLabel.AnchorPoint=Vector2.new(1,0);initialLabel.Position=UDim2.new(1,-38,0,5);initialLabel.Size=UDim2.fromOffset(25,35);initialLabel.TextXAlignment=Enum.TextXAlignment.Center;initialLabel.ZIndex=2
    local avatar=new("ImageLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,6),Size=UDim2.fromOffset(32,32),BackgroundColor3=self.Colors.White,
        Image=("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(Player.UserId),ZIndex=2},header);corner(avatar,16);stroke(avatar,0.25)
    local pages=new("Frame",{Position=UDim2.fromOffset(0,56),Size=UDim2.new(1,0,1,-56),BackgroundTransparency=1,ClipsDescendants=true},content)
    local function resize()
        local v=workspace.CurrentCamera.ViewportSize;scale.Scale=math.min(1,v.X/(width+50),v.Y/(height+50))
    end
    resize();register(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize))
    power.Activated:Connect(function() self:Unload() end)
    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q=search.Text:lower()
        for _,tab in ipairs(window.TabOrder) do for _,sub in ipairs(tab.SubtabOrder) do
            for _,col in ipairs({sub.Left.Root,sub.Right.Root}) do for _,card in ipairs(col:GetChildren()) do
                if card:IsA("Frame") then card.Visible=q=="" or tostring(card:GetAttribute("SearchText") or ""):lower():find(q,1,true)~=nil end
            end end
        end end
    end)

    function window:AddTab(info)
        info=type(info)=="string" and {Title=info} or info or {}
        local title=info.Title or info.Name or "Tab";local tab={Title=title,Subtabs={},SubtabOrder={}}
        local button=bind(new("TextButton",{AutoButtonColor=false,Size=UDim2.fromOffset(46,40),BackgroundColor3=L.Colors.Dark,BackgroundTransparency=1,
            Font=Enum.Font.GothamMedium,Text=info.IconText or title:sub(1,1):upper(),TextColor3=L.Colors.Text,TextSize=13},nav),{BackgroundColor3="Dark",TextColor3="Text"});corner(button,13)
        function tab:Show()
            closePopups()
            for _,other in ipairs(window.TabOrder) do other:Hide() end
            self.Active=true;tween(button,{BackgroundTransparency=0.38})
            for _,sub in ipairs(self.SubtabOrder) do sub.Button.Visible=true end
            if self.SubtabOrder[1] then self.SubtabOrder[1]:Show() end
        end
        function tab:Hide()
            closePopups()
            self.Active=false;tween(button,{BackgroundTransparency=1})
            for _,s in ipairs(self.SubtabOrder) do s:Hide();s.Button.Visible=false end
        end
        button.Activated:Connect(function() tab:Show() end)
        function tab:AddSubtab(name)
            local sub={Title=name,Tab=tab}
            local sb=new("TextButton",{AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromOffset(math.max(76,#name*8+20),38),
                Font=Enum.Font.Gotham,Text=name,TextColor3=L.Colors.Muted,TextSize=12,Visible=tab.Active},subtabs)
            local line=new("Frame",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,0),Size=UDim2.new(1,-18,0,1),BackgroundColor3=L.Colors.White,BackgroundTransparency=1},sb)
            local page=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},pages)
            sub.Root=page;sub.Button=sb;sub.Left=makeColumn(page,0,0.5,window);sub.Right=makeColumn(page,0.5,0.5,window)
            function sub:Show()
                for _,other in ipairs(tab.SubtabOrder) do other:Hide() end
                page.Visible=true;self.Active=true;tween(sb,{TextColor3=L.Colors.Text});tween(line,{BackgroundTransparency=0})
            end
            function sub:Hide() page.Visible=false;self.Active=false;tween(sb,{TextColor3=L.Colors.Muted});tween(line,{BackgroundTransparency=1}) end
            sb.Activated:Connect(function() sub:Show() end)
            tab.Subtabs[name]=sub;table.insert(tab.SubtabOrder,sub)
            if #tab.SubtabOrder==1 and tab.Active then sub:Show() end
            return sub
        end
        function tab:AddSection(title)
            if not self.DefaultSubtab then self.DefaultSubtab=self:AddSubtab("Main");self.NextSide="Left" end
            local side=self.NextSide;self.NextSide=side=="Left" and "Right" or "Left"
            return self.DefaultSubtab[side]:AddCard(title)
        end
        function tab:AddLeftGroupbox(title)
            if not self.DefaultSubtab then self.DefaultSubtab=self:AddSubtab("Main") end
            return self.DefaultSubtab.Left:AddCard(title)
        end
        function tab:AddRightGroupbox(title)
            if not self.DefaultSubtab then self.DefaultSubtab=self:AddSubtab("Main") end
            return self.DefaultSubtab.Right:AddCard(title)
        end
        function tab:AddGroupbox(info)
            info=type(info)=="string" and {Name=info,Side=1} or info or {}
            return (info.Side==2 and self:AddRightGroupbox(info.Name or info.Title) or self:AddLeftGroupbox(info.Name or info.Title))
        end
        local function addTabbox(side)
            if not tab.DefaultSubtab then tab.DefaultSubtab=tab:AddSubtab("Main") end
            local column=tab.DefaultSubtab[side].Root
            local container=bind(new("Frame",{BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.27,
                Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},column),{BackgroundColor3="Card"})
            corner(container,17);stroke(container,0.76);pad(container,10,10,10,10)
            local tabsRow=new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,32)},container)
            new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)},tabsRow)
            local body=new("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,38),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},container)
            local box={Tabs={},Order={}}
            function box:AddTab(name)
                local button=bind(new("TextButton",{AutoButtonColor=false,Size=UDim2.fromOffset(math.max(68,#name*7+18),30),
                    BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.45,Font=Enum.Font.Gotham,Text=name,TextColor3=L.Colors.Muted,TextSize=10},tabsRow),{BackgroundColor3="Control",TextColor3="Muted"});corner(button,11)
                local holder=new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Visible=false},body)
                local card=createCard(holder,"",window);card.Root.BackgroundTransparency=1
                function card:Show()
                    for _,entry in ipairs(box.Order) do entry.Card.Root.Parent.Visible=false;tween(entry.Button,{BackgroundTransparency=0.45,TextColor3=L.Colors.Muted}) end
                    holder.Visible=true;tween(button,{BackgroundTransparency=0.12,TextColor3=L.Colors.Text})
                end
                button.Activated:Connect(function()card:Show()end)
                self.Tabs[name]=card;table.insert(self.Order,{Card=card,Button=button})
                if #self.Order==1 then card:Show() end
                return card
            end
            return box
        end
        function tab:AddLeftTabbox() return addTabbox("Left") end
        function tab:AddRightTabbox() return addTabbox("Right") end
        local methods={"AddParagraph","AddLabel","AddDivider","AddButton","AddToggle","AddSlider","AddDropdown","AddInput","AddKeybind","AddKeyPicker","AddColorpicker","AddColorPicker","AddDependencyBox"}
        for _,method in ipairs(methods) do tab[method]=function(self,...) if not self.DefaultCard then self.DefaultCard=self:AddSection("") end return self.DefaultCard[method](self.DefaultCard,...) end end
        window.Tabs[title]=tab;table.insert(window.TabOrder,tab);if #window.TabOrder==1 then tab:Show() end;return tab
    end
    function window:SelectTab(which) local tab=type(which)=="number" and self.TabOrder[which] or self.Tabs[which];if tab then tab:Show() end end
    function window:Toggle() closePopups();root.Visible=not root.Visible end
    function window:Minimize() root.Visible=false end
    function window:Destroy()
        closePopups()
        for popup,owner in next,L.Popups do if owner==window then unbind(popup);popup:Destroy() end end
        root:Destroy()
    end
    function window:Dialog(info)
        info=info or {};closePopups();local shade=ownPopup(new("TextButton",{AutoButtonColor=false,Text="",BackgroundColor3=Color3.new(),BackgroundTransparency=0.45,Size=UDim2.fromScale(1,1),ZIndex=250},Screen),window)
        local box=bind(new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(390,190),BackgroundColor3=L.Colors.Card,ZIndex=251},shade),{BackgroundColor3="Card"});corner(box,20);stroke(box,0.65);pad(box,18,18,16,16)
        local ttl=text(box,info.Title or "Dialog",15,L.Colors.Text,true);ttl.Size=UDim2.new(1,0,0,24)
        local body=text(box,info.Content or "",11,L.Colors.Muted);body.Position=UDim2.fromOffset(0,34);body.Size=UDim2.new(1,0,0,75);body.TextWrapped=true;body.TextYAlignment=Enum.TextYAlignment.Top
        local buttons=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},box)
        new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,8)},buttons)
        for _,b in ipairs(info.Buttons or {{Title="Okay"}}) do local x=bind(new("TextButton",{Size=UDim2.fromOffset(92,32),BackgroundColor3=L.Colors.Control,Font=Enum.Font.Gotham,Text=b.Title or "Okay",TextColor3=L.Colors.Text,TextSize=11,ZIndex=252},buttons),{BackgroundColor3="Control",TextColor3="Text"});corner(x,14);x.Activated:Connect(function()callback(b.Callback);shade:Destroy()end) end
        shade.Activated:Connect(function() shade:Destroy() end)
    end
    window.Root=root;window.Panel=panel;self.Window=window;table.insert(self.Windows,window)
    if config.Acrylic~=false then self:ToggleAcrylic(true) end
    return window
end

function L:SetTheme(name)
    local theme=type(name)=="table" and name or self.Themes[name]
    if not theme then return end
    if type(name)=="string" then self.Theme=name end
    for key,value in next,theme do self.Colors[key]=value end
    self:UpdateColorsUsingRegistry()
    self:Notify({Title="Theme changed",Content="Applied "..tostring(type(name)=="string" and name or "custom theme"),Duration=3})
end
function L:UpdateColorsUsingRegistry()
    for object,properties in next,self.Registry do
        if object.Parent then for property,key in next,properties do pcall(function()object[property]=themeValue(key)end) end else self.Registry[object]=nil end
    end
    for _,option in next,self.Options do if option.RefreshTheme then option:RefreshTheme() end end
end
function L:ToggleAcrylic(value)
    local blur=Lighting:FindFirstChild("LuminwareBlur") or new("BlurEffect",{Name="LuminwareBlur",Size=0},Lighting)
    tween(blur,{Size=value==false and 0 or 8},0.2)
end
function L:ToggleTransparency(value) for _,w in ipairs(self.Windows) do tween(w.Panel,{BackgroundTransparency=value and 0.35 or 0.17}) end end
function L:AttemptSave() if self.SaveManager and self.SaveManager.Save then pcall(function()self.SaveManager:Save()end) end end
function L:Destroy() self:Unload() end
function L:Unload()
    self.Unloaded=true
    for _,fn in ipairs(self.OnUnloadCallbacks) do pcall(fn) end
    for _,s in ipairs(self.Signals) do pcall(function()s:Disconnect()end) end
    local blur=Lighting:FindFirstChild("LuminwareBlur");if blur then blur:Destroy() end
    Screen:Destroy()
    pcall(function() if typeof(getgenv)=="function" then getgenv().Options=nil;getgenv().Toggles=nil end end)
end

pcall(function() if typeof(getgenv)=="function" then getgenv().Options=L.Options;getgenv().Toggles=L.Toggles end end)
return L

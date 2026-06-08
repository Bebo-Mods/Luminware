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
Screen.ZIndexBehavior=Enum.ZIndexBehavior.Global
Screen.Parent=Parent

local L={
    Version="2.0.0",
    Options={},
    Toggles={},
    Signals={},
    Windows={},
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
        Concept={Accent=Color3.fromRGB(35,184,241),Panel=Color3.fromRGB(45,43,39),Card=Color3.fromRGB(111,109,103),Rail=Color3.fromRGB(117,115,108)},
        Warm={Accent=Color3.fromRGB(235,174,92),Panel=Color3.fromRGB(52,45,38),Card=Color3.fromRGB(119,105,91),Rail=Color3.fromRGB(124,111,98)},
        Plum={Accent=Color3.fromRGB(178,118,235),Panel=Color3.fromRGB(44,38,49),Card=Color3.fromRGB(101,89,108),Rail=Color3.fromRGB(106,94,112)},
    },
}

local function new(class,props,parent)
    local object=Instance.new(class)
    for key,value in next,props or {} do
        if key~="Parent" then pcall(function() object[key]=value end) end
    end
    object.Parent=parent or props and props.Parent
    return object
end
local function corner(parent,r) return new("UICorner",{CornerRadius=UDim.new(0,r or 12)},parent) end
local function stroke(parent,t) return new("UIStroke",{Color=L.Colors.White,Transparency=t or 0.78,Thickness=1},parent) end
local function pad(parent,l,r,t,b) return new("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0)},parent) end
local function tween(object,props,d)
    if object and object.Parent then TS:Create(object,TweenInfo.new(d or 0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play() end
end
local function callback(fn,...) if typeof(fn)=="function" then task.spawn(fn,...) end end
local function text(parent,value,size,color,bold)
    return new("TextLabel",{BackgroundTransparency=1,Font=bold and Enum.Font.GothamMedium or Enum.Font.Gotham,
        Text=value or "",TextColor3=color or L.Colors.Text,TextSize=size or 12,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},parent)
end
local function drag(handle,target)
    local active,start,pos=false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then active=true;start=i.Position;pos=target.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if active and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-start
            target.Position=UDim2.new(pos.X.Scale,pos.X.Offset+d.X,pos.Y.Scale,pos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then active=false end end)
end
local function register(signal) table.insert(L.Signals,signal);return signal end

local Notifications=new("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-18),
    Size=UDim2.fromOffset(300,500),BackgroundTransparency=1,ZIndex=300},Screen)
new("UIListLayout",{VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Right,
    Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},Notifications)

function L:Notify(info)
    info=type(info)=="string" and {Title=info} or info or {}
    local box=new("Frame",{BackgroundColor3=self.Colors.Card,BackgroundTransparency=0.12,
        Size=UDim2.fromOffset(290,info.Content and 72 or 50),ZIndex=301},Notifications)
    corner(box,15);stroke(box,0.72)
    local title=text(box,info.Title or "Notification",12,self.Colors.Text,true)
    title.Position=UDim2.fromOffset(15,8);title.Size=UDim2.new(1,-30,0,20)
    if info.Content or info.SubContent then
        local body=text(box,info.Content or info.SubContent,10,self.Colors.Muted)
        body.Position=UDim2.fromOffset(15,29);body.Size=UDim2.new(1,-30,0,28);body.TextWrapped=true
    end
    box.BackgroundTransparency=1;tween(box,{BackgroundTransparency=0.12},0.2)
    task.delay(info.Duration or 4,function() tween(box,{BackgroundTransparency=1},0.2);task.wait(0.25);box:Destroy() end)
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
    function api:OnChanged(fn) self.Changed=fn;fn(self.Value) end
    track.Activated:Connect(function() api:SetValue(not api.Value) end)
    return api,track
end

local function createCard(column,title)
    local card=new("Frame",{BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.27,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},column)
    card:SetAttribute("SearchText",title or "")
    corner(card,17);stroke(card,0.76);pad(card,14,14,12,14)
    local layout=new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},card)
    local api={Title=title or "",Root=card}
    if title and title~="" then
        local header=text(card,title,13,L.Colors.Text,true);header.Size=UDim2.new(1,0,0,22);header.LayoutOrder=-100
    end
    local function row(height)
        return new("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,height or 38)},card)
    end
    local function rowTitle(r,info)
        local label=text(r,info.Title or info.Label or "",12,L.Colors.Text)
        label.Size=UDim2.new(0.58,0,1,0)
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
    function api:AddButton(info)
        info=type(info)=="string" and {Title=info} or info or {}
        local r=row(38);rowTitle(r,info)
        local b=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(92,30),
            AutoButtonColor=false,BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.25,
            Font=Enum.Font.Gotham,Text=info.Action or "Action",TextColor3=L.Colors.Text,TextSize=11},r)
        corner(b,15);stroke(b,0.78)
        b.Activated:Connect(function() tween(b,{BackgroundColor3=L.Colors.Accent},0.08);task.delay(0.18,function()tween(b,{BackgroundColor3=L.Colors.Control})end);callback(info.Callback or info.Func) end)
        return b
    end
    function api:AddToggle(index,info)
        info=info or {};local r=row(38);rowTitle(r,info)
        local option,track=makeToggle(r,info.Default,function(v) callback(info.Callback,v) end)
        track.AnchorPoint=Vector2.new(1,0.5);track.Position=UDim2.new(1,0,0.5,0)
        L.Options[index]=option;L.Toggles[index]=option;return option
    end
    function api:AddSlider(index,info)
        info=info or {};local min,max=info.Min or 0,info.Max or 100
        local option={Value=info.Default or min,Min=min,Max=max,Type="Slider"}
        local r=row(45);rowTitle(r,info)
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
        local down=false
        track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then down=true end end)
        register(UIS.InputChanged:Connect(function(i) if down and i.UserInputType==Enum.UserInputType.MouseMovement then option:SetValue(min+math.clamp((Mouse.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(max-min)) end end))
        register(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then down=false end end))
        option:SetValue(option.Value);L.Options[index]=option;return option
    end
    function api:AddDropdown(index,info)
        info=info or {};local values=info.Values or {};local initial=info.Default
        if not info.Multi and type(initial)=="number" then initial=values[initial] end
        if info.Multi then local m={} for _,v in ipairs(initial or {}) do m[v]=true end initial=m end
        local option={Value=initial,Values=values,Multi=not not info.Multi,Type="Dropdown"}
        local r=row(62);local t=rowTitle(r,info);t.Size=UDim2.new(1,0,0,20)
        local box=new("TextButton",{AutoButtonColor=false,Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,31),
            BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,Font=Enum.Font.Gotham,Text="",TextColor3=L.Colors.Text,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},r);corner(box,12);stroke(box,0.8);pad(box,11,11)
        local pop=new("Frame",{Visible=false,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.08,Size=UDim2.fromOffset(180,0),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=200},Screen);corner(pop,12);stroke(pop,0.7);pad(pop,5,5,5,5)
        new("UIListLayout",{Padding=UDim.new(0,3)},pop)
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
        box.Activated:Connect(function() pop.Position=UDim2.fromOffset(box.AbsolutePosition.X,box.AbsolutePosition.Y+35);pop.Size=UDim2.fromOffset(box.AbsoluteSize.X,0);pop.Visible=not pop.Visible end)
        render();L.Options[index]=option;return option
    end
    function api:AddInput(index,info)
        info=info or {};local option={Value=tostring(info.Default or ""),Type="Input"}
        local r=row(62);local t=rowTitle(r,info);t.Size=UDim2.new(1,0,0,20)
        local box=new("TextBox",{Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,31),BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,
            ClearTextOnFocus=false,Font=Enum.Font.Gotham,Text=option.Value,PlaceholderText=info.Placeholder or "",TextColor3=L.Colors.Text,
            PlaceholderColor3=L.Colors.Muted,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},r);corner(box,12);stroke(box,0.8);pad(box,11,11)
        function option:SetValue(v) self.Value=tostring(v or "");box.Text=self.Value end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        box:GetPropertyChangedSignal("Text"):Connect(function() if info.Numeric and box.Text~="" and not tonumber(box.Text) then box.Text=option.Value else option.Value=box.Text;if not info.Finished then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end end end)
        box.FocusLost:Connect(function(enter) if info.Finished and enter then callback(info.Callback,option.Value);callback(option.Changed,option.Value) end end)
        L.Options[index]=option;return option
    end
    function api:AddKeybind(index,info)
        info=info or {};local option={Value=info.Default or "None",Mode=info.Mode or "Toggle",Toggled=false,Type="KeyPicker"}
        local r=row(38);rowTitle(r,info)
        local button=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(90,29),
            BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.27,Font=Enum.Font.Gotham,Text=option.Value,TextColor3=L.Colors.Text,TextSize=10},r);corner(button,12);stroke(button,0.8)
        local picking=false
        local function name(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then return "MB1" elseif i.UserInputType==Enum.UserInputType.MouseButton2 then return "MB2" elseif i.UserInputType==Enum.UserInputType.Keyboard then return i.KeyCode.Name end end
        function option:SetValue(v,mode) self.Value=type(v)=="table" and v[1] or v;self.Mode=mode or (type(v)=="table" and v[2]) or self.Mode;button.Text=self.Value;callback(info.ChangedCallback,self.Value);callback(self.Changed,self.Value) end
        function option:GetState() return self.Mode=="Always" or self.Toggled end
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        function option:OnClick(fn) self.Clicked=fn end
        button.Activated:Connect(function() picking=true;button.Text="...";local c;c=UIS.InputBegan:Connect(function(i) local n=name(i);if n then picking=false;c:Disconnect();option:SetValue(n) end end) end)
        register(UIS.InputBegan:Connect(function(i,gp) if not gp and not picking and name(i)==option.Value then option.Toggled=option.Mode=="Toggle" and not option.Toggled or true;callback(info.Callback,option.Toggled);callback(option.Clicked,option.Toggled) end end))
        register(UIS.InputEnded:Connect(function(i) if option.Mode=="Hold" and name(i)==option.Value then option.Toggled=false;callback(info.Callback,false) end end))
        L.Options[index]=option;return option
    end
    function api:AddColorpicker(index,info)
        info=info or {};local option={Value=info.Default or L.Colors.Accent,Transparency=info.Transparency or 0,Type="ColorPicker"}
        local r=row(38);rowTitle(r,info)
        local swatch=new("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(46,25),Text="",BackgroundColor3=option.Value},r);corner(swatch,13);stroke(swatch,0.65)
        local pop=new("Frame",{Visible=false,BackgroundColor3=L.Colors.Card,BackgroundTransparency=0.08,Size=UDim2.fromOffset(220,66),ZIndex=200},Screen);corner(pop,14);stroke(pop,0.65);pad(pop,9,9,9,9)
        local hex=new("TextBox",{ClearTextOnFocus=false,BackgroundColor3=L.Colors.Control,BackgroundTransparency=0.2,Size=UDim2.new(1,0,0,30),
            Font=Enum.Font.Gotham,Text="#"..option.Value:ToHex(),TextColor3=L.Colors.Text,TextSize=11},pop);corner(hex,10)
        function option:SetValueRGB(c,t) self.Value=c;self.Transparency=t or self.Transparency;swatch.BackgroundColor3=c;hex.Text="#"..c:ToHex();callback(info.Callback,c);callback(self.Changed,c) end
        option.SetValue=option.SetValueRGB
        function option:OnChanged(fn) self.Changed=fn;fn(self.Value) end
        hex.FocusLost:Connect(function() local ok,c=pcall(Color3.fromHex,hex.Text);if ok then option:SetValueRGB(c) end end)
        swatch.Activated:Connect(function() pop.Position=UDim2.fromOffset(swatch.AbsolutePosition.X-174,swatch.AbsolutePosition.Y+32);pop.Visible=not pop.Visible end)
        L.Options[index]=option;return option
    end
    api.AddColorPicker=api.AddColorpicker
    return api
end

local function makeColumn(parent,x,w)
    local col=new("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(x,0,0,0),Size=UDim2.new(w,-5,1,0),
        CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=2,ScrollBarImageColor3=L.Colors.Accent},parent)
    new("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},col)
    return {Root=col,AddCard=function(_,title)return createCard(col,title)end}
end

function L:CreateWindow(config)
    config=config or {};local width=config.Size and config.Size.X.Offset or 900;local height=config.Size and config.Size.Y.Offset or 600
    local window={Tabs={},TabOrder={}}
    local root=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(width,height),BackgroundTransparency=1},Screen)
    local scale=new("UIScale",{Scale=1},root)
    local panel=new("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=self.Colors.Panel,BackgroundTransparency=0.17,ClipsDescendants=true},root);corner(panel,28);stroke(panel,0.78)
    new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(99,97,91)),ColorSequenceKeypoint.new(0.48,Color3.fromRGB(67,64,59)),ColorSequenceKeypoint.new(1,Color3.fromRGB(39,37,34))}),Rotation=9},panel)
    local rail=new("Frame",{Position=UDim2.fromOffset(14,14),Size=UDim2.new(0,72,1,-28),BackgroundColor3=self.Colors.Rail,BackgroundTransparency=0.28},panel);corner(rail,22);stroke(rail,0.8)
    local nav=new("Frame",{Position=UDim2.fromOffset(10,12),Size=UDim2.new(1,-20,1,-70),BackgroundTransparency=1},rail)
    new("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},nav)
    local power=new("TextButton",{AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-12),Size=UDim2.fromOffset(42,36),BackgroundTransparency=1,
        Font=Enum.Font.GothamMedium,Text="O",TextColor3=self.Colors.Text,TextSize=16},rail)
    local content=new("Frame",{Position=UDim2.fromOffset(104,14),Size=UDim2.new(1,-118,1,-28),BackgroundTransparency=1},panel)
    local header=new("Frame",{Size=UDim2.new(1,0,0,54),BackgroundTransparency=1},content);drag(header,root)
    local subtabs=new("Frame",{Position=UDim2.fromOffset(0,4),Size=UDim2.new(1,-245,0,42),BackgroundTransparency=1},header)
    local subLayout=new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},subtabs)
    local search=new("TextBox",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-68,0,5),Size=UDim2.fromOffset(170,35),BackgroundColor3=self.Colors.Dark,BackgroundTransparency=0.5,
        ClearTextOnFocus=false,Font=Enum.Font.Gotham,PlaceholderText="Q  Search",PlaceholderColor3=self.Colors.Muted,Text="",TextColor3=self.Colors.Text,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},header);corner(search,16);pad(search,13,8)
    local initial=(Player.DisplayName~="" and Player.DisplayName or Player.Name):sub(1,1):upper()
    local initialLabel=text(header,initial,12,self.Colors.Text,true);initialLabel.AnchorPoint=Vector2.new(1,0);initialLabel.Position=UDim2.new(1,-38,0,5);initialLabel.Size=UDim2.fromOffset(25,35);initialLabel.TextXAlignment=Enum.TextXAlignment.Center
    local avatar=new("ImageLabel",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,6),Size=UDim2.fromOffset(32,32),BackgroundColor3=self.Colors.White,
        Image=("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(Player.UserId)},header);corner(avatar,16);stroke(avatar,0.25)
    local pages=new("Frame",{Position=UDim2.fromOffset(0,56),Size=UDim2.new(1,0,1,-56),BackgroundTransparency=1},content)
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
        local button=new("TextButton",{AutoButtonColor=false,Size=UDim2.fromOffset(46,40),BackgroundColor3=L.Colors.Dark,BackgroundTransparency=1,
            Font=Enum.Font.GothamMedium,Text=info.IconText or title:sub(1,1):upper(),TextColor3=L.Colors.Text,TextSize=13},nav);corner(button,13)
        function tab:Show()
            for _,other in ipairs(window.TabOrder) do other:Hide() end
            self.Active=true;tween(button,{BackgroundTransparency=0.38})
            for _,sub in ipairs(self.SubtabOrder) do sub.Button.Visible=true end
            if self.SubtabOrder[1] then self.SubtabOrder[1]:Show() end
        end
        function tab:Hide()
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
            sub.Root=page;sub.Button=sb;sub.Left=makeColumn(page,0,0.5);sub.Right=makeColumn(page,0.5,0.5)
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
        local methods={"AddParagraph","AddButton","AddToggle","AddSlider","AddDropdown","AddInput","AddKeybind","AddColorpicker","AddColorPicker"}
        for _,method in ipairs(methods) do tab[method]=function(self,...) if not self.DefaultCard then self.DefaultCard=self:AddSection("") end return self.DefaultCard[method](self.DefaultCard,...) end end
        window.Tabs[title]=tab;table.insert(window.TabOrder,tab);if #window.TabOrder==1 then tab:Show() end;return tab
    end
    function window:SelectTab(which) local tab=type(which)=="number" and self.TabOrder[which] or self.Tabs[which];if tab then tab:Show() end end
    function window:Toggle() root.Visible=not root.Visible end
    function window:Minimize() root.Visible=false end
    function window:Dialog(info)
        info=info or {};local shade=new("TextButton",{AutoButtonColor=false,Text="",BackgroundColor3=Color3.new(),BackgroundTransparency=0.45,Size=UDim2.fromScale(1,1),ZIndex=250},Screen)
        local box=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(390,190),BackgroundColor3=L.Colors.Card,ZIndex=251},shade);corner(box,20);stroke(box,0.65);pad(box,18,18,16,16)
        local ttl=text(box,info.Title or "Dialog",15,L.Colors.Text,true);ttl.Size=UDim2.new(1,0,0,24)
        local body=text(box,info.Content or "",11,L.Colors.Muted);body.Position=UDim2.fromOffset(0,34);body.Size=UDim2.new(1,0,0,75);body.TextWrapped=true;body.TextYAlignment=Enum.TextYAlignment.Top
        local buttons=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},box)
        new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,8)},buttons)
        for _,b in ipairs(info.Buttons or {{Title="Okay"}}) do local x=new("TextButton",{Size=UDim2.fromOffset(92,32),BackgroundColor3=L.Colors.Control,Font=Enum.Font.Gotham,Text=b.Title or "Okay",TextColor3=L.Colors.Text,TextSize=11,ZIndex=252},buttons);corner(x,14);x.Activated:Connect(function()callback(b.Callback);shade:Destroy()end) end
    end
    window.Root=root;window.Panel=panel;self.Window=window;table.insert(self.Windows,window)
    if config.Acrylic~=false then self:ToggleAcrylic(true) end
    return window
end

function L:SetTheme(name)
    local theme=self.Themes[name]
    if not theme then return end
    self.Theme=name
    for key,value in next,theme do self.Colors[key]=value end
    self:Notify({Title="Theme changed",Content="New windows will use "..name,Duration=3})
end
function L:ToggleAcrylic(value)
    local blur=Lighting:FindFirstChild("LuminwareBlur") or new("BlurEffect",{Name="LuminwareBlur",Size=0},Lighting)
    tween(blur,{Size=value==false and 0 or 8},0.2)
end
function L:ToggleTransparency(value) for _,w in ipairs(self.Windows) do tween(w.Panel,{BackgroundTransparency=value and 0.35 or 0.17}) end end
function L:Destroy() self:Unload() end
function L:Unload()
    self.Unloaded=true
    for _,s in ipairs(self.Signals) do pcall(function()s:Disconnect()end) end
    local blur=Lighting:FindFirstChild("LuminwareBlur");if blur then blur:Destroy() end
    Screen:Destroy()
end

pcall(function() if typeof(getgenv)=="function" then getgenv().Options=L.Options;getgenv().Toggles=L.Toggles end end)
return L

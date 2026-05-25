--[[
    iOS 26 UI Library
    A Roblox UI Library with iOS 26 (Liquid Glass) Design Language
    Inspired by Wind UI structure and iOS 26 visual design
    
    Features:
    - Liquid Glass: Semi-transparent frosted backgrounds, layered depth
    - Super Squircle: Continuous curve rounded corners
    - Spring Animations: Elastic/bounce effects on all interactions
    - Depth & Layering: Multi-layer semi-transparent stacking
    - Soft Shadows: Diffused shadow effects
    - Haptic Feel: Press-scale, ripple interaction feedback
    - Responsive: Auto-adapts between mobile and desktop layouts
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local a = {}
local p = {}
local Theme = {}
local Icons = {}
local ConfigSystem = {}
local DragSystem = {}
local NotificationSystem = {}
local DialogSystem = {}
local TooltipSystem = {}

local ActiveWindows = {}
local CurrentTheme = "Dark"
local ThemeConnections = {}
local MobileThreshold = 768

-- ============================================================
-- UTILITY MODULE (p)
-- ============================================================

function p.Create(className, props)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" and k ~= "Children" then
                inst[k] = v
            end
        end
        if props.Children then
            for _, child in ipairs(props.Children) do
                child.Parent = inst
            end
        end
        if props.Parent then
            inst.Parent = props.Parent
        end
    end
    return inst
end

function p.Tween(inst, props, duration, easingStyle, easingDirection, callback)
    duration = duration or 0.3
    easingStyle = easingStyle or Enum.EasingStyle.Quart
    easingDirection = easingDirection or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(inst, tweenInfo, props)
    if callback then
        tween.Completed:Connect(function()
            callback()
        end)
    end
    tween:Play()
    return tween
end

function p.Color3FromHex(hex)
    hex = hex:gsub("#", "")
    if #hex == 8 then hex = hex:sub(1, 6) end
    if #hex ~= 6 then return Color3.fromRGB(255, 255, 255) end
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    return Color3.fromRGB(r, g, b)
end

function p.Color3ToHex(color3)
    local r = math.floor(color3.R * 255 + 0.5)
    local g = math.floor(color3.G * 255 + 0.5)
    local b = math.floor(color3.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

function p.Lerp(a, b, t)
    return a + (b - a) * t
end

function p.Clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function p.Round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

function p.IsMobile()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
    if viewport then
        return viewport.X < MobileThreshold
    end
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function p.GetTextBounds(text, font, fontSize, maxSize)
    local success, bounds = pcall(function()
        return TextService:GetTextSize(text, font, fontSize, maxSize or Vector2.new(9999, 9999))
    end)
    if success then
        return bounds
    end
    return Vector2.new(0, 0)
end

function p.CreateGlassFrame(props)
    local theme = Theme.GetCurrent()
    local frame = p.Create("Frame", {
        Name = props.Name or "GlassFrame",
        Size = props.Size or UDim2.new(1, 0, 1, 0),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = props.BackgroundColor3 or theme.GlassBackground,
        BackgroundTransparency = props.BackgroundTransparency or theme.GlassTransparency,
        BorderSizePixel = 0,
        Parent = props.Parent
    })

    local cornerRadius = props.CornerRadius or UDim.new(0, 16)
    p.Create("UICorner", {
        CornerRadius = cornerRadius,
        Parent = frame
    })

    if props.Border ~= false then
        p.Create("UIStroke", {
            Color = theme.Border,
            Transparency = 0.6,
            Thickness = 1,
            Parent = frame
        })
    end

    if props.Shadow ~= false then
        local shadow = p.Create("ImageLabel", {
            Name = "Shadow",
            Size = UDim2.new(1, 20, 1, 20),
            Position = UDim2.new(0, -10, 0, -10),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = theme.Shadow,
            ImageTransparency = 0.6,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ZIndex = frame.ZIndex - 1,
            Parent = frame
        })
        p.Create("UICorner", {
            CornerRadius = cornerRadius,
            Parent = shadow
        })
    end

    return frame
end

function p.CreateCardFrame(props)
    local theme = Theme.GetCurrent()
    local frame = p.Create("Frame", {
        Name = props.Name or "Card",
        Size = props.Size or UDim2.new(1, 0, 0, 50),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = props.BackgroundColor3 or theme.CardBackground,
        BackgroundTransparency = props.BackgroundTransparency or 0,
        BorderSizePixel = 0,
        Parent = props.Parent
    })
    p.Create("UICorner", {
        CornerRadius = props.CornerRadius or UDim.new(0, 14),
        Parent = frame
    })
    return frame
end

function p.CreateLabel(props)
    local theme = Theme.GetCurrent()
    local label = p.Create("TextLabel", {
        Name = props.Name or "Label",
        Size = props.Size or UDim2.new(1, 0, 0, 20),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = props.Text or "",
        TextColor3 = props.TextColor3 or theme.TextPrimary,
        TextSize = props.TextSize or 14,
        Font = props.Font or Enum.Font.GothamMedium,
        TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
        TextTruncate = props.TextTruncate or Enum.TextTruncate.None,
        RichText = props.RichText or false,
        Parent = props.Parent
    })
    if props.AutomaticSize then
        label.AutomaticSize = props.AutomaticSize
    end
    return label
end

function p.ApplyPressScale(frame, scale, duration)
    scale = scale or 0.96
    duration = duration or 0.1
    local originalSize = frame.Size

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            p.Tween(frame, {
                Size = UDim2.new(
                    originalSize.X.Scale, originalSize.X.Offset * scale,
                    originalSize.Y.Scale, originalSize.Y.Offset * scale
                )
            }, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            p.Tween(frame, {Size = originalSize}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end)

    return originalSize
end

function p.CreateRipple(frame, posX, posY)
    local theme = Theme.GetCurrent()
    local ripple = p.Create("Frame", {
        Name = "Ripple",
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, posX, 0, posY),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Ripple,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 10,
        Parent = frame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = ripple})

    local maxSize = math.max(frame.AbsoluteSize.X, frame.AbsoluteSize.Y) * 2.5
    p.Tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
        ripple:Destroy()
    end)
end

function p.Cleanup(tbl)
    if type(tbl) ~= "table" then return end
    for key, value in pairs(tbl) do
        if typeof(value) == "RBXScriptConnection" then
            value:Disconnect()
        elseif typeof(value) == "Instance" then
            value:Destroy()
        end
        tbl[key] = nil
    end
end

function p.DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = p.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function p.GetSafeParent()
    local success, result = pcall(function()
        return CoreGui:FindFirstChild("iOS26UI") ~= nil
    end)
    if success then
        local folder = CoreGui:FindFirstChild("iOS26UI")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "iOS26UI"
            folder.Parent = CoreGui
        end
        return folder
    else
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        local folder = playerGui:FindFirstChild("iOS26UI")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "iOS26UI"
            folder.Parent = playerGui
        end
        return folder
    end
end

-- ============================================================
-- THEME SYSTEM
-- ============================================================

Theme.Themes = {
    Dark = {
        Name = "Dark",
        Background = p.Color3FromHex("#1C1C1E"),
        BackgroundTransparency = 0,
        GlassBackground = p.Color3FromHex("#1C1C1E"),
        GlassTransparency = 0.15,
        CardBackground = p.Color3FromHex("#2C2C2E"),
        CardTransparency = 0,
        TextPrimary = p.Color3FromHex("#FFFFFF"),
        TextSecondary = p.Color3FromHex("#8E8E93"),
        TextTertiary = p.Color3FromHex("#636366"),
        Accent = p.Color3FromHex("#007AFF"),
        AccentHover = p.Color3FromHex("#0A84FF"),
        AccentText = p.Color3FromHex("#FFFFFF"),
        Success = p.Color3FromHex("#34C759"),
        Warning = p.Color3FromHex("#FF9F0A"),
        Danger = p.Color3FromHex("#FF3B30"),
        Info = p.Color3FromHex("#5AC8FA"),
        Divider = p.Color3FromHex("#38383A"),
        Border = p.Color3FromHex("#48484A"),
        Shadow = p.Color3FromHex("#000000"),
        ToggleOn = p.Color3FromHex("#34C759"),
        ToggleOff = p.Color3FromHex("#39393D"),
        InputBackground = p.Color3FromHex("#1C1C1E"),
        Placeholder = p.Color3FromHex("#636366"),
        TabBackground = p.Color3FromHex("#1C1C1E"),
        TabActive = p.Color3FromHex("#007AFF"),
        TabInactive = p.Color3FromHex("#8E8E93"),
        TitleBar = p.Color3FromHex("#1C1C1E"),
        Overlay = p.Color3FromHex("#000000"),
        OverlayTransparency = 0.5,
        NotificationBackground = p.Color3FromHex("#2C2C2E"),
        DialogBackground = p.Color3FromHex("#2C2C2E"),
        TooltipBackground = p.Color3FromHex("#2C2C2E"),
        CheckboxCheck = p.Color3FromHex("#FFFFFF"),
        SliderFill = p.Color3FromHex("#007AFF"),
        SliderTrack = p.Color3FromHex("#39393D"),
        DropdownBackground = p.Color3FromHex("#2C2C2E"),
        DropdownHover = p.Color3FromHex("#3A3A3C"),
        CodeBackground = p.Color3FromHex("#1C1C1E"),
        CodeText = p.Color3FromHex("#FFFFFF"),
        WindowBorder = p.Color3FromHex("#48484A"),
        SectionHeader = p.Color3FromHex("#8E8E93"),
        BadgeBackground = p.Color3FromHex("#FF3B30"),
        BadgeText = p.Color3FromHex("#FFFFFF"),
        Ripple = p.Color3FromHex("#FFFFFF"),
    },
    Light = {
        Name = "Light",
        Background = p.Color3FromHex("#F2F2F7"),
        BackgroundTransparency = 0,
        GlassBackground = p.Color3FromHex("#F2F2F7"),
        GlassTransparency = 0.15,
        CardBackground = p.Color3FromHex("#FFFFFF"),
        CardTransparency = 0,
        TextPrimary = p.Color3FromHex("#000000"),
        TextSecondary = p.Color3FromHex("#8E8E93"),
        TextTertiary = p.Color3FromHex("#AEAEB2"),
        Accent = p.Color3FromHex("#007AFF"),
        AccentHover = p.Color3FromHex("#0A84FF"),
        AccentText = p.Color3FromHex("#FFFFFF"),
        Success = p.Color3FromHex("#34C759"),
        Warning = p.Color3FromHex("#FF9F0A"),
        Danger = p.Color3FromHex("#FF3B30"),
        Info = p.Color3FromHex("#5AC8FA"),
        Divider = p.Color3FromHex("#C6C6C8"),
        Border = p.Color3FromHex("#D1D1D6"),
        Shadow = p.Color3FromHex("#000000"),
        ToggleOn = p.Color3FromHex("#34C759"),
        ToggleOff = p.Color3FromHex("#E5E5EA"),
        InputBackground = p.Color3FromHex("#E5E5EA"),
        Placeholder = p.Color3FromHex("#C7C7CC"),
        TabBackground = p.Color3FromHex("#F2F2F7"),
        TabActive = p.Color3FromHex("#007AFF"),
        TabInactive = p.Color3FromHex("#8E8E93"),
        TitleBar = p.Color3FromHex("#F2F2F7"),
        Overlay = p.Color3FromHex("#000000"),
        OverlayTransparency = 0.5,
        NotificationBackground = p.Color3FromHex("#FFFFFF"),
        DialogBackground = p.Color3FromHex("#FFFFFF"),
        TooltipBackground = p.Color3FromHex("#FFFFFF"),
        CheckboxCheck = p.Color3FromHex("#FFFFFF"),
        SliderFill = p.Color3FromHex("#007AFF"),
        SliderTrack = p.Color3FromHex("#E5E5EA"),
        DropdownBackground = p.Color3FromHex("#FFFFFF"),
        DropdownHover = p.Color3FromHex("#F2F2F7"),
        CodeBackground = p.Color3FromHex("#F2F2F7"),
        CodeText = p.Color3FromHex("#1C1C1E"),
        WindowBorder = p.Color3FromHex("#D1D1D6"),
        SectionHeader = p.Color3FromHex("#8E8E93"),
        BadgeBackground = p.Color3FromHex("#FF3B30"),
        BadgeText = p.Color3FromHex("#FFFFFF"),
        Ripple = p.Color3FromHex("#000000"),
    }
}

function Theme.GetCurrent()
    return Theme.Themes[CurrentTheme] or Theme.Themes.Dark
end

function Theme.SetTheme(themeName)
    if Theme.Themes[themeName] then
        CurrentTheme = themeName
        Theme.FireThemeChanged()
    end
end

function Theme.Toggle()
    if CurrentTheme == "Dark" then
        Theme.SetTheme("Light")
    else
        Theme.SetTheme("Dark")
    end
end

function Theme.OnChanged(callback)
    table.insert(ThemeConnections, callback)
    return #ThemeConnections
end

function Theme.FireThemeChanged()
    for _, callback in ipairs(ThemeConnections) do
        local success, err = pcall(callback, Theme.GetCurrent())
        if not success then
            warn("[iOS26UI] Theme callback error: " .. tostring(err))
        end
    end
end

function Theme.RemoveCallback(index)
    ThemeConnections[index] = nil
end

function Theme.ApplyToInstances(instances)
    Theme.OnChanged(function(theme)
        for inst, props in pairs(instances) do
            if inst and inst.Parent then
                for propName, themeKey in pairs(props) do
                    if theme[themeKey] then
                        p.Tween(inst, {[propName] = theme[themeKey]}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- ICON SYSTEM
-- ============================================================

Icons.Provider = "rbxassetid://"
Icons.DefaultSize = 18

Icons.List = {
    home = 6034509999, settings = 6034509983, user = 6034509993,
    search = 6034509997, star = 6034509989, heart = 6034509991,
    bell = 6034509985, shield = 6034509987, lock = 6034509981,
    key = 6034509979, eye = 6034509977, eye_off = 6034509975,
    check = 6034509973, x = 6034509971, plus = 6034509969,
    minus = 6034509967, chevron_up = 6034509965, chevron_down = 6034509963,
    chevron_left = 6034509961, chevron_right = 6034509959,
    arrow_up = 6034509957, arrow_down = 6034509955,
    arrow_left = 6034509953, arrow_right = 6034509951,
    copy = 6034509949, trash = 6034509947, edit = 6034509945,
    download = 6034509943, upload = 6034509941, file = 6034509939,
    folder = 6034509937, image = 6034509935, camera = 6034509933,
    music = 6034509931, volume = 6034509929, mic = 6034509927,
    phone = 6034509925, wifi = 6034509923, bluetooth = 6034509921,
    battery = 6034509919, clock = 6034509917, calendar = 6034509915,
    map = 6034509913, compass = 6034509911, globe = 6034509909,
    sun = 6034509907, moon = 6034509905, cloud = 6034509903,
    zap = 6034509901, activity = 6034509899, flag = 6034509897,
    award = 6034509895, gift = 6034509893, package = 6034509891,
    layers = 6034509889, code = 6034509887, terminal = 6034509885,
    palette = 6034509883, color_picker = 6034509881,
    sliders = 6034509879, toggle_left = 6034509877,
    toggle_right = 6034509875, info = 6034509873,
    alert = 6034509871, help = 6034509869, message = 6034509867,
    mail = 6034509865, link = 6034509863, external = 6034509861,
    refresh = 6034509859, shuffle = 6034509855,
    play = 6034509849, pause = 6034509847, stop = 6034509845,
    maximize = 6034509843, minimize = 6034509841,
    grid = 6034509831, list = 6034509829, sidebar = 6034509827,
    layout = 6034509825, window = 6034509823, monitor = 6034509821,
    cpu = 6034509813, hard_drive = 6034509811,
    server = 6034509809, database = 6034509807,
    web = 6034509805, bug = 6034509803, wrench = 6034509801,
    tool = 6034509799, hammer = 6034509797, scissors = 6034509795,
    paintbrush = 6034509793, pen = 6034509791, pencil = 6034509789,
    bookmark = 6034509787, tag = 6034509785, target = 6034509783,
    filter = 6034509779, sort = 6034509777, hash = 6034509775,
    sparkles = 6034509765, wand = 6034509763,
    ghost = 6034509761, skull = 6034509759, robot = 6034509757,
    gamepad = 6034509753, joystick = 6034509751,
    dice = 6034509749, sword = 6034509745,
    shield_check = 6034509743, shield_alert = 6034509741,
}

function Icons.Get(name)
    if Icons.List[name] then
        return Icons.Provider .. tostring(Icons.List[name])
    end
    return ""
end

function Icons.Create(name, props)
    props = props or {}
    local theme = Theme.GetCurrent()
    local icon = p.Create("ImageLabel", {
        Name = "Icon_" .. (name or "unknown"),
        Size = UDim2.new(0, props.Size or Icons.DefaultSize, 0, props.Size or Icons.DefaultSize),
        Position = props.Position or UDim2.new(0, 0, 0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Image = Icons.Get(name),
        ImageColor3 = props.Color or theme.TextPrimary,
        ImageTransparency = props.Transparency or 0,
        ScaleType = Enum.ScaleType.Fit,
        Parent = props.Parent
    })
    return icon
end

function Icons.SetProvider(providerUrl)
    Icons.Provider = providerUrl
end

function Icons.Register(name, assetId)
    Icons.List[name] = assetId
end

-- ============================================================
-- DRAG SYSTEM
-- ============================================================

function DragSystem.MakeDraggable(frame, handle, constraints)
    handle = handle or frame
    constraints = constraints or {}
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragInput = nil

    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        frame.Position = newPos
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateDrag(input)
        end
    end)
end

-- ============================================================
-- CONFIG SYSTEM
-- ============================================================

ConfigSystem.Store = {}
ConfigSystem.FilePath = "iOS26UI_Config"
ConfigSystem.AutoSave = true

function ConfigSystem:SetFlag(key, value)
    self.Store[key] = value
    if self.AutoSave then
        self:SaveAll()
    end
end

function ConfigSystem:GetFlag(key, default)
    if self.Store[key] ~= nil then
        return self.Store[key]
    end
    return default
end

function ConfigSystem:SaveAll()
    pcall(function()
        writefile(self.FilePath .. ".json", HttpService:JSONEncode(self.Store))
    end)
end

function ConfigSystem:LoadAll()
    local success, result = pcall(function()
        if isfile and isfile(self.FilePath .. ".json") then
            return readfile(self.FilePath .. ".json")
        end
        return nil
    end)
    if success and result then
        local decoded = HttpService:JSONDecode(result)
        if type(decoded) == "table" then
            for k, v in pairs(decoded) do
                self.Store[k] = v
            end
        end
    end
end

function ConfigSystem:Clear()
    self.Store = {}
    pcall(function()
        if isfile and isfile(self.FilePath .. ".json") then
            delfile(self.FilePath .. ".json")
        end
    end)
end


-- ============================================================
-- WINDOW SYSTEM
-- ============================================================

local WindowClass = {}
WindowClass.__index = WindowClass

function a:CreateWindow(config)
    config = config or {}
    config.Title = config.Title or "iOS 26 UI"
    config.Author = config.Author or ""
    config.Theme = config.Theme or "Dark"
    config.Size = config.Size or UDim2.new(0, 580, 0, 420)
    config.Position = config.Position or UDim2.new(0.5, 0, 0.5, 0)
    config.AnchorPoint = config.AnchorPoint or Vector2.new(0.5, 0.5)
    config.CornerRadius = config.CornerRadius or 16
    config.Transparency = config.Transparency or 0
    config.Keybind = config.Keybind or Enum.KeyCode.RightShift
    config.SideBarWidth = config.SideBarWidth or 160
    config.BottomBarHeight = config.BottomBarHeight or 64
    config.TitleBarHeight = config.TitleBarHeight or 48
    config.Icon = config.Icon or nil
    config.HideOnStart = config.HideOnStart or false

    Theme.SetTheme(config.Theme)

    local window = {}
    setmetatable(window, WindowClass)

    window.Tabs = {}
    window.ActiveTab = nil
    window.IsVisible = true
    window.IsFullscreen = false
    window.IsLocked = false
    window.Config = config
    window.Connections = {}
    window.ThemeInstances = {}
    window.Notifications = {}
    window.SavedSize = config.Size
    window.SavedPosition = config.Position
    window.TransparencyValue = config.Transparency

    local safeParent = p.GetSafeParent()
    local theme = Theme.GetCurrent()

    -- ScreenGui
    local screenGui = p.Create("ScreenGui", {
        Name = "iOS26UI_" .. config.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = safeParent
    })
    window.ScreenGui = screenGui

    -- Main Window Frame (Liquid Glass)
    local windowFrame = p.CreateGlassFrame({
        Name = "Window",
        Size = config.Size,
        Position = config.Position,
        AnchorPoint = config.AnchorPoint,
        BackgroundColor3 = theme.GlassBackground,
        BackgroundTransparency = math.max(theme.GlassTransparency, config.Transparency),
        CornerRadius = UDim.new(0, config.CornerRadius),
        Border = true,
        Shadow = true,
        Parent = screenGui
    })
    window.WindowFrame = windowFrame

    -- Add subtle glass overlay for depth
    local glassOverlay = p.Create("Frame", {
        Name = "GlassOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.97,
        BorderSizePixel = 0,
        ZIndex = windowFrame.ZIndex + 1,
        Parent = windowFrame
    })
    p.Create("UICorner", {
        CornerRadius = UDim.new(0, config.CornerRadius),
        Parent = glassOverlay
    })
    window.GlassOverlay = glassOverlay

    -- Window border (glass edge)
    local windowStroke = p.Create("UIStroke", {
        Name = "WindowStroke",
        Color = theme.WindowBorder,
        Transparency = 0.4,
        Thickness = 1.5,
        Parent = windowFrame
    })
    window.WindowStroke = windowStroke

    -- Title Bar
    local titleBar = p.Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, config.TitleBarHeight),
        BackgroundColor3 = theme.TitleBar,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = windowFrame
    })
    p.Create("UICorner", {
        CornerRadius = UDim.new(0, config.CornerRadius),
        Parent = titleBar
    })
    -- Cover bottom corners of title bar
    local titleBarCover = p.Create("Frame", {
        Name = "BottomCover",
        Size = UDim2.new(1, 0, 0, config.CornerRadius),
        Position = UDim2.new(0, 0, 1, -config.CornerRadius),
        BackgroundColor3 = theme.TitleBar,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = titleBar.ZIndex,
        Parent = titleBar
    })
    window.TitleBar = titleBar

    -- Title Bar: Window Icon
    if config.Icon then
        local windowIcon = Icons.Create(config.Icon, {
            Size = 20,
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Color = theme.Accent,
            Parent = titleBar
        })
        window.WindowIcon = windowIcon
    end

    -- Title Bar: Title Text
    local iconOffset = config.Icon and 40 or 0
    local titleText = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, 14 + iconOffset, 0, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = titleBar
    })
    window.TitleText = titleText

    -- Title Bar: Author
    if config.Author and config.Author ~= "" then
        local authorText = p.CreateLabel({
            Name = "Author",
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(0, 14 + iconOffset, 0, 0),
            Text = config.Author,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            Parent = titleBar
        })
        -- Position author below title by using right side
        authorText.Position = UDim2.new(1, -14, 0.5, 0)
        authorText.AnchorPoint = Vector2.new(1, 0.5)
        authorText.TextXAlignment = Enum.TextXAlignment.Right
        window.AuthorText = authorText
    end

    -- Title Bar: Close Button
    local closeBtn = p.Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -10, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.Danger,
        BackgroundTransparency = 0.2,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = titleBar.ZIndex + 1,
        Parent = titleBar
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = closeBtn})
    local closeIcon = Icons.Create("x", {Size = 14, Color = Color3.fromRGB(255, 255, 255), Parent = closeBtn})
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    window.CloseButton = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        window:ToggleVisibility()
    end)
    closeBtn.MouseEnter:Connect(function()
        p.Tween(closeBtn, {BackgroundTransparency = 0}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    closeBtn.MouseLeave:Connect(function()
        p.Tween(closeBtn, {BackgroundTransparency = 0.2}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    -- Title Bar: Minimize Button
    local minBtn = p.Create("TextButton", {
        Name = "MinButton",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -44, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.Warning,
        BackgroundTransparency = 0.2,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = titleBar.ZIndex + 1,
        Parent = titleBar
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = minBtn})
    local minIcon = Icons.Create("minus", {Size = 14, Color = Color3.fromRGB(0, 0, 0), Parent = minBtn})
    minIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    minIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    window.MinButton = minBtn

    minBtn.MouseButton1Click:Connect(function()
        window:ToggleFullscreen()
    end)
    minBtn.MouseEnter:Connect(function()
        p.Tween(minBtn, {BackgroundTransparency = 0}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    minBtn.MouseLeave:Connect(function()
        p.Tween(minBtn, {BackgroundTransparency = 0.2}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    -- Title Bar: Theme Toggle Button
    local themeBtn = p.Create("TextButton", {
        Name = "ThemeButton",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -78, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.3,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = titleBar.ZIndex + 1,
        Parent = titleBar
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = themeBtn})
    local themeIcon = Icons.Create("moon", {Size = 14, Color = Color3.fromRGB(255, 255, 255), Parent = themeBtn})
    themeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    themeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    window.ThemeButton = themeBtn
    window.ThemeIcon = themeIcon

    themeBtn.MouseButton1Click:Connect(function()
        Theme.Toggle()
        local newTheme = Theme.GetCurrent()
        if newTheme.Name == "Light" then
            themeIcon.Image = Icons.Get("sun")
        else
            themeIcon.Image = Icons.Get("moon")
        end
    end)
    themeBtn.MouseEnter:Connect(function()
        p.Tween(themeBtn, {BackgroundTransparency = 0}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    themeBtn.MouseLeave:Connect(function()
        p.Tween(themeBtn, {BackgroundTransparency = 0.3}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    -- Make title bar draggable
    DragSystem.MakeDraggable(windowFrame, titleBar)

    -- Content Container (below title bar, includes sidebar + content)
    local contentContainer = p.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, 0, 1, -config.TitleBarHeight),
        Position = UDim2.new(0, 0, 0, config.TitleBarHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = windowFrame
    })
    window.ContentContainer = contentContainer

    -- Sidebar (Desktop) / Bottom Bar (Mobile)
    local isMobile = p.IsMobile()

    -- Desktop Sidebar
    local sidebar = p.Create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, config.SideBarWidth, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.TabBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Visible = not isMobile,
        Parent = contentContainer
    })
    p.Create("UICorner", {
        CornerRadius = UDim.new(0, config.CornerRadius),
        Parent = sidebar
    })
    -- Cover right side radius
    local sidebarCover = p.Create("Frame", {
        Name = "RightCover",
        Size = UDim2.new(config.CornerRadius, 0, 1, 0),
        Position = UDim2.new(1, -config.CornerRadius, 0, 0),
        BackgroundColor3 = theme.TabBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = sidebar
    })
    window.Sidebar = sidebar

    local sidebarLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sidebar
    })
    local sidebarPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebar
    })

    -- Mobile Bottom Bar
    local bottomBar = p.Create("Frame", {
        Name = "BottomBar",
        Size = UDim2.new(1, 0, 0, config.BottomBarHeight),
        Position = UDim2.new(0, 0, 1, -config.BottomBarHeight),
        BackgroundColor3 = theme.TabBackground,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Visible = isMobile,
        Parent = contentContainer
    })
    p.Create("UICorner", {
        CornerRadius = UDim.new(0, config.CornerRadius),
        Parent = bottomBar
    })
    local bottomBarCover = p.Create("Frame", {
        Name = "TopCover",
        Size = UDim2.new(1, 0, config.CornerRadius, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.TabBackground,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Parent = bottomBar
    })
    window.BottomBar = bottomBar

    local bottomBarLayout = p.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = bottomBar
    })
    local bottomBarPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = bottomBar
    })

    -- Main Content Area
    local mainContent = p.Create("ScrollingFrame", {
        Name = "MainContent",
        Size = isMobile and UDim2.new(1, 0, 1, -config.BottomBarHeight) or UDim2.new(1, -config.SideBarWidth, 1, 0),
        Position = isMobile and UDim2.new(0, 0, 0, 0) or UDim2.new(0, config.SideBarWidth, 0, 0),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.TextSecondary,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = contentContainer
    })
    p.Create("UICorner", {
        CornerRadius = UDim.new(0, config.CornerRadius),
        Parent = mainContent
    })
    window.MainContent = mainContent

    local contentLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = mainContent
    })
    local contentPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = mainContent
    })

    -- Resize Handle (bottom-right corner)
    local resizeHandle = p.Create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -6, 1, -6),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 100,
        Parent = windowFrame
    })
    local resizeIcon = Icons.Create("maximize", {Size = 12, Color = theme.TextSecondary, Transparency = 0.5, Parent = resizeHandle})
    resizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    resizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)

    local resizing = false
    local resizeStartPos = nil
    local resizeStartSize = nil

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStartPos = input.Position
            resizeStartSize = windowFrame.Size
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartPos
            local newWidth = math.max(380, resizeStartSize.X.Offset + delta.X)
            local newHeight = math.max(280, resizeStartSize.Y.Offset + delta.Y)
            windowFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)

    -- Keybind to toggle visibility
    if config.Keybind then
        local keybindConn
        keybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == config.Keybind then
                window:ToggleVisibility()
            end
        end)
        table.insert(window.Connections, keybindConn)
    end

    -- Responsive layout handler
    local viewportConn
    viewportConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        local mobile = p.IsMobile()
        if mobile then
            sidebar.Visible = false
            bottomBar.Visible = true
            if not window.IsFullscreen then
                mainContent.Size = UDim2.new(1, 0, 1, -config.BottomBarHeight)
                mainContent.Position = UDim2.new(0, 0, 0, 0)
                if window.IsVisible then
                    windowFrame.Size = UDim2.new(1, 0, 1, 0)
                    windowFrame.Position = UDim2.new(0, 0, 0, 0)
                    windowFrame.AnchorPoint = Vector2.new(0, 0)
                end
            end
        else
            sidebar.Visible = true
            bottomBar.Visible = false
            if not window.IsFullscreen then
                mainContent.Size = UDim2.new(1, -config.SideBarWidth, 1, 0)
                mainContent.Position = UDim2.new(0, config.SideBarWidth, 0, 0)
                windowFrame.Size = config.Size
                windowFrame.Position = config.Position
                windowFrame.AnchorPoint = config.AnchorPoint
            end
        end
    end)
    table.insert(window.Connections, viewportConn)

    -- Apply initial mobile layout
    if isMobile then
        windowFrame.Size = UDim2.new(1, 0, 1, 0)
        windowFrame.Position = UDim2.new(0, 0, 0, 0)
        windowFrame.AnchorPoint = Vector2.new(0, 0)
        sidebar.Visible = false
        bottomBar.Visible = true
        mainContent.Size = UDim2.new(1, 0, 1, -config.BottomBarHeight)
        mainContent.Position = UDim2.new(0, 0, 0, 0)
    end

    -- Theme change handler for window
    Theme.OnChanged(function(th)
        -- Window frame
        p.Tween(windowFrame, {BackgroundColor3 = th.GlassBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(windowStroke, {Color = th.WindowBorder}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        -- Title bar
        p.Tween(titleBar, {BackgroundColor3 = th.TitleBar}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(titleBarCover, {BackgroundColor3 = th.TitleBar}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(titleText, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if window.AuthorText then
            p.Tween(window.AuthorText, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        -- Sidebar
        p.Tween(sidebar, {BackgroundColor3 = th.TabBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sidebarCover, {BackgroundColor3 = th.TabBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        -- Bottom bar
        p.Tween(bottomBar, {BackgroundColor3 = th.TabBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(bottomBarCover, {BackgroundColor3 = th.TabBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        -- Content
        p.Tween(mainContent, {BackgroundColor3 = th.Background, ScrollBarImageColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        -- Buttons
        p.Tween(closeBtn, {BackgroundColor3 = th.Danger}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(minBtn, {BackgroundColor3 = th.Warning}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(themeBtn, {BackgroundColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if window.WindowIcon then
            p.Tween(window.WindowIcon, {ImageColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        -- Glass overlay
        if th.Name == "Light" then
            p.Tween(glassOverlay, {BackgroundTransparency = 0.95}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            p.Tween(glassOverlay, {BackgroundTransparency = 0.97}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    -- Hide on start
    if config.HideOnStart then
        windowFrame.Visible = false
        window.IsVisible = false
    end

    table.insert(ActiveWindows, window)
    return window
end

function WindowClass:Tab(config)
    config = config or {}
    config.Title = config.Title or "Tab"
    config.Icon = config.Icon or nil
    config.Order = config.Order or #self.Tabs + 1

    local theme = Theme.GetCurrent()
    local isMobile = p.IsMobile()
    local tab = {}
    tab.Title = config.Title
    tab.Icon = config.Icon
    tab.Order = config.Order
    tab.Sections = {}
    tab.Window = self
    tab.IsSelected = false
    tab.Locked = false
    tab.Connections = {}
    tab.ThemeInstances = {}

    -- Tab button for Sidebar (Desktop)
    local tabBtnDesktop = p.Create("TextButton", {
        Name = "TabBtn_" .. config.Title,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = config.Order,
        Parent = self.Sidebar
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tabBtnDesktop})
    tab.DesktopButton = tabBtnDesktop

    local tabPadding = p.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = tabBtnDesktop
    })

    -- Tab icon (desktop)
    if config.Icon then
        local tabIcon = Icons.Create(config.Icon, {
            Size = 16,
            Position = UDim2.new(0, 10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Color = theme.TabInactive,
            Parent = tabBtnDesktop
        })
        tab.DesktopIcon = tabIcon
    end

    -- Tab label (desktop)
    local iconOffsetDesktop = config.Icon and 32 or 0
    local tabLabel = p.CreateLabel({
        Name = "Label",
        Size = UDim2.new(1, -iconOffsetDesktop - 10, 1, 0),
        Position = UDim2.new(0, iconOffsetDesktop + 10, 0, 0),
        Text = config.Title,
        TextColor3 = theme.TabInactive,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        Parent = tabBtnDesktop
    })
    tab.DesktopLabel = tabLabel

    -- Tab button for Bottom Bar (Mobile)
    local tabBtnMobile = p.Create("TextButton", {
        Name = "TabBtnMobile_" .. config.Title,
        Size = UDim2.new(0, 60, 1, 0),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = config.Order,
        Parent = self.BottomBar
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tabBtnMobile})
    tab.MobileButton = tabBtnMobile

    -- Tab icon (mobile)
    if config.Icon then
        local mobileIcon = Icons.Create(config.Icon, {
            Size = 18,
            Position = UDim2.new(0.5, 0, 0.3, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Color = theme.TabInactive,
            Parent = tabBtnMobile
        })
        tab.MobileIcon = mobileIcon
    end

    -- Tab label (mobile)
    local mobileLabel = p.CreateLabel({
        Name = "MobileLabel",
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -14),
        Text = config.Title,
        TextColor3 = theme.TabInactive,
        TextSize = 9,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = tabBtnMobile
    })
    tab.MobileLabel = mobileLabel

    -- Tab Content Frame
    local tabContent = p.Create("Frame", {
        Name = "TabContent_" .. config.Title,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        LayoutOrder = config.Order,
        Parent = self.MainContent
    })
    local tabContentLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabContent
    })
    tab.ContentFrame = tabContent

    -- Empty state placeholder
    local emptyState = p.Create("Frame", {
        Name = "EmptyState",
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundTransparency = 1,
        Visible = true,
        Parent = tabContent
    })
    local emptyLabel = p.CreateLabel({
        Name = "EmptyLabel",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0.5, 0),
        Text = "No sections yet",
        TextColor3 = theme.TextTertiary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = emptyState
    })
    tab.EmptyState = emptyState

    -- Tab selection handler
    local function selectTab()
        -- Deselect all other tabs
        for _, otherTab in ipairs(self.Tabs) do
            otherTab.IsSelected = false
            otherTab.ContentFrame.Visible = false
            -- Reset desktop button style
            p.Tween(otherTab.DesktopButton, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            p.Tween(otherTab.DesktopLabel, {TextColor3 = theme.TabInactive}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if otherTab.DesktopIcon then
                p.Tween(otherTab.DesktopIcon, {ImageColor3 = theme.TabInactive}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
            -- Reset mobile button style
            p.Tween(otherTab.MobileButton, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            p.Tween(otherTab.MobileLabel, {TextColor3 = theme.TabInactive}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if otherTab.MobileIcon then
                p.Tween(otherTab.MobileIcon, {ImageColor3 = theme.TabInactive}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        end

        -- Select this tab
        tab.IsSelected = true
        tab.ContentFrame.Visible = true
        -- Active desktop button style
        p.Tween(tabBtnDesktop, {BackgroundTransparency = 0.85, BackgroundColor3 = theme.Accent}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(tabLabel, {TextColor3 = theme.TabActive}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if tab.DesktopIcon then
            p.Tween(tab.DesktopIcon, {ImageColor3 = theme.TabActive}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        -- Active mobile button style
        p.Tween(tabBtnMobile, {BackgroundTransparency = 0.85, BackgroundColor3 = theme.Accent}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(mobileLabel, {TextColor3 = theme.TabActive}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if tab.MobileIcon then
            p.Tween(tab.MobileIcon, {ImageColor3 = theme.TabActive}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end

        self.ActiveTab = tab
    end

    tabBtnDesktop.MouseButton1Click:Connect(function()
        if not tab.Locked then selectTab() end
    end)
    tabBtnMobile.MouseButton1Click:Connect(function()
        if not tab.Locked then selectTab() end
    end)

    -- Hover effects (desktop)
    tabBtnDesktop.MouseEnter:Connect(function()
        if not tab.IsSelected then
            p.Tween(tabBtnDesktop, {BackgroundTransparency = 0.7, BackgroundColor3 = theme.CardBackground}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)
    tabBtnDesktop.MouseLeave:Connect(function()
        if not tab.IsSelected then
            p.Tween(tabBtnDesktop, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)

    -- Theme handling for tab
    Theme.OnChanged(function(th)
        if tab.IsSelected then
            p.Tween(tabBtnDesktop, {BackgroundColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            p.Tween(tabLabel, {TextColor3 = th.TabActive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if tab.DesktopIcon then
                p.Tween(tab.DesktopIcon, {ImageColor3 = th.TabActive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
            p.Tween(tabBtnMobile, {BackgroundColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            p.Tween(mobileLabel, {TextColor3 = th.TabActive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if tab.MobileIcon then
                p.Tween(tab.MobileIcon, {ImageColor3 = th.TabActive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        else
            p.Tween(tabLabel, {TextColor3 = th.TabInactive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if tab.DesktopIcon then
                p.Tween(tab.DesktopIcon, {ImageColor3 = th.TabInactive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
            p.Tween(mobileLabel, {TextColor3 = th.TabInactive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if tab.MobileIcon then
                p.Tween(tab.MobileIcon, {ImageColor3 = th.TabInactive}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        end
        p.Tween(emptyLabel, {TextColor3 = th.TextTertiary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)

    -- Tab methods
    function tab:Section(sectionConfig)
        sectionConfig = sectionConfig or {}
        sectionConfig.Title = sectionConfig.Title or "Section"
        sectionConfig.Description = sectionConfig.Description or ""
        sectionConfig.Order = sectionConfig.Order or #self.Sections + 1
        sectionConfig.Collapsible = sectionConfig.Collapsible ~= false
        return SectionClass.Create(self, sectionConfig)
    end

    function tab:SetTitle(newTitle)
        self.Title = newTitle
        tabLabel.Text = newTitle
        mobileLabel.Text = newTitle
    end

    function tab:Lock()
        self.Locked = true
        tabBtnDesktop.AutoButtonColor = false
        tabBtnMobile.AutoButtonColor = false
    end

    function tab:Unlock()
        self.Locked = false
        tabBtnDesktop.AutoButtonColor = true
        tabBtnMobile.AutoButtonColor = true
    end

    function tab:Select()
        selectTab()
    end

    table.insert(self.Tabs, tab)

    -- Auto-select first tab
    if #self.Tabs == 1 then
        selectTab()
    end

    return tab
end

function WindowClass:ToggleVisibility()
    self.IsVisible = not self.IsVisible
    if self.IsVisible then
        self.WindowFrame.Visible = true
        self.WindowFrame.Size = UDim2.new(0, 0, 0, 0)
        p.Tween(self.WindowFrame, {Size = self.SavedSize}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        self.SavedSize = self.WindowFrame.Size
        p.Tween(self.WindowFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
            self.WindowFrame.Visible = false
        end)
    end
end

function WindowClass:ToggleFullscreen()
    local isMobile = p.IsMobile()
    self.IsFullscreen = not self.IsFullscreen

    if self.IsFullscreen then
        self.SavedSize = self.WindowFrame.Size
        self.SavedPosition = self.WindowFrame.Position
        local targetSize = isMobile and UDim2.new(1, 0, 1, 0) or UDim2.new(0.9, 0, 0.9, 0)
        local targetPos = UDim2.new(0.5, 0, 0.5, 0)
        self.WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        p.Tween(self.WindowFrame, {Size = targetSize, Position = targetPos}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    else
        p.Tween(self.WindowFrame, {Size = self.SavedSize, Position = self.SavedPosition}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end
end

function WindowClass:SetTransparency(value)
    self.TransparencyValue = value
    p.Tween(self.WindowFrame, {BackgroundTransparency = value}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

function WindowClass:Notify(config)
    NotificationSystem:Create(self, config)
end

function WindowClass:Dialog(config)
    DialogSystem:Create(self, config)
end

function WindowClass:Destroy()
    for _, conn in ipairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self.ScreenGui:Destroy()
    for i, w in ipairs(ActiveWindows) do
        if w == self then
            table.remove(ActiveWindows, i)
            break
        end
    end
end


-- ============================================================
-- SECTION CLASS
-- ============================================================

local SectionClass = {}
SectionClass.__index = SectionClass

function SectionClass.Create(tab, config)
    local section = {}
    setmetatable(section, SectionClass)

    section.Title = config.Title
    section.Description = config.Description or ""
    section.Order = config.Order
    section.Collapsible = config.Collapsible
    section.IsCollapsed = false
    section.Locked = false
    section.Elements = {}
    section.Tab = tab
    section.Connections = {}

    local theme = Theme.GetCurrent()

    -- Hide empty state
    if tab.EmptyState then
        tab.EmptyState.Visible = false
    end

    -- Section container
    local sectionFrame = p.Create("Frame", {
        Name = "Section_" .. config.Title,
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = config.Order,
        Parent = tab.ContentFrame
    })
    section.Frame = sectionFrame

    local sectionLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = sectionFrame
    })

    -- Section header
    local headerBtn = p.Create("TextButton", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = 0,
        Parent = sectionFrame
    })
    section.HeaderButton = headerBtn

    -- Section title
    local sectionTitle = p.CreateLabel({
        Name = "SectionTitle",
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        Text = config.Title:upper(),
        TextColor3 = theme.SectionHeader,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = headerBtn
    })
    section.TitleLabel = sectionTitle

    -- Collapse chevron
    if config.Collapsible then
        local chevron = Icons.Create("chevron_down", {
            Size = 14,
            Position = UDim2.new(1, -4, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Color = theme.TextSecondary,
            Parent = headerBtn
        })
        section.Chevron = chevron
    end

    -- Section card (iOS grouped card)
    local cardFrame = p.CreateCardFrame({
        Name = "Card",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.CardBackground,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        Parent = sectionFrame
    })
    section.CardFrame = cardFrame

    -- Card stroke
    local cardStroke = p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.7,
        Thickness = 0.5,
        Parent = cardFrame
    })
    section.CardStroke = cardStroke

    -- Card content layout
    local cardLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = cardFrame
    })

    -- Card padding
    local cardPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = cardFrame
    })

    -- Collapse/Expand toggle
    if config.Collapsible then
        headerBtn.MouseButton1Click:Connect(function()
            if section.IsCollapsed then
                section:Expand()
            else
                section:Collapse()
            end
        end)
    end

    -- Theme handling
    Theme.OnChanged(function(th)
        p.Tween(sectionTitle, {TextColor3 = th.SectionHeader}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(cardFrame, {BackgroundColor3 = th.CardBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(cardStroke, {Color = th.Border}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if section.Chevron then
            p.Tween(section.Chevron, {ImageColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    -- Section methods
    function section:Button(btnConfig)
        return ElementClass.Button(self, btnConfig)
    end

    function section:Toggle(toggleConfig)
        return ElementClass.Toggle(self, toggleConfig)
    end

    function section:Slider(sliderConfig)
        return ElementClass.Slider(self, sliderConfig)
    end

    function section:Dropdown(dropdownConfig)
        return ElementClass.Dropdown(self, dropdownConfig)
    end

    function section:Input(inputConfig)
        return ElementClass.Input(self, inputConfig)
    end

    function section:Checkbox(checkConfig)
        return ElementClass.Checkbox(self, checkConfig)
    end

    function section:Keybind(keyConfig)
        return ElementClass.Keybind(self, keyConfig)
    end

    function section:ColorPicker(colorConfig)
        return ElementClass.ColorPicker(self, colorConfig)
    end

    function section:Paragraph(paraConfig)
        return ElementClass.Paragraph(self, paraConfig)
    end

    function section:Divider(divConfig)
        return ElementClass.Divider(self, divConfig or {})
    end

    function section:Code(codeConfig)
        return ElementClass.Code(self, codeConfig)
    end

    function section:Image(imgConfig)
        return ElementClass.Image(self, imgConfig)
    end

    function section:Group(groupConfig)
        return ElementClass.Group(self, groupConfig)
    end

    function section:Collapse()
        self.IsCollapsed = true
        p.Tween(cardFrame, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        p.Tween(cardStroke, {Transparency = 1}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        if self.Chevron then
            p.Tween(self.Chevron, {Rotation = -90}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        end
        -- Hide children
        for _, child in ipairs(cardFrame:GetChildren()) do
            if child:IsA("GUIObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                child.Visible = false
            end
        end
    end

    function section:Expand()
        self.IsCollapsed = false
        cardFrame.AutomaticSize = Enum.AutomaticSize.Y
        p.Tween(cardFrame, {BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        p.Tween(cardStroke, {Transparency = 0.7}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        if self.Chevron then
            p.Tween(self.Chevron, {Rotation = 0}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        end
        for _, child in ipairs(cardFrame:GetChildren()) do
            if child:IsA("GUIObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                child.Visible = true
            end
        end
    end

    function section:SetTitle(newTitle)
        self.Title = newTitle
        sectionTitle.Text = newTitle:upper()
    end

    function section:Lock()
        self.Locked = true
    end

    function section:Unlock()
        self.Locked = false
    end

    table.insert(tab.Sections, section)
    return section
end


-- ============================================================
-- ELEMENT CLASS (All UI Elements)
-- ============================================================

local ElementClass = {}

-- Helper: Create a standard element row
local function createElementRow(section, config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local rowHeight = config.Height or 42

    local row = p.Create("Frame", {
        Name = config.Name or "ElementRow",
        Size = UDim2.new(1, 0, 0, rowHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = config.Order or #section.Elements + 1,
        Parent = section.CardFrame
    })

    -- Divider line above (if not first element)
    if #section.Elements > 0 then
        local divider = p.Create("Frame", {
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 0.5),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = theme.Divider,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = row.ZIndex + 1,
            Parent = row
        })
        row._Divider = divider
    end

    return row
end

-- ============================================================
-- BUTTON
-- ============================================================

function ElementClass.Button(section, config)
    config = config or {}
    config.Title = config.Title or "Button"
    config.Callback = config.Callback or function() end
    config.Color = config.Color or nil
    config.Icon = config.Icon or nil
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Button"
    element.Title = config.Title
    element.Locked = false
    element.Callback = config.Callback

    local row = createElementRow(section, {
        Name = "Button_" .. config.Title,
        Order = config.Order,
        Height = 46
    })
    element.Row = row

    local btnColor = config.Color and p.Color3FromHex(config.Color) or theme.Accent

    local btn = p.Create("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 1, -8),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = btnColor,
        BackgroundTransparency = 0.15,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = btn})
    element.Button = btn

    -- Glass effect on button
    local btnStroke = p.Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.85,
        Thickness = 0.5,
        Parent = btn
    })

    -- Button content (icon + text)
    if config.Icon then
        local btnIcon = Icons.Create(config.Icon, {
            Size = 16,
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Color = theme.AccentText,
            Parent = btn
        })
        element.Icon = btnIcon
    end

    local iconOffset = config.Icon and 36 or 0
    local btnLabel = p.CreateLabel({
        Name = "Label",
        Size = UDim2.new(1, -iconOffset - 28, 1, 0),
        Position = UDim2.new(0, iconOffset + 14, 0, 0),
        Text = config.Title,
        TextColor3 = theme.AccentText,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = btn
    })
    element.Label = btnLabel

    -- Press-scale effect
    local originalBtnSize = btn.Size
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            p.Tween(btn, {
                Size = UDim2.new(originalBtnSize.X.Scale, originalBtnSize.X.Offset * 0.97, originalBtnSize.Y.Scale, originalBtnSize.Y.Offset * 0.94)
            }, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            -- Ripple
            local relX = input.Position.X - btn.AbsolutePosition.X
            local relY = input.Position.Y - btn.AbsolutePosition.Y
            p.CreateRipple(btn, relX, relY)
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            p.Tween(btn, {Size = originalBtnSize}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if not element.Locked then
            config.Callback()
        end
    end)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        p.Tween(btn, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    btn.MouseLeave:Connect(function()
        p.Tween(btn, {BackgroundTransparency = 0.15}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    -- Theme handling
    Theme.OnChanged(function(th)
        local newColor = config.Color and p.Color3FromHex(config.Color) or th.Accent
        p.Tween(btn, {BackgroundColor3 = newColor}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(btnLabel, {TextColor3 = th.AccentText}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if element.Icon then
            p.Tween(element.Icon, {ImageColor3 = th.AccentText}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        btnLabel.Text = newTitle
    end

    function element:Lock()
        self.Locked = true
        btn.AutoButtonColor = false
        p.Tween(btn, {BackgroundTransparency = 0.5}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    function element:Unlock()
        self.Locked = false
        btn.AutoButtonColor = true
        p.Tween(btn, {BackgroundTransparency = 0.15}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- TOGGLE
-- ============================================================

function ElementClass.Toggle(section, config)
    config = config or {}
    config.Title = config.Title or "Toggle"
    config.Default = config.Default or false
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Toggle"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Callback = config.Callback

    local row = createElementRow(section, {
        Name = "Toggle_" .. config.Title,
        Order = config.Order
    })
    element.Row = row

    -- Title label
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- iOS-style toggle switch
    local toggleContainer = p.Create("Frame", {
        Name = "ToggleContainer",
        Size = UDim2.new(0, 51, 0, 31),
        Position = UDim2.new(1, -4, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = config.Default and theme.ToggleOn or theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleContainer})
    element.ToggleContainer = toggleContainer

    -- Toggle knob
    local knob = p.Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 27, 0, 27),
        Position = config.Default and UDim2.new(1, -29, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = toggleContainer.ZIndex + 1,
        Parent = toggleContainer
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})
    -- Knob shadow
    p.Create("ImageLabel", {
        Name = "KnobShadow",
        Size = UDim2.new(1, 6, 1, 6),
        Position = UDim2.new(0, -3, 0, -1),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = knob
    })
    element.Knob = knob

    -- Click area
    local clickArea = p.Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    local function setToggle(value, animate)
        element.Value = value
        local th = Theme.GetCurrent()
        if value then
            if animate ~= false then
                p.Tween(toggleContainer, {BackgroundColor3 = th.ToggleOn}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                p.Tween(knob, {Position = UDim2.new(1, -29, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                -- Spring overshoot
                p.Tween(knob, {Size = UDim2.new(0, 31, 0, 25)}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                task.delay(0.1, function()
                    p.Tween(knob, {Size = UDim2.new(0, 27, 0, 27)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end)
            else
                toggleContainer.BackgroundColor3 = th.ToggleOn
                knob.Position = UDim2.new(1, -29, 0.5, 0)
            end
        else
            if animate ~= false then
                p.Tween(toggleContainer, {BackgroundColor3 = th.ToggleOff}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                p.Tween(knob, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                p.Tween(knob, {Size = UDim2.new(0, 31, 0, 25)}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                task.delay(0.1, function()
                    p.Tween(knob, {Size = UDim2.new(0, 27, 0, 27)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end)
            else
                toggleContainer.BackgroundColor3 = th.ToggleOff
                knob.Position = UDim2.new(0, 2, 0.5, 0)
            end
        end
        element.Callback(value)
    end

    clickArea.MouseButton1Click:Connect(function()
        if not element.Locked then
            setToggle(not element.Value)
        end
    end)

    -- Set initial value
    setToggle(config.Default, false)

    -- Theme handling
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if element.Value then
            p.Tween(toggleContainer, {BackgroundColor3 = th.ToggleOn}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            p.Tween(toggleContainer, {BackgroundColor3 = th.ToggleOff}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        setToggle(value)
    end

    function element:Lock()
        self.Locked = true
        p.Tween(toggleContainer, {BackgroundTransparency = 0.5}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    function element:Unlock()
        self.Locked = false
        p.Tween(toggleContainer, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- SLIDER
-- ============================================================

function ElementClass.Slider(section, config)
    config = config or {}
    config.Title = config.Title or "Slider"
    config.Value = config.Value or {}
    config.Value.Min = config.Value.Min or 0
    config.Value.Max = config.Value.Max or 100
    config.Value.Default = config.Value.Default or 50
    config.Value.Step = config.Value.Step or 1
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1
    config.Suffix = config.Suffix or ""

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Slider"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Value.Default
    element.Min = config.Value.Min
    element.Max = config.Value.Max
    element.Step = config.Value.Step
    element.Callback = config.Callback

    local row = createElementRow(section, {
        Name = "Slider_" .. config.Title,
        Order = config.Order,
        Height = 56
    })
    element.Row = row

    -- Title + Value label row
    local topRow = p.Create("Frame", {
        Name = "TopRow",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = row
    })

    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.6, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = topRow
    })
    element.TitleLabel = titleLabel

    local valueLabel = p.CreateLabel({
        Name = "ValueLabel",
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        Text = tostring(config.Value.Default) .. config.Suffix,
        TextColor3 = theme.Accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = topRow
    })
    element.ValueLabel = valueLabel

    -- Slider track
    local sliderTrack = p.Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderTrack})
    element.Track = sliderTrack

    -- Slider fill
    local defaultPercent = (config.Value.Default - config.Value.Min) / (config.Value.Max - config.Value.Min)
    local sliderFill = p.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(defaultPercent, 0, 1, 0),
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel = 0,
        Parent = sliderTrack
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderFill})
    element.Fill = sliderFill

    -- Slider knob
    local knobSize = 20
    local sliderKnob = p.Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, knobSize, 0, knobSize),
        Position = UDim2.new(defaultPercent, -knobSize/2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = sliderTrack.ZIndex + 2,
        Parent = sliderTrack
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderKnob})
    -- Knob shadow
    p.Create("ImageLabel", {
        Name = "Shadow",
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0, -2, 0, -1),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.75,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = sliderKnob
    })
    element.Knob = sliderKnob

    -- Interaction area
    local interactionArea = p.Create("TextButton", {
        Name = "Interaction",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    local dragging = false

    local function updateSlider(input)
        local relX = input.Position.X - sliderTrack.AbsolutePosition.X
        local trackWidth = sliderTrack.AbsoluteSize.X
        local percent = p.Clamp(relX / trackWidth, 0, 1)
        local rawValue = config.Value.Min + (config.Value.Max - config.Value.Min) * percent
        local steppedValue = p.Round(rawValue / config.Value.Step) * config.Value.Step
        steppedValue = p.Clamp(steppedValue, config.Value.Min, config.Value.Max)
        local newPercent = (steppedValue - config.Value.Min) / (config.Value.Max - config.Value.Min)

        element.Value = steppedValue
        p.Tween(sliderFill, {Size = UDim2.new(newPercent, 0, 1, 0)}, 0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        p.Tween(sliderKnob, {Position = UDim2.new(newPercent, -knobSize/2, 0.5, 0)}, 0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        valueLabel.Text = tostring(steppedValue) .. config.Suffix
        element.Callback(steppedValue)
    end

    interactionArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
            -- Enlarge knob on drag
            p.Tween(sliderKnob, {Size = UDim2.new(0, knobSize + 6, 0, knobSize + 6)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    p.Tween(sliderKnob, {Size = UDim2.new(0, knobSize, 0, knobSize)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    -- Theme handling
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(valueLabel, {TextColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderTrack, {BackgroundColor3 = th.SliderTrack}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderFill, {BackgroundColor3 = th.SliderFill}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        value = p.Clamp(value, config.Value.Min, config.Value.Max)
        value = p.Round(value / config.Value.Step) * config.Value.Step
        self.Value = value
        local pct = (value - config.Value.Min) / (config.Value.Max - config.Value.Min)
        p.Tween(sliderFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderKnob, {Position = UDim2.new(pct, -knobSize/2, 0.5, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        valueLabel.Text = tostring(value) .. config.Suffix
        self.Callback(value)
    end

    function element:Lock()
        self.Locked = true
        p.Tween(sliderKnob, {BackgroundTransparency = 0.5}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    function element:Unlock()
        self.Locked = false
        p.Tween(sliderKnob, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    table.insert(section.Elements, element)
    return element
end


-- ============================================================
-- DROPDOWN
-- ============================================================

function ElementClass.Dropdown(section, config)
    config = config or {}
    config.Title = config.Title or "Dropdown"
    config.Options = config.Options or {}
    config.Default = config.Default or nil
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1
    config.Placeholder = config.Placeholder or "Select..."

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Dropdown"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Options = config.Options
    element.Callback = config.Callback
    element.IsOpen = false

    local row = createElementRow(section, {
        Name = "Dropdown_" .. config.Title,
        Order = config.Order,
        Height = 42
    })
    element.Row = row

    -- Title label
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Selected value label
    local valueLabel = p.CreateLabel({
        Name = "ValueLabel",
        Size = UDim2.new(0.4, -20, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Text = config.Default or config.Placeholder,
        TextColor3 = theme.TextSecondary,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row
    })
    element.ValueLabel = valueLabel

    -- Chevron
    local chevron = Icons.Create("chevron_down", {
        Size = 14,
        Position = UDim2.new(1, -4, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Color = theme.TextSecondary,
        Parent = row
    })
    element.Chevron = chevron

    -- Dropdown popup (created in window frame for z-index)
    local dropdownPopup = nil
    local optionButtons = {}

    local function closeDropdown()
        if not element.IsOpen then return end
        element.IsOpen = false
        if dropdownPopup then
            p.Tween(dropdownPopup, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                dropdownPopup.Visible = false
            end)
            p.Tween(chevron, {Rotation = 0}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end

    local function openDropdown()
        if element.IsOpen or element.Locked then return end
        element.IsOpen = true

        if not dropdownPopup then
            dropdownPopup = p.CreateCardFrame({
                Name = "DropdownPopup",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 1, 2),
                BackgroundColor3 = theme.DropdownBackground,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 100,
                Parent = row
            })
            p.Create("UIStroke", {
                Color = theme.Border,
                Transparency = 0.5,
                Thickness = 0.5,
                Parent = dropdownPopup
            })
            local popupLayout = p.Create("UIListLayout", {
                Padding = UDim.new(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = dropdownPopup
            })

            -- Create option buttons
            for i, opt in ipairs(config.Options) do
                local optBtn = p.Create("TextButton", {
                    Name = "Option_" .. tostring(opt),
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                    ZIndex = 101,
                    Parent = dropdownPopup
                })

                local optLabel = p.CreateLabel({
                    Name = "Label",
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.new(0, 14, 0, 0),
                    Text = tostring(opt),
                    TextColor3 = theme.TextPrimary,
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    Parent = optBtn
                })

                -- Check icon for selected option
                local checkIcon = Icons.Create("check", {
                    Size = 14,
                    Position = UDim2.new(1, -14, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Color = theme.Accent,
                    Parent = optBtn
                })
                checkIcon.Visible = (opt == element.Value)

                optBtn.MouseButton1Click:Connect(function()
                    element.Value = opt
                    valueLabel.Text = tostring(opt)
                    valueLabel.TextColor3 = theme.Accent
                    -- Update check icons
                    for _, btn in ipairs(optionButtons) do
                        if btn._CheckIcon then
                            btn._CheckIcon.Visible = (btn._OptionValue == opt)
                        end
                    end
                    config.Callback(opt)
                    closeDropdown()
                end)

                optBtn.MouseEnter:Connect(function()
                    p.Tween(optBtn, {BackgroundColor3 = theme.DropdownHover, BackgroundTransparency = 0}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end)
                optBtn.MouseLeave:Connect(function()
                    p.Tween(optBtn, {BackgroundTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end)

                -- Divider between options (not after last)
                if i < #config.Options then
                    local optDivider = p.Create("Frame", {
                        Name = "Divider",
                        Size = UDim2.new(1, -28, 0, 0.5),
                        Position = UDim2.new(0, 14, 1, 0),
                        BackgroundColor3 = theme.Divider,
                        BackgroundTransparency = 0.3,
                        BorderSizePixel = 0,
                        ZIndex = 101,
                        Parent = optBtn
                    })
                end

                optBtn._OptionValue = opt
                optBtn._CheckIcon = checkIcon
                table.insert(optionButtons, optBtn)
            end
        end

        dropdownPopup.Visible = true
        dropdownPopup.Size = UDim2.new(1, 0, 0, 0)
        dropdownPopup.BackgroundTransparency = 1
        local targetHeight = #config.Options * 34
        p.Tween(dropdownPopup, {Size = UDim2.new(1, 0, 0, targetHeight), BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        p.Tween(chevron, {Rotation = 180}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end

    -- Click to toggle
    local clickArea = p.Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = row.ZIndex + 1,
        Parent = row
    })

    clickArea.MouseButton1Click:Connect(function()
        if element.IsOpen then
            closeDropdown()
        else
            openDropdown()
        end
    end)

    -- Close when clicking elsewhere
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if element.IsOpen and dropdownPopup then
                local mousePos = input.Position
                local popupPos = dropdownPopup.AbsolutePosition
                local popupSize = dropdownPopup.AbsoluteSize
                local rowPos = row.AbsolutePosition
                local rowSize = row.AbsoluteSize
                local inPopup = mousePos.X >= popupPos.X and mousePos.X <= popupPos.X + popupSize.X
                    and mousePos.Y >= popupPos.Y and mousePos.Y <= popupPos.Y + popupSize.Y
                local inRow = mousePos.X >= rowPos.X and mousePos.X <= rowPos.X + rowSize.X
                    and mousePos.Y >= rowPos.Y and mousePos.Y <= rowPos.Y + rowSize.Y
                if not inPopup and not inRow then
                    closeDropdown()
                end
            end
        end
    end)

    -- Theme handling
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(valueLabel, {TextColor3 = element.Value and th.Accent or th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(chevron, {ImageColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if dropdownPopup then
            p.Tween(dropdownPopup, {BackgroundColor3 = th.DropdownBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        for _, btn in ipairs(optionButtons) do
            if btn:FindFirstChild("Label") then
                p.Tween(btn.Label, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
            if btn._CheckIcon then
                p.Tween(btn._CheckIcon, {ImageColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        self.Value = value
        valueLabel.Text = tostring(value)
        valueLabel.TextColor3 = Theme.GetCurrent().Accent
        for _, btn in ipairs(optionButtons) do
            if btn._CheckIcon then
                btn._CheckIcon.Visible = (btn._OptionValue == value)
            end
        end
        self.Callback(value)
    end

    function element:SetOptions(newOptions)
        self.Options = newOptions
        -- Destroy existing popup and recreate on next open
        if dropdownPopup then
            dropdownPopup:Destroy()
            dropdownPopup = nil
        end
        optionButtons = {}
        config.Options = newOptions
    end

    function element:Lock()
        self.Locked = true
        closeDropdown()
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- INPUT
-- ============================================================

function ElementClass.Input(section, config)
    config = config or {}
    config.Title = config.Title or "Input"
    config.Placeholder = config.Placeholder or "Type here..."
    config.Default = config.Default or ""
    config.Callback = config.Callback or function() end
    config.ClearOnFocus = config.ClearOnFocus or false
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Input"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Callback = config.Callback

    local row = createElementRow(section, {
        Name = "Input_" .. config.Title,
        Order = config.Order,
        Height = 68
    })
    element.Row = row

    -- Title label
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 18),
        Text = config.Title,
        TextColor3 = theme.TextSecondary,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Input container
    local inputContainer = p.Create("Frame", {
        Name = "InputContainer",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundColor3 = theme.InputBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = inputContainer})
    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.6,
        Thickness = 0.5,
        Parent = inputContainer
    })
    element.InputContainer = inputContainer

    -- Text box
    local textBox = p.Create("TextBox", {
        Name = "TextBox",
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = config.Default,
        PlaceholderText = config.Placeholder,
        PlaceholderColor3 = theme.Placeholder,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = config.ClearOnFocus,
        Parent = inputContainer
    })
    element.TextBox = textBox

    -- Focus effects
    textBox.Focused:Connect(function()
        p.Tween(inputContainer, {
            BackgroundTransparency = 0,
            Size = UDim2.new(1, 0, 0, 38)
        }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        -- Highlight border with accent
        local stroke = inputContainer:FindFirstChildOfClass("UIStroke")
        if stroke then
            p.Tween(stroke, {Color = theme.Accent, Transparency = 0.3}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        p.Tween(inputContainer, {
            BackgroundTransparency = 0.3,
            Size = UDim2.new(1, 0, 0, 36)
        }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local stroke = inputContainer:FindFirstChildOfClass("UIStroke")
        if stroke then
            local th = Theme.GetCurrent()
            p.Tween(stroke, {Color = th.Border, Transparency = 0.6}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
        element.Value = textBox.Text
        element.Callback(textBox.Text)
    end)

    -- Theme handling
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(inputContainer, {BackgroundColor3 = th.InputBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(textBox, {TextColor3 = th.TextPrimary, PlaceholderColor3 = th.Placeholder}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        self.Value = value
        textBox.Text = value
    end

    function element:Lock()
        self.Locked = true
        textBox.ClearTextOnFocus = false
        textBox.TextEditable = false
        p.Tween(inputContainer, {BackgroundTransparency = 0.5}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    function element:Unlock()
        self.Locked = false
        textBox.TextEditable = true
        p.Tween(inputContainer, {BackgroundTransparency = 0.3}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- CHECKBOX
-- ============================================================

function ElementClass.Checkbox(section, config)
    config = config or {}
    config.Title = config.Title or "Checkbox"
    config.Default = config.Default or false
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Checkbox"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Callback = config.Callback

    local row = createElementRow(section, {
        Name = "Checkbox_" .. config.Title,
        Order = config.Order
    })
    element.Row = row

    -- Checkbox box
    local checkboxSize = 22
    local checkbox = p.Create("Frame", {
        Name = "Checkbox",
        Size = UDim2.new(0, checkboxSize, 0, checkboxSize),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = config.Default and theme.Accent or theme.InputBackground,
        BackgroundTransparency = config.Default and 0 or 0.3,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = checkbox})
    p.Create("UIStroke", {
        Color = config.Default and theme.Accent or theme.Border,
        Transparency = 0,
        Thickness = 1.5,
        Parent = checkbox
    })
    element.Checkbox = checkbox

    -- Check icon
    local checkIcon = Icons.Create("check", {
        Size = 14,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Color = theme.CheckboxCheck,
        Transparency = config.Default and 0 or 1,
        Parent = checkbox
    })
    element.CheckIcon = checkIcon

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, -checkboxSize - 10, 1, 0),
        Position = UDim2.new(0, checkboxSize + 10, 0, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Click area
    local clickArea = p.Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    local function setCheckbox(value, animate)
        element.Value = value
        local th = Theme.GetCurrent()
        local stroke = checkbox:FindFirstChildOfClass("UIStroke")
        if value then
            if animate ~= false then
                p.Tween(checkbox, {BackgroundColor3 = th.Accent, BackgroundTransparency = 0}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                p.Tween(checkIcon, {ImageTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                if stroke then p.Tween(stroke, {Color = th.Accent}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) end
                -- Scale bounce
                p.Tween(checkbox, {Size = UDim2.new(0, checkboxSize + 4, 0, checkboxSize + 4)}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                task.delay(0.1, function()
                    p.Tween(checkbox, {Size = UDim2.new(0, checkboxSize, 0, checkboxSize)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end)
            else
                checkbox.BackgroundColor3 = th.Accent
                checkbox.BackgroundTransparency = 0
                checkIcon.ImageTransparency = 0
                if stroke then stroke.Color = th.Accent end
            end
        else
            if animate ~= false then
                p.Tween(checkbox, {BackgroundColor3 = th.InputBackground, BackgroundTransparency = 0.3}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                p.Tween(checkIcon, {ImageTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                if stroke then p.Tween(stroke, {Color = th.Border}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) end
            else
                checkbox.BackgroundColor3 = th.InputBackground
                checkbox.BackgroundTransparency = 0.3
                checkIcon.ImageTransparency = 1
                if stroke then stroke.Color = th.Border end
            end
        end
        element.Callback(value)
    end

    clickArea.MouseButton1Click:Connect(function()
        if not element.Locked then
            setCheckbox(not element.Value)
        end
    end)

    -- Set initial
    setCheckbox(config.Default, false)

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if element.Value then
            p.Tween(checkbox, {BackgroundColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            p.Tween(checkIcon, {ImageColor3 = th.CheckboxCheck}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        else
            p.Tween(checkbox, {BackgroundColor3 = th.InputBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        setCheckbox(value)
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- KEYBIND
-- ============================================================

function ElementClass.Keybind(section, config)
    config = config or {}
    config.Title = config.Title or "Keybind"
    config.Default = config.Default or Enum.KeyCode.Unknown
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Keybind"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Callback = config.Callback
    element.Listening = false

    local row = createElementRow(section, {
        Name = "Keybind_" .. config.Title,
        Order = config.Order
    })
    element.Row = row

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.6, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Key display button
    local keyName = config.Default ~= Enum.KeyCode.Unknown and config.Default.Name or "None"
    local keyBtn = p.Create("TextButton", {
        Name = "KeyButton",
        Size = UDim2.new(0.35, 0, 0, 26),
        Position = UDim2.new(1, -4, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0.3,
        Text = keyName,
        TextColor3 = theme.TextSecondary,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = keyBtn})
    element.KeyButton = keyBtn

    keyBtn.MouseButton1Click:Connect(function()
        if element.Locked then return end
        element.Listening = true
        keyBtn.Text = "..."
        p.Tween(keyBtn, {BackgroundColor3 = theme.Accent, TextColor3 = theme.AccentText}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if element.Listening then
            element.Listening = false
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                element.Value = input.KeyCode
                keyBtn.Text = input.KeyCode.Name
                element.Callback(input.KeyCode)
            end
            local th = Theme.GetCurrent()
            p.Tween(keyBtn, {BackgroundColor3 = th.CardBackground, TextColor3 = th.TextSecondary}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        elseif input.KeyCode == element.Value then
            element.Callback(input.KeyCode)
            -- Flash effect
            p.Tween(keyBtn, {BackgroundColor3 = theme.Accent}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            task.delay(0.2, function()
                local th = Theme.GetCurrent()
                p.Tween(keyBtn, {BackgroundColor3 = th.CardBackground}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
        end
    end)

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if not element.Listening then
            p.Tween(keyBtn, {BackgroundColor3 = th.CardBackground, TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(keyCode)
        self.Value = keyCode
        keyBtn.Text = keyCode.Name
        self.Callback(keyCode)
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end


-- ============================================================
-- COLOR PICKER
-- ============================================================

function ElementClass.ColorPicker(section, config)
    config = config or {}
    config.Title = config.Title or "Color Picker"
    config.Default = config.Default or Color3.fromRGB(0, 122, 255)
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "ColorPicker"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Callback = config.Callback
    element.IsOpen = false

    local row = createElementRow(section, {
        Name = "ColorPicker_" .. config.Title,
        Order = config.Order
    })
    element.Row = row

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.6, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Color preview
    local colorPreview = p.Create("Frame", {
        Name = "Preview",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -4, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = config.Default,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = colorPreview})
    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.5,
        Thickness = 1,
        Parent = colorPreview
    })
    element.ColorPreview = colorPreview

    -- Click to open
    local clickArea = p.Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    -- Picker popup
    local pickerPopup = nil
    local hueBar = nil
    local satValBox = nil
    local hueMarker = nil
    local svMarker = nil

    local function createPicker()
        pickerPopup = p.CreateCardFrame({
            Name = "PickerPopup",
            Size = UDim2.new(1, 0, 0, 200),
            Position = UDim2.new(0, 0, 1, 4),
            BackgroundColor3 = theme.DropdownBackground,
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 100,
            Parent = row
        })
        p.Create("UIStroke", {
            Color = theme.Border,
            Transparency = 0.5,
            Thickness = 0.5,
            Parent = pickerPopup
        })

        -- Saturation-Value box
        satValBox = p.Create("ImageLabel", {
            Name = "SatValBox",
            Size = UDim2.new(1, -40, 0, 150),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = pickerPopup
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = satValBox})

        -- White gradient (left to right)
        local whiteGradient = p.Create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            }),
            Rotation = 0,
            Parent = satValBox
        })

        -- Black gradient (top to bottom)
        local blackGradient = p.Create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0)
            }),
            Rotation = 90,
            Parent = satValBox
        })

        -- SV Marker
        svMarker = p.Create("Frame", {
            Name = "SVMarker",
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0.5, -7, 0.5, -7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 102,
            Parent = satValBox
        })
        p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = svMarker})
        p.Create("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 1.5,
            Parent = svMarker
        })

        -- Hue bar
        hueBar = p.Create("ImageLabel", {
            Name = "HueBar",
            Size = UDim2.new(0, 18, 0, 150),
            Position = UDim2.new(1, -28, 0, 10),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = pickerPopup
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 9), Parent = hueBar})

        -- Hue gradient
        local hueGradient = p.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            }),
            Rotation = 90,
            Parent = hueBar
        })

        -- Hue marker
        hueMarker = p.Create("Frame", {
            Name = "HueMarker",
            Size = UDim2.new(0, 22, 0, 8),
            Position = UDim2.new(0.5, -11, 0, -2),
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 102,
            Parent = hueBar
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = hueMarker})
        p.Create("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 1,
            Parent = hueMarker
        })

        -- RGB display
        local rgbLabel = p.CreateLabel({
            Name = "RGBLabel",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0, 10, 0, 168),
            Text = "RGB: " .. tostring(math.floor(config.Default.R*255)) .. ", " .. tostring(math.floor(config.Default.G*255)) .. ", " .. tostring(math.floor(config.Default.B*255)),
            TextColor3 = theme.TextSecondary,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            Parent = pickerPopup
        })
        element.RGBLabel = rgbLabel

        -- SV dragging
        local svDragging = false
        satValBox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                svDragging = true
                local relX = p.Clamp((input.Position.X - satValBox.AbsolutePosition.X) / satValBox.AbsoluteSize.X, 0, 1)
                local relY = p.Clamp((input.Position.Y - satValBox.AbsolutePosition.Y) / satValBox.AbsoluteSize.Y, 0, 1)
                svMarker.Position = UDim2.new(relX, -7, relY, -7)
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then svDragging = false end
                end)
            end
        end)

        -- Hue dragging
        local hueDragging = false
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                hueDragging = true
                local relY = p.Clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                hueMarker.Position = UDim2.new(0.5, -11, relY, -4)
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then hueDragging = false end
                end)
            end
        end)

        -- Update color on drag
        RunService.RenderStepped:Connect(function()
            if not pickerPopup or not pickerPopup.Parent then return end
            if svDragging or hueDragging then
                local svX = p.Clamp((svMarker.Position.X.Offset + 7) / satValBox.AbsoluteSize.X, 0, 1)
                local svY = p.Clamp((svMarker.Position.Y.Offset + 7) / satValBox.AbsoluteSize.Y, 0, 1)
                local hueY = p.Clamp((hueMarker.Position.Y.Offset + 4) / hueBar.AbsoluteSize.Y, 0, 1)

                local hue = hueY * 360
                local c = Color3.fromHSV(hue / 360, svX, 1 - svY)
                satValBox.BackgroundColor3 = Color3.fromHSV(hue / 360, 1, 1)
                colorPreview.BackgroundColor3 = c
                element.Value = c
                rgbLabel.Text = "RGB: " .. math.floor(c.R*255) .. ", " .. math.floor(c.G*255) .. ", " .. math.floor(c.B*255)
                element.Callback(c)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local relX = p.Clamp((input.Position.X - satValBox.AbsolutePosition.X) / satValBox.AbsoluteSize.X, 0, 1)
                local relY = p.Clamp((input.Position.Y - satValBox.AbsolutePosition.Y) / satValBox.AbsoluteSize.Y, 0, 1)
                svMarker.Position = UDim2.new(relX, -7, relY, -7)
            end
            if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local relY = p.Clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                hueMarker.Position = UDim2.new(0.5, -11, relY, -4)
            end
        end)
    end

    local function openPicker()
        if element.IsOpen or element.Locked then return end
        element.IsOpen = true
        if not pickerPopup then createPicker() end
        pickerPopup.Visible = true
        pickerPopup.Size = UDim2.new(1, 0, 0, 0)
        p.Tween(pickerPopup, {Size = UDim2.new(1, 0, 0, 200)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    local function closePicker()
        if not element.IsOpen then return end
        element.IsOpen = false
        if pickerPopup then
            p.Tween(pickerPopup, {Size = UDim2.new(1, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                pickerPopup.Visible = false
            end)
        end
    end

    clickArea.MouseButton1Click:Connect(function()
        if element.IsOpen then
            closePicker()
        else
            openPicker()
        end
    end)

    -- Close when clicking elsewhere
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if element.IsOpen and pickerPopup then
                local mousePos = input.Position
                local popupPos = pickerPopup.AbsolutePosition
                local popupSize = pickerPopup.AbsoluteSize
                local inPopup = mousePos.X >= popupPos.X and mousePos.X <= popupPos.X + popupSize.X
                    and mousePos.Y >= popupPos.Y and mousePos.Y <= popupPos.Y + popupSize.Y
                local rowPos = row.AbsolutePosition
                local rowSize = row.AbsoluteSize
                local inRow = mousePos.X >= rowPos.X and mousePos.X <= rowPos.X + rowSize.X
                    and mousePos.Y >= rowPos.Y and mousePos.Y <= rowPos.Y + rowSize.Y
                if not inPopup and not inRow then
                    closePicker()
                end
            end
        end
    end)

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if pickerPopup then
            p.Tween(pickerPopup, {BackgroundColor3 = th.DropdownBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if element.RGBLabel then
                p.Tween(element.RGBLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(color)
        self.Value = color
        colorPreview.BackgroundColor3 = color
        self.Callback(color)
    end

    function element:Lock()
        self.Locked = true
        closePicker()
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- PARAGRAPH
-- ============================================================

function ElementClass.Paragraph(section, config)
    config = config or {}
    config.Title = config.Title or "Paragraph"
    config.Content = config.Content or ""
    config.Buttons = config.Buttons or {}
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Paragraph"
    element.Title = config.Title
    element.Locked = false
    element.Content = config.Content

    local row = createElementRow(section, {
        Name = "Paragraph_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    local container = p.Create("Frame", {
        Name = "Container",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = row
    })

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 18),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = container
    })
    element.TitleLabel = titleLabel

    -- Content text
    local contentLabel = p.Create("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = config.Content,
        TextColor3 = theme.TextSecondary,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = container
    })
    element.ContentLabel = contentLabel

    -- Buttons row
    if #config.Buttons > 0 then
        local btnRow = p.Create("Frame", {
            Name = "ButtonRow",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Parent = container
        })
        local btnLayout = p.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = btnRow
        })

        for i, btnConfig in ipairs(config.Buttons) do
            local paraBtn = p.Create("TextButton", {
                Name = "Btn_" .. (btnConfig.Title or "Button"),
                Size = UDim2.new(0, 80, 0, 28),
                BackgroundColor3 = btnConfig.Color and p.Color3FromHex(btnConfig.Color) or theme.Accent,
                BackgroundTransparency = 0.15,
                Text = btnConfig.Title or "Button",
                TextColor3 = theme.AccentText,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = btnRow
            })
            p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = paraBtn})

            if btnConfig.Callback then
                paraBtn.MouseButton1Click:Connect(function()
                    if not element.Locked then
                        btnConfig.Callback()
                    end
                end)
            end

            paraBtn.MouseEnter:Connect(function()
                p.Tween(paraBtn, {BackgroundTransparency = 0}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
            paraBtn.MouseLeave:Connect(function()
                p.Tween(paraBtn, {BackgroundTransparency = 0.15}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
        end
    end

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(contentLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetContent(newContent)
        self.Content = newContent
        contentLabel.Text = newContent
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- DIVIDER
-- ============================================================

function ElementClass.Divider(section, config)
    config = config or {}
    config.Title = config.Title or ""
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Divider"
    element.Title = config.Title
    element.Locked = false

    local rowHeight = config.Title ~= "" and 30 or 14
    local row = createElementRow(section, {
        Name = "Divider",
        Order = config.Order,
        Height = rowHeight
    })
    element.Row = row

    if config.Title ~= "" then
        -- Labeled divider
        local label = p.CreateLabel({
            Name = "Label",
            Size = UDim2.new(1, 0, 1, 0),
            Text = config.Title,
            TextColor3 = theme.TextTertiary,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            Parent = row
        })
        element.Label = label
    end

    local dividerLine = p.Create("Frame", {
        Name = "Line",
        Size = UDim2.new(1, 0, 0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = theme.Divider,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = row
    })
    element.Line = dividerLine

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(dividerLine, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if element.Label then
            p.Tween(element.Label, {TextColor3 = th.TextTertiary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        if element.Label then element.Label.Text = newTitle end
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- CODE
-- ============================================================

function ElementClass.Code(section, config)
    config = config or {}
    config.Title = config.Title or "Code"
    config.Content = config.Content or ""
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Code"
    element.Title = config.Title
    element.Locked = false
    element.Content = config.Content

    local row = createElementRow(section, {
        Name = "Code_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    -- Title
    if config.Title ~= "" then
        local titleLabel = p.CreateLabel({
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 16),
            Text = config.Title,
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            Parent = row
        })
        element.TitleLabel = titleLabel
    end

    -- Code container
    local codeFrame = p.Create("Frame", {
        Name = "CodeFrame",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.CodeBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = codeFrame})
    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.7,
        Thickness = 0.5,
        Parent = codeFrame
    })

    local codePadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = codeFrame
    })

    local codeText = p.Create("TextLabel", {
        Name = "CodeText",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = config.Content,
        TextColor3 = theme.CodeText,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = codeFrame
    })
    element.CodeText = codeText

    -- Copy button
    local copyBtn = p.Create("TextButton", {
        Name = "CopyBtn",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -8, 0, 8),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0.3,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = codeFrame.ZIndex + 1,
        Parent = codeFrame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = copyBtn})
    local copyIcon = Icons.Create("copy", {Size = 12, Color = theme.TextSecondary, Parent = copyBtn})
    copyIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    copyIcon.AnchorPoint = Vector2.new(0.5, 0.5)

    copyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            setclipboard(config.Content)
        end)
        -- Flash feedback
        p.Tween(copyBtn, {BackgroundColor3 = theme.Success}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.delay(0.5, function()
            p.Tween(copyBtn, {BackgroundColor3 = theme.CardBackground}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
    end)

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(codeFrame, {BackgroundColor3 = th.CodeBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(codeText, {TextColor3 = th.CodeText}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if element.TitleLabel then
            p.Tween(element.TitleLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        if element.TitleLabel then element.TitleLabel.Text = newTitle end
    end

    function element:SetContent(newContent)
        self.Content = newContent
        codeText.Text = newContent
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- IMAGE
-- ============================================================

function ElementClass.Image(section, config)
    config = config or {}
    config.Title = config.Title or "Image"
    config.Source = config.Source or ""
    config.Size = config.Size or UDim2.new(1, 0, 0, 150)
    config.CornerRadius = config.CornerRadius or 10
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Image"
    element.Title = config.Title
    element.Locked = false

    local row = createElementRow(section, {
        Name = "Image_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    -- Title
    if config.Title ~= "" then
        local titleLabel = p.CreateLabel({
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 16),
            Text = config.Title,
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            Parent = row
        })
        element.TitleLabel = titleLabel
    end

    -- Image
    local imageLabel = p.Create("ImageLabel", {
        Name = "Image",
        Size = config.Size,
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Image = config.Source,
        ScaleType = Enum.ScaleType.Fit,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, config.CornerRadius), Parent = imageLabel})
    element.ImageLabel = imageLabel

    -- Theme
    Theme.OnChanged(function(th)
        if element.TitleLabel then
            p.Tween(element.TitleLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        if element.TitleLabel then element.TitleLabel.Text = newTitle end
    end

    function element:SetSource(source)
        imageLabel.Image = source
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- GROUP
-- ============================================================

function ElementClass.Group(section, config)
    config = config or {}
    config.Title = config.Title or "Group"
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Group"
    element.Title = config.Title
    element.Locked = false
    element.Elements = {}

    local row = createElementRow(section, {
        Name = "Group_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    -- Group container with card style
    local groupFrame = p.CreateCardFrame({
        Name = "GroupCard",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0.5,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = row
    })
    element.GroupFrame = groupFrame

    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.7,
        Thickness = 0.5,
        Parent = groupFrame
    })

    -- Title
    if config.Title ~= "" then
        local groupTitle = p.CreateLabel({
            Name = "GroupTitle",
            Size = UDim2.new(1, 0, 0, 24),
            Text = config.Title,
            TextColor3 = theme.SectionHeader,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            Parent = groupFrame
        })
        local titlePad = p.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 6),
            Parent = groupTitle
        })
        element.GroupTitleLabel = groupTitle
    end

    local groupLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = groupFrame
    })

    local groupPadding = p.Create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 6),
        Parent = groupFrame
    })

    -- Group methods - same as section but nested
    function element:Button(btnConfig)
        return ElementClass.Button({CardFrame = groupFrame, Elements = self.Elements}, btnConfig)
    end

    function element:Toggle(toggleConfig)
        return ElementClass.Toggle({CardFrame = groupFrame, Elements = self.Elements}, toggleConfig)
    end

    function element:Slider(sliderConfig)
        return ElementClass.Slider({CardFrame = groupFrame, Elements = self.Elements}, sliderConfig)
    end

    function element:Dropdown(dropdownConfig)
        return ElementClass.Dropdown({CardFrame = groupFrame, Elements = self.Elements}, dropdownConfig)
    end

    function element:Input(inputConfig)
        return ElementClass.Input({CardFrame = groupFrame, Elements = self.Elements}, inputConfig)
    end

    function element:Checkbox(checkConfig)
        return ElementClass.Checkbox({CardFrame = groupFrame, Elements = self.Elements}, checkConfig)
    end

    function element:Divider(divConfig)
        return ElementClass.Divider({CardFrame = groupFrame, Elements = self.Elements}, divConfig or {})
    end

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(groupFrame, {BackgroundColor3 = th.CardBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if element.GroupTitleLabel then
            p.Tween(element.GroupTitleLabel, {TextColor3 = th.SectionHeader}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        if element.GroupTitleLabel then element.GroupTitleLabel.Text = newTitle end
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end


-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================

NotificationSystem.Queue = {}
NotificationSystem.ActiveCount = 0
NotificationSystem.MaxActive = 5
NotificationSystem.Container = nil

function NotificationSystem:GetContainer(window)
    if not self.Container or not self.Container.Parent then
        local screenGui = window.ScreenGui
        self.Container = p.Create("Frame", {
            Name = "NotificationContainer",
            Size = UDim2.new(0, 340, 1, 0),
            Position = UDim2.new(1, -20, 0, 20),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 200,
            Parent = screenGui
        })
        p.Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Parent = self.Container
        })
    end
    return self.Container
end

function NotificationSystem:Create(window, config)
    config = config or {}
    config.Title = config.Title or "Notification"
    config.Content = config.Content or ""
    config.Duration = config.Duration or 5
    config.Icon = config.Icon or nil
    config.Buttons = config.Buttons or {}
    config.Style = config.Style or "Info" -- Info, Success, Warning, Danger

    local theme = Theme.GetCurrent()
    local container = self:GetContainer(window)

    local notif = {}
    notif.Window = window
    notif.Closed = false

    -- Notification frame (Liquid Glass)
    local notifFrame = p.CreateGlassFrame({
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.NotificationBackground,
        BackgroundTransparency = 0.05,
        CornerRadius = UDim.new(0, 14),
        Border = true,
        Shadow = true,
        Parent = container
    })
    notif.Frame = notifFrame

    -- Auto-size
    local notifLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = notifFrame
    })

    local notifPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14),
        Parent = notifFrame
    })

    -- Top row: icon + title + close
    local topRow = p.Create("Frame", {
        Name = "TopRow",
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Parent = notifFrame
    })

    -- Style color
    local styleColors = {
        Info = theme.Info,
        Success = theme.Success,
        Warning = theme.Warning,
        Danger = theme.Danger
    }
    local styleColor = styleColors[config.Style] or theme.Info

    -- Accent dot
    local accentDot = p.Create("Frame", {
        Name = "AccentDot",
        Size = UDim2.new(0, 8, 0, 8),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = styleColor,
        BorderSizePixel = 0,
        Parent = topRow
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = accentDot})

    -- Icon
    local iconOffset = 0
    if config.Icon then
        local notifIcon = Icons.Create(config.Icon, {
            Size = 16,
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Color = styleColor,
            Parent = topRow
        })
        iconOffset = 24
    end

    -- Title
    local notifTitle = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, -iconOffset - 30, 1, 0),
        Position = UDim2.new(0, 14 + iconOffset, 0, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = topRow
    })

    -- Close button
    local closeBtn = p.Create("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        Parent = topRow
    })
    local closeIcon = Icons.Create("x", {Size = 12, Color = theme.TextSecondary, Parent = closeBtn})
    closeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)

    -- Content
    if config.Content ~= "" then
        local contentLabel = p.Create("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = config.Content,
            TextColor3 = theme.TextSecondary,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            Parent = notifFrame
        })
    end

    -- Buttons
    if #config.Buttons > 0 then
        local btnRow = p.Create("Frame", {
            Name = "ButtonRow",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            LayoutOrder = 3,
            Parent = notifFrame
        })
        local btnLayout = p.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = btnRow
        })

        for i, btnConf in ipairs(config.Buttons) do
            local nBtn = p.Create("TextButton", {
                Name = "Btn",
                Size = UDim2.new(0, 70, 0, 26),
                BackgroundColor3 = btnConf.Color and p.Color3FromHex(btnConf.Color) or theme.Accent,
                BackgroundTransparency = 0.15,
                Text = btnConf.Title or "OK",
                TextColor3 = theme.AccentText,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = btnRow
            })
            p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = nBtn})
            if btnConf.Callback then
                nBtn.MouseButton1Click:Connect(function()
                    btnConf.Callback()
                    dismissNotification()
                end)
            end
        end
    end

    -- Progress bar
    local progressFrame = p.Create("Frame", {
        Name = "ProgressFrame",
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = theme.Divider,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        LayoutOrder = 10,
        Parent = notifFrame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = progressFrame})

    local progressBar = p.Create("Frame", {
        Name = "Progress",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = styleColor,
        BorderSizePixel = 0,
        Parent = progressFrame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = progressBar})

    -- Dismiss function
    function dismissNotification()
        if notif.Closed then return end
        notif.Closed = true
        p.Tween(notifFrame, {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1
        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
            notifFrame:Destroy()
            NotificationSystem.ActiveCount = math.max(0, NotificationSystem.ActiveCount - 1)
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        dismissNotification()
    end)

    -- Animate in: slide from right with elastic
    notifFrame.Size = UDim2.new(0, 0, 0, 0)
    notifFrame.Position = UDim2.new(1, 0, 0, 0)
    -- First set automatic size off temporarily
    notifFrame.AutomaticSize = Enum.AutomaticSize.Y
    -- Use clipping to animate
    notifFrame.ClipsDescendants = true

    -- Calculate target size by briefly showing
    task.defer(function()
        local targetSize = notifFrame.AbsoluteSize
        notifFrame.Size = UDim2.new(0, 0, 0, 0)
        notifFrame.AutomaticSize = Enum.AutomaticSize.None

        p.Tween(notifFrame, {Size = UDim2.new(1, 0, 0, targetSize.Y)}, 0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
        task.delay(0.5, function()
            notifFrame.AutomaticSize = Enum.AutomaticSize.Y
            notifFrame.Size = UDim2.new(1, 0, 0, 0)
        end)
    end)

    -- Auto dismiss with progress bar
    if config.Duration > 0 then
        local startTime = tick()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if notif.Closed then
                connection:Disconnect()
                return
            end
            local elapsed = tick() - startTime
            local progress = 1 - (elapsed / config.Duration)
            if progress <= 0 then
                connection:Disconnect()
                dismissNotification()
                return
            end
            progressBar.Size = UDim2.new(progress, 0, 1, 0)
        end)
    end

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(notifFrame, {BackgroundColor3 = th.NotificationBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(notifTitle, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)

    self.ActiveCount = self.ActiveCount + 1
    return notif
end

-- ============================================================
-- DIALOG SYSTEM
-- ============================================================

DialogSystem.ActiveDialog = nil

function DialogSystem:Create(window, config)
    config = config or {}
    config.Title = config.Title or "Dialog"
    config.Content = config.Content or ""
    config.Buttons = config.Buttons or {}
    config.Icon = config.Icon or nil

    local theme = Theme.GetCurrent()
    local screenGui = window.ScreenGui

    -- Overlay
    local overlay = p.Create("Frame", {
        Name = "DialogOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.Overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 300,
        Parent = screenGui
    })

    -- Animate overlay
    p.Tween(overlay, {BackgroundTransparency = theme.OverlayTransparency}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    -- Dialog frame
    local dialogWidth = p.IsMobile() and 300 or 340
    local dialogFrame = p.CreateGlassFrame({
        Name = "Dialog",
        Size = UDim2.new(0, dialogWidth, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.DialogBackground,
        BackgroundTransparency = 0,
        CornerRadius = UDim.new(0, 18),
        Border = true,
        Shadow = true,
        ZIndex = 301,
        Parent = overlay
    })
    dialogFrame.AutomaticSize = Enum.AutomaticSize.Y

    local dialogPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 20),
        PaddingBottom = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 20),
        Parent = dialogFrame
    })

    local dialogLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = dialogFrame
    })

    -- Icon
    if config.Icon then
        local dialogIcon = Icons.Create(config.Icon, {
            Size = 32,
            Color = theme.Accent,
            Parent = dialogFrame
        })
    end

    -- Title
    local dialogTitle = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 24),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 1,
        Parent = dialogFrame
    })

    -- Content
    if config.Content ~= "" then
        local dialogContent = p.Create("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = config.Content,
            TextColor3 = theme.TextSecondary,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            Parent = dialogFrame
        })
    end

    -- Buttons
    local btnContainer = p.Create("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = dialogFrame
    })
    local btnLayout = p.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = btnContainer
    })

    local function closeDialog()
        p.Tween(overlay, {BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        p.Tween(dialogFrame, {Size = UDim2.new(0, dialogWidth, 0, 0)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In, function()
            overlay:Destroy()
            self.ActiveDialog = nil
        end)
    end

    if #config.Buttons == 0 then
        -- Default OK button
        local okBtn = p.Create("TextButton", {
            Name = "OK",
            Size = UDim2.new(0, 120, 0, 36),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 0,
            Text = "OK",
            TextColor3 = theme.AccentText,
            TextSize = 15,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Parent = btnContainer
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = okBtn})
        okBtn.MouseButton1Click:Connect(closeDialog)
    else
        for i, btnConf in ipairs(config.Buttons) do
            local dBtn = p.Create("TextButton", {
                Name = btnConf.Title or "Button",
                Size = UDim2.new(0, 120, 0, 36),
                BackgroundColor3 = btnConf.Color and p.Color3FromHex(btnConf.Color) or theme.CardBackground,
                BackgroundTransparency = 0,
                Text = btnConf.Title or "Button",
                TextColor3 = btnConf.Color and theme.AccentText or theme.Accent,
                TextSize = 15,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                LayoutOrder = i,
                Parent = btnContainer
            })
            p.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dBtn})

            dBtn.MouseButton1Click:Connect(function()
                if btnConf.Callback then btnConf.Callback() end
                closeDialog()
            end)
        end
    end

    -- Animate dialog in
    dialogFrame.Size = UDim2.new(0, dialogWidth, 0, 0)
    dialogFrame.AutomaticSize = Enum.AutomaticSize.None
    -- Calculate target height
    task.defer(function()
        dialogFrame.AutomaticSize = Enum.AutomaticSize.Y
        local targetH = dialogFrame.AbsoluteSize.Y
        dialogFrame.AutomaticSize = Enum.AutomaticSize.None
        dialogFrame.Size = UDim2.new(0, dialogWidth, 0, 0)
        p.Tween(dialogFrame, {Size = UDim2.new(0, dialogWidth, 0, targetH)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, function()
            dialogFrame.AutomaticSize = Enum.AutomaticSize.Y
            dialogFrame.Size = UDim2.new(0, dialogWidth, 0, 0)
        end)
    end)

    -- Close overlay on click outside
    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local dialogPos = dialogFrame.AbsolutePosition
            local dialogSize = dialogFrame.AbsoluteSize
            local mousePos = input.Position
            local inDialog = mousePos.X >= dialogPos.X and mousePos.X <= dialogPos.X + dialogSize.X
                and mousePos.Y >= dialogPos.Y and mousePos.Y <= dialogPos.Y + dialogSize.Y
            if not inDialog then
                closeDialog()
            end
        end
    end)

    self.ActiveDialog = overlay
    return {Close = closeDialog, Frame = dialogFrame, Overlay = overlay}
end

-- ============================================================
-- TOOLTIP SYSTEM
-- ============================================================

TooltipSystem.ActiveTooltip = nil

function TooltipSystem:Show(parent, text, position)
    position = position or "Top" -- Top, Bottom, Left, Right
    self:Hide()

    local theme = Theme.GetCurrent()
    local parentAbsPos = parent.AbsolutePosition
    local parentAbsSize = parent.AbsoluteSize

    local tooltipFrame = p.Create("Frame", {
        Name = "Tooltip",
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.TooltipBackground,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 500,
        Parent = parent:FindFirstAncestorOfClass("ScreenGui") or parent:FindFirstAncestorOfClass("LayerCollector")
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = tooltipFrame})
    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.5,
        Thickness = 0.5,
        Parent = tooltipFrame
    })

    local tooltipLabel = p.CreateLabel({
        Name = "Label",
        Size = UDim2.new(0, 0, 0, 0),
        Text = text,
        TextColor3 = theme.TextPrimary,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        AutomaticSize = Enum.AutomaticSize.XY,
        Parent = tooltipFrame
    })

    local tooltipPad = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = tooltipFrame
    })

    -- Arrow (small triangle pointing down)
    local arrow = p.Create("Frame", {
        Name = "Arrow",
        Size = UDim2.new(0, 8, 0, 5),
        BackgroundColor3 = theme.TooltipBackground,
        BorderSizePixel = 0,
        Rotation = 180,
        ZIndex = tooltipFrame.ZIndex + 1,
        Parent = tooltipFrame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = arrow})

    -- Position after render
    task.defer(function()
        local tooltipSize = tooltipFrame.AbsoluteSize
        local centerX = parentAbsPos.X + parentAbsSize.X / 2
        local centerY = parentAbsPos.Y + parentAbsSize.Y / 2

        if position == "Top" then
            tooltipFrame.Position = UDim2.new(0, centerX - tooltipSize.X / 2, 0, parentAbsPos.Y - tooltipSize.Y - 6)
            arrow.Position = UDim2.new(0.5, -4, 1, 0)
            arrow.Rotation = 180
        elseif position == "Bottom" then
            tooltipFrame.Position = UDim2.new(0, centerX - tooltipSize.X / 2, 0, parentAbsPos.Y + parentAbsSize.Y + 6)
            arrow.Position = UDim2.new(0.5, -4, 0, -5)
            arrow.Rotation = 0
        elseif position == "Left" then
            tooltipFrame.Position = UDim2.new(0, parentAbsPos.X - tooltipSize.X - 6, 0, centerY - tooltipSize.Y / 2)
            arrow.Position = UDim2.new(1, 0, 0.5, -4)
            arrow.Rotation = 90
        elseif position == "Right" then
            tooltipFrame.Position = UDim2.new(0, parentAbsPos.X + parentAbsSize.X + 6, 0, centerY - tooltipSize.Y / 2)
            arrow.Position = UDim2.new(0, -5, 0.5, -4)
            arrow.Rotation = -90
        end

        -- Animate in
        local targetPos = tooltipFrame.Position
        local offset = position == "Top" and UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset + 6)
            or position == "Bottom" and UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - 6)
            or targetPos
        tooltipFrame.Position = offset
        tooltipFrame.BackgroundTransparency = 1
        p.Tween(tooltipFrame, {Position = targetPos, BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        p.Tween(tooltipLabel, {TextTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    self.ActiveTooltip = tooltipFrame
    return tooltipFrame
end

function TooltipSystem:Hide()
    if self.ActiveTooltip and self.ActiveTooltip.Parent then
        p.Tween(self.ActiveTooltip, {BackgroundTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
            self.ActiveTooltip:Destroy()
            self.ActiveTooltip = nil
        end)
    end
end

-- Helper function to attach tooltip to any element
function p.AttachTooltip(element, text, position)
    local hoverConn
    hoverConn = element.MouseEnter:Connect(function()
        TooltipSystem:Show(element, text, position or "Top")
    end)
    element.MouseLeave:Connect(function()
        TooltipSystem:Hide()
    end)
    return hoverConn
end


-- ============================================================
-- LIBRARY EXPORTS & PUBLIC API
-- ============================================================

--- Set theme by name
function a:SetTheme(themeName)
    Theme.SetTheme(themeName)
end

--- Toggle between Dark and Light themes
function a:ToggleTheme()
    Theme.Toggle()
end

--- Get current theme name
function a:GetTheme()
    return CurrentTheme
end

--- Get current theme table
function a:GetThemeTable()
    return Theme.GetCurrent()
end

--- Register a theme change callback
function a:OnThemeChanged(callback)
    return Theme.OnChanged(callback)
end

--- Set icon provider URL
function a:SetIconProvider(url)
    Icons.SetProvider(url)
end

--- Register custom icon
function a:RegisterIcon(name, assetId)
    Icons.Register(name, assetId)
end

--- Get icon URL
function a:GetIcon(name)
    return Icons.Get(name)
end

--- Check if device is mobile
function a:IsMobile()
    return p.IsMobile()
end

--- Set config flag
function a:SetFlag(key, value)
    ConfigSystem:SetFlag(key, value)
end

--- Get config flag
function a:GetFlag(key, default)
    return ConfigSystem:GetFlag(key, default)
end

--- Load saved config
function a:LoadConfig()
    ConfigSystem:LoadAll()
end

--- Save config
function a:SaveConfig()
    ConfigSystem:SaveAll()
end

--- Clear all config
function a:ClearConfig()
    ConfigSystem:Clear()
end

--- Set mobile detection threshold
function a:SetMobileThreshold(width)
    MobileThreshold = width
end

--- Attach tooltip to element
function a:AttachTooltip(element, text, position)
    return p.AttachTooltip(element, text, position)
end

--- Utility: Create tween
function a:Tween(inst, props, duration, easingStyle, easingDirection, callback)
    return p.Tween(inst, props, duration, easingStyle, easingDirection, callback)
end

--- Utility: Color from hex
function a:Color3FromHex(hex)
    return p.Color3FromHex(hex)
end

--- Utility: Color to hex
function a:Color3ToHex(color3)
    return p.Color3ToHex(color3)
end

--- Utility: Create glass frame
function a:CreateGlassFrame(props)
    return p.CreateGlassFrame(props)
end

--- Utility: Create card frame
function a:CreateCardFrame(props)
    return p.CreateCardFrame(props)
end

--- Utility: Create label
function a:CreateLabel(props)
    return p.CreateLabel(props)
end

--- Utility: Create ripple effect
function a:CreateRipple(frame, posX, posY)
    return p.CreateRipple(frame, posX, posY)
end

--- Utility: Deep copy
function a:DeepCopy(tbl)
    return p.DeepCopy(tbl)
end

--- Get all active windows
function a:GetWindows()
    return ActiveWindows
end

--- Destroy all windows
function a:DestroyAll()
    for _, window in ipairs(ActiveWindows) do
        if window.ScreenGui and window.ScreenGui.Parent then
            window.ScreenGui:Destroy()
        end
    end
    ActiveWindows = {}
end

-- ============================================================
-- WINDOW EXTENDED METHODS
-- ============================================================

--- Set window title
function WindowClass:SetTitle(newTitle)
    self.TitleText.Text = newTitle
    self.Config.Title = newTitle
end

--- Set window transparency
function WindowClass:SetTransparency(value)
    self.TransparencyValue = value
    local th = Theme.GetCurrent()
    p.Tween(self.WindowFrame, {
        BackgroundTransparency = math.max(th.GlassTransparency, value)
    }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

--- Show the window
function WindowClass:Show()
    if self.IsVisible then return end
    self.IsVisible = true
    self.WindowFrame.Visible = true
    self.WindowFrame.Size = UDim2.new(0, 0, 0, 0)
    p.Tween(self.WindowFrame, {Size = self.SavedSize}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

--- Hide the window
function WindowClass:Hide()
    if not self.IsVisible then return end
    self.IsVisible = false
    self.SavedSize = self.WindowFrame.Size
    p.Tween(self.WindowFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
        self.WindowFrame.Visible = false
    end)
end

--- Lock window (prevent interaction)
function WindowClass:Lock()
    self.IsLocked = true
    -- Dim the window
    local lockOverlay = self.WindowFrame:FindFirstChild("LockOverlay")
    if not lockOverlay then
        lockOverlay = p.Create("Frame", {
            Name = "LockOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 1000,
            Parent = self.WindowFrame
        })
        p.Create("UICorner", {
            CornerRadius = UDim.new(0, self.Config.CornerRadius),
            Parent = lockOverlay
        })
    end
    p.Tween(lockOverlay, {BackgroundTransparency = 0.5}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

--- Unlock window
function WindowClass:Unlock()
    self.IsLocked = false
    local lockOverlay = self.WindowFrame:FindFirstChild("LockOverlay")
    if lockOverlay then
        p.Tween(lockOverlay, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function()
            lockOverlay:Destroy()
        end)
    end
end

--- Move window to position
function WindowClass:MoveTo(position)
    p.Tween(self.WindowFrame, {Position = position}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

--- Resize window
function WindowClass:Resize(size)
    p.Tween(self.WindowFrame, {Size = size}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

--- Center window on screen
function WindowClass:Center()
    p.Tween(self.WindowFrame, {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5)
    }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

--- Get tab by name
function WindowClass:GetTab(name)
    for _, tab in ipairs(self.Tabs) do
        if tab.Title == name then
            return tab
        end
    end
    return nil
end

--- Select tab by name
function WindowClass:SelectTab(name)
    local tab = self:GetTab(name)
    if tab then
        tab:Select()
    end
end

-- ============================================================
-- ADDITIONAL ELEMENT HELPERS
-- ============================================================

--- Create a notification (standalone - no window needed, but pass window for container)
function a:Notify(window, config)
    return NotificationSystem:Create(window, config)
end

--- Create a dialog
function a:Dialog(window, config)
    return DialogSystem:Create(window, config)
end

--- Show tooltip
function a:ShowTooltip(parent, text, position)
    return TooltipSystem:Show(parent, text, position)
end

--- Hide tooltip
function a:HideTooltip()
    TooltipSystem:Hide()
end

-- ============================================================
-- PRE-BUILT THEME COLORS (iOS System Colors)
-- ============================================================

a.Colors = {
    SystemBlue = p.Color3FromHex("#007AFF"),
    SystemGreen = p.Color3FromHex("#34C759"),
    SystemIndigo = p.Color3FromHex("#5856D6"),
    SystemOrange = p.Color3FromHex("#FF9500"),
    SystemPink = p.Color3FromHex("#FF2D55"),
    SystemPurple = p.Color3FromHex("#AF52DE"),
    SystemRed = p.Color3FromHex("#FF3B30"),
    SystemTeal = p.Color3FromHex("#5AC8FA"),
    SystemYellow = p.Color3FromHex("#FFCC00"),
    SystemCyan = p.Color3FromHex("#32ADE6"),
    SystemMint = p.Color3FromHex("#00C7BE"),
    SystemBrown = p.Color3FromHex("#A2845E"),
    -- Dark mode variants
    SystemBlueDark = p.Color3FromHex("#0A84FF"),
    SystemGreenDark = p.Color3FromHex("#30D158"),
    SystemIndigoDark = p.Color3FromHex("#5E5CE6"),
    SystemOrangeDark = p.Color3FromHex("#FF9F0A"),
    SystemPinkDark = p.Color3FromHex("#FF375F"),
    SystemPurpleDark = p.Color3FromHex("#BF5AF2"),
    SystemRedDark = p.Color3FromHex("#FF453A"),
    SystemTealDark = p.Color3FromHex("#64D2FF"),
    SystemYellowDark = p.Color3FromHex("#FFD60A"),
    -- Backgrounds
    DarkBackground = p.Color3FromHex("#1C1C1E"),
    DarkSecondaryBackground = p.Color3FromHex("#2C2C2E"),
    DarkTertiaryBackground = p.Color3FromHex("#3A3A3C"),
    LightBackground = p.Color3FromHex("#F2F2F7"),
    LightSecondaryBackground = p.Color3FromHex("#FFFFFF"),
    -- Text
    DarkText = p.Color3FromHex("#FFFFFF"),
    DarkSecondaryText = p.Color3FromHex("#EBEBF5"),
    DarkTertiaryText = p.Color3FromHex("#EBEBF599"),
    LightText = p.Color3FromHex("#000000"),
    LightSecondaryText = p.Color3FromHex("#3C3C4399"),
    LightTertiaryText = p.Color3FromHex("#3C3C434D"),
}

-- ============================================================
-- ANIMATION PRESETS (iOS 26)
-- ============================================================

a.Animations = {
    TabSwitch = {Duration = 0.35, EasingStyle = Enum.EasingStyle.Quart, EasingDirection = Enum.EasingDirection.Out},
    ElementHover = {Duration = 0.2, EasingStyle = Enum.EasingStyle.Quad, EasingDirection = Enum.EasingDirection.Out},
    SpringButton = {Duration = 0.4, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out},
    NotificationSlide = {Duration = 0.5, EasingStyle = Enum.EasingStyle.Elastic, EasingDirection = Enum.EasingDirection.Out},
    DialogPopup = {Duration = 0.4, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out},
    ToggleSwitch = {Duration = 0.3, EasingStyle = Enum.EasingStyle.Quart, EasingDirection = Enum.EasingDirection.InOut},
    CollapseExpand = {Duration = 0.35, EasingStyle = Enum.EasingStyle.Quart, EasingDirection = Enum.EasingDirection.InOut},
    FadeIn = {Duration = 0.25, EasingStyle = Enum.EasingStyle.Quad, EasingDirection = Enum.EasingDirection.Out},
    FadeOut = {Duration = 0.2, EasingStyle = Enum.EasingStyle.Quad, EasingDirection = Enum.EasingDirection.In},
    ScaleIn = {Duration = 0.3, EasingStyle = Enum.EasingStyle.Back, EasingDirection = Enum.EasingDirection.Out},
    ScaleOut = {Duration = 0.2, EasingStyle = Enum.EasingStyle.Quart, EasingDirection = Enum.EasingDirection.In},
}

-- ============================================================
-- VERSION INFO
-- ============================================================

a.Version = "1.0.0"
a.Name = "iOS 26 UI Library"
a.Author = "Lobster"
a.Description = "A Roblox UI Library with iOS 26 (Liquid Glass) Design Language"

-- ============================================================
-- AUTO-LOAD CONFIG
-- ============================================================

pcall(function()
    ConfigSystem:LoadAll()
end)

-- ============================================================
-- RETURN LIBRARY
-- ============================================================

return a

--[[ 
============================================================
API USAGE EXAMPLE
============================================================

local iOS26UI = loadstring(game:HttpGet("URL"))()

-- Create Window
local Window = iOS26UI:CreateWindow({
    Title = "iOS 26 UI",
    Author = "Lobster",
    Theme = "Dark",
    Size = UDim2.new(0, 580, 0, 420),
    Keybind = Enum.KeyCode.RightShift
})

-- Create Tabs
local HomeTab = Window:Tab({Title = "General", Icon = "home"})
local SettingsTab = Window:Tab({Title = "Settings", Icon = "settings"})
local VisualsTab = Window:Tab({Title = "Visuals", Icon = "palette"})

-- Create Sections
local MainSection = HomeTab:Section({Title = "Main Settings"})
local ActionsSection = HomeTab:Section({Title = "Actions", Collapsible = true})
local InfoSection = HomeTab:Section({Title = "Information"})

-- Button
MainSection:Button({
    Title = "Click Me",
    Icon = "zap",
    Callback = function()
        print("Button clicked!")
    end
})

-- Colored Button
ActionsSection:Button({
    Title = "Danger Action",
    Color = "#FF3B30",
    Callback = function()
        print("Danger!")
    end
})

-- Toggle
local featureToggle = MainSection:Toggle({
    Title = "Enable Feature",
    Default = false,
    Callback = function(value)
        print("Feature:", value)
    end
})

-- Slider
MainSection:Slider({
    Title = "Speed",
    Value = {Min = 0, Max = 100, Default = 50, Step = 1},
    Suffix = "%",
    Callback = function(value)
        print("Speed:", value)
    end
})

-- Dropdown
MainSection:Dropdown({
    Title = "Select Mode",
    Options = {"Easy", "Medium", "Hard", "Extreme"},
    Default = "Medium",
    Callback = function(value)
        print("Mode:", value)
    end
})

-- Input
MainSection:Input({
    Title = "Player Name",
    Placeholder = "Enter name...",
    Callback = function(value)
        print("Name:", value)
    end
})

-- Checkbox
MainSection:Checkbox({
    Title = "Auto Farm",
    Default = false,
    Callback = function(value)
        print("Auto Farm:", value)
    end
})

-- Keybind
MainSection:Keybind({
    Title = "Toggle Key",
    Default = Enum.KeyCode.E,
    Callback = function(key)
        print("Key pressed:", key.Name)
    end
})

-- Color Picker
VisualsTab:Section({Title = "Colors"}):ColorPicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(0, 122, 255),
    Callback = function(color)
        print("Color:", color)
    end
})

-- Paragraph with Buttons
InfoSection:Paragraph({
    Title = "About",
    Content = "This UI library features iOS 26 design language with Liquid Glass effects, spring animations, and responsive layout.",
    Buttons = {
        {Title = "GitHub", Callback = function() print("GitHub") end},
        {Title = "Discord", Callback = function() print("Discord") end}
    }
})

-- Divider
MainSection:Divider({Title = "Advanced"})

-- Code Block
InfoSection:Code({
    Title = "Example Code",
    Content = "local ui = iOS26UI:CreateWindow({Title = 'My UI'})\nprint('Hello, iOS 26!')"
})

-- Image
VisualsTab:Section({Title = "Preview"}):Image({
    Title = "Logo",
    Source = "rbxassetid://123456789",
    Size = UDim2.new(1, 0, 0, 150)
})

-- Group (nested elements)
local groupSection = SettingsTab:Section({Title = "Grouped Settings"})
local group = groupSection:Group({Title = "Quick Settings"})
group:Toggle({Title = "Fast Mode", Callback = function(v) end})
group:Toggle({Title = "Safe Mode", Callback = function(v) end})

-- Notifications
Window:Notify({
    Title = "Welcome!",
    Content = "iOS 26 UI Library loaded successfully.",
    Duration = 5,
    Style = "Success",
    Icon = "sparkles"
})

-- Dialog
Window:Dialog({
    Title = "Confirm Action",
    Content = "Are you sure you want to proceed?",
    Buttons = {
        {Title = "Cancel", Color = "#8E8E93", Callback = function() print("Cancelled") end},
        {Title = "Confirm", Color = "#007AFF", Callback = function() print("Confirmed") end}
    }
})

-- Theme toggle
iOS26UI:ToggleTheme()

-- Element methods
featureToggle:SetValue(true)      -- Set toggle value
featureToggle:SetTitle("New Title") -- Change title
featureToggle:Lock()              -- Lock element
featureToggle:Unlock()            -- Unlock element

-- Window methods
Window:Center()                   -- Center window
Window:ToggleFullscreen()         -- Toggle fullscreen
Window:SetTransparency(0.3)       -- Set window transparency
Window:Show()                     -- Show window
Window:Hide()                     -- Hide window
Window:Lock()                     -- Lock window
Window:Unlock()                   -- Unlock window

-- Library utilities
print(iOS26UI.Version)            -- "1.0.0"
print(iOS26UI:IsMobile())         -- true/false
iOS26UI:SetFlag("myKey", "value") -- Save config
iOS26UI:GetFlag("myKey")          -- Get config

-- iOS System Colors
local blue = iOS26UI.Colors.SystemBlue
local darkBlue = iOS26UI.Colors.SystemBlueDark

-- Animation Presets
local anim = iOS26UI.Animations.TabSwitch
-- {Duration = 0.35, EasingStyle = Quart, EasingDirection = Out}

============================================================
]]


-- ============================================================
-- WATERMARK SYSTEM
-- ============================================================

local WatermarkSystem = {}
WatermarkSystem.Enabled = true
WatermarkSystem.Frame = nil

function WatermarkSystem:Create(window)
    if not self.Enabled then return end
    local theme = Theme.GetCurrent()
    local screenGui = window.ScreenGui

    local watermarkFrame = p.CreateGlassFrame({
        Name = "Watermark",
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundColor3 = theme.GlassBackground,
        BackgroundTransparency = 0.3,
        CornerRadius = UDim.new(0, 8),
        Border = true,
        Shadow = false,
        ZIndex = 999,
        Parent = screenGui
    })
    watermarkFrame.AutomaticSize = Enum.AutomaticSize.XY

    local wmPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = watermarkFrame
    })

    local wmLabel = p.CreateLabel({
        Name = "Text",
        Size = UDim2.new(0, 0, 0, 14),
        Text = a.Name .. " v" .. a.Version,
        TextColor3 = theme.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = watermarkFrame
    })

    self.Frame = watermarkFrame
    self.Label = wmLabel

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(watermarkFrame, {BackgroundColor3 = th.GlassBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(wmLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)

    -- Update with FPS and time
    spawn(function()
        while watermarkFrame and watermarkFrame.Parent do
            local fps = math.floor(1 / RunService.Heartbeat:Wait())
            local timeStr = os.date("%H:%M:%S")
            wmLabel.Text = a.Name .. " v" .. a.Version .. "  |  " .. timeStr .. "  |  " .. tostring(fps) .. " FPS"
            task.wait(1)
        end
    end)

    return watermarkFrame
end

function WatermarkSystem:SetText(text)
    if self.Label then
        self.Label.Text = text
    end
end

function WatermarkSystem:Toggle()
    self.Enabled = not self.Enabled
    if self.Frame then
        self.Frame.Visible = self.Enabled
    end
end

-- ============================================================
-- SPLASH / LOADING SCREEN
-- ============================================================

local SplashSystem = {}

function SplashSystem:Show(window, config)
    config = config or {}
    config.Title = config.Title or a.Name
    config.Duration = config.Duration or 2
    config.Icon = config.Icon or nil

    local theme = Theme.GetCurrent()
    local screenGui = window.ScreenGui

    local splashFrame = p.Create("Frame", {
        Name = "Splash",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 500,
        Parent = screenGui
    })

    -- Center container
    local centerFrame = p.Create("Frame", {
        Name = "Center",
        Size = UDim2.new(0, 200, 0, 120),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = splashFrame
    })

    -- Splash icon (spinning)
    local splashIcon = nil
    if config.Icon then
        splashIcon = Icons.Create(config.Icon, {
            Size = 48,
            Position = UDim2.new(0.5, 0, 0, 0),
            AnchorPoint = Vector2.new(0.5, 0),
            Color = theme.Accent,
            Parent = centerFrame
        })
    end

    -- Splash title
    local splashTitle = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -40, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = centerFrame
    })
    splashTitle.Position = UDim2.new(0, 0, 1, -44)

    -- Loading indicator
    local loadingBar = p.Create("Frame", {
        Name = "LoadingBar",
        Size = UDim2.new(0.8, 0, 0, 4),
        Position = UDim2.new(0.5, 0, 1, -12),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Parent = centerFrame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = loadingBar})

    local loadingFill = p.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Parent = loadingBar
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = loadingFill})

    -- Spinning animation for icon
    if splashIcon then
        spawn(function()
            while splashFrame and splashFrame.Parent do
                p.Tween(splashIcon, {Rotation = splashIcon.Rotation + 360}, 1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
                task.wait(1.5)
            end
        end)
    end

    -- Animate loading bar
    p.Tween(loadingFill, {Size = UDim2.new(1, 0, 1, 0)}, config.Duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    -- Auto dismiss
    task.delay(config.Duration, function()
        if splashFrame and splashFrame.Parent then
            p.Tween(splashFrame, {BackgroundTransparency = 1}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            p.Tween(splashTitle, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            p.Tween(loadingBar, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            p.Tween(loadingFill, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            if splashIcon then
                p.Tween(splashIcon, {ImageTransparency = 1, Size = UDim2.new(0, 64, 0, 64)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end
            task.delay(0.5, function()
                if splashFrame and splashFrame.Parent then
                    splashFrame:Destroy()
                end
            end)
        end
    end)

    return splashFrame
end

-- ============================================================
-- BADGE ELEMENT
-- ============================================================

function ElementClass.Badge(section, config)
    config = config or {}
    config.Title = config.Title or "Badge"
    config.Text = config.Text or "New"
    config.Color = config.Color or nil
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Badge"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Text

    local row = createElementRow(section, {
        Name = "Badge_" .. config.Title,
        Order = config.Order
    })
    element.Row = row

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.7, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Badge
    local badgeColor = config.Color and p.Color3FromHex(config.Color) or theme.BadgeBackground
    local badgeFrame = p.Create("Frame", {
        Name = "Badge",
        Size = UDim2.new(0, 0, 0, 22),
        Position = UDim2.new(1, -4, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = badgeColor,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Parent = row
    })
    badgeFrame.AutomaticSize = Enum.AutomaticSize.X
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = badgeFrame})

    local badgePadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = badgeFrame
    })

    local badgeLabel = p.CreateLabel({
        Name = "Text",
        Size = UDim2.new(0, 0, 1, 0),
        Text = config.Text,
        TextColor3 = theme.BadgeText,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = badgeFrame
    })
    element.Badge = badgeFrame
    element.BadgeLabel = badgeLabel

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(badgeFrame, {BackgroundColor3 = config.Color and p.Color3FromHex(config.Color) or th.BadgeBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(badgeLabel, {TextColor3 = th.BadgeText}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetText(newText)
        self.Value = newText
        badgeLabel.Text = newText
    end

    function element:SetColor(hexColor)
        config.Color = hexColor
        p.Tween(badgeFrame, {BackgroundColor3 = p.Color3FromHex(hexColor)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- PROGRESS BAR ELEMENT
-- ============================================================

function ElementClass.ProgressBar(section, config)
    config = config or {}
    config.Title = config.Title or "Progress"
    config.Value = config.Value or 50
    config.Max = config.Max or 100
    config.Height = config.Height or 6
    config.Color = config.Color or nil
    config.ShowPercent = config.ShowPercent ~= false
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "ProgressBar"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Value
    element.Max = config.Max

    local rowHeight = config.ShowPercent and 50 or 30
    local row = createElementRow(section, {
        Name = "Progress_" .. config.Title,
        Order = config.Order,
        Height = rowHeight
    })
    element.Row = row

    -- Top row: title + percent
    if config.ShowPercent then
        local topRow = p.Create("Frame", {
            Name = "TopRow",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = row
        })

        local titleLabel = p.CreateLabel({
            Name = "Title",
            Size = UDim2.new(0.7, 0, 1, 0),
            Text = config.Title,
            TextColor3 = theme.TextPrimary,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            Parent = topRow
        })
        element.TitleLabel = titleLabel

        local percentLabel = p.CreateLabel({
            Name = "Percent",
            Size = UDim2.new(0.3, 0, 1, 0),
            Position = UDim2.new(0.7, 0, 0, 0),
            Text = tostring(math.floor(config.Value / config.Max * 100)) .. "%",
            TextColor3 = theme.Accent,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = topRow
        })
        element.PercentLabel = percentLabel
    else
        local titleLabel = p.CreateLabel({
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 14),
            Text = config.Title,
            TextColor3 = theme.TextPrimary,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            Parent = row
        })
        element.TitleLabel = titleLabel
    end

    -- Track
    local trackY = config.ShowPercent and 22 or 16
    local progressTrack = p.Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, config.Height),
        Position = UDim2.new(0, 0, 0, trackY),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = progressTrack})

    local fillPercent = p.Clamp(config.Value / config.Max, 0, 1)
    local fillColor = config.Color and p.Color3FromHex(config.Color) or theme.SliderFill
    local progressFill = p.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(fillPercent, 0, 1, 0),
        BackgroundColor3 = fillColor,
        BorderSizePixel = 0,
        Parent = progressTrack
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = progressFill})
    element.Track = progressTrack
    element.Fill = progressFill

    -- Shimmer effect on fill
    local shimmer = p.Create("ImageLabel", {
        Name = "Shimmer",
        Size = UDim2.new(2, 0, 1, 0),
        Position = UDim2.new(-1, 0, 0, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6833184689",
        ImageTransparency = 0.7,
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(40, 0, 0, 0),
        Parent = progressFill
    })
    -- Animate shimmer
    spawn(function()
        while progressFill and progressFill.Parent do
            p.Tween(shimmer, {Position = UDim2.new(1, 0, 0, 0)}, 1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
            task.wait(1.5)
            shimmer.Position = UDim2.new(-1, 0, 0, 0)
        end
    end)

    -- Theme
    Theme.OnChanged(function(th)
        if element.TitleLabel then
            p.Tween(element.TitleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if element.PercentLabel then
            p.Tween(element.PercentLabel, {TextColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        p.Tween(progressTrack, {BackgroundColor3 = th.SliderTrack}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(progressFill, {BackgroundColor3 = config.Color and p.Color3FromHex(config.Color) or th.SliderFill}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        if element.TitleLabel then element.TitleLabel.Text = newTitle end
    end

    function element:SetValue(value)
        self.Value = p.Clamp(value, 0, self.Max)
        local pct = self.Value / self.Max
        p.Tween(progressFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if element.PercentLabel then
            element.PercentLabel.Text = tostring(math.floor(pct * 100)) .. "%"
        end
    end

    function element:SetColor(hexColor)
        config.Color = hexColor
        p.Tween(progressFill, {BackgroundColor3 = p.Color3FromHex(hexColor)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- LABEL ELEMENT (Read-only text display)
-- ============================================================

function ElementClass.Label(section, config)
    config = config or {}
    config.Title = config.Title or "Label"
    config.Content = config.Content or ""
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Label"
    element.Title = config.Title
    element.Locked = false

    local row = createElementRow(section, {
        Name = "Label_" .. config.Title,
        Order = config.Order
    })
    element.Row = row

    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.45, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    local contentLabel = p.CreateLabel({
        Name = "Content",
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Text = config.Content,
        TextColor3 = theme.TextSecondary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row
    })
    element.ContentLabel = contentLabel

    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(contentLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetContent(newContent)
        contentLabel.Text = newContent
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- MULTI-SELECT LIST ELEMENT
-- ============================================================

function ElementClass.List(section, config)
    config = config or {}
    config.Title = config.Title or "List"
    config.Options = config.Options or {}
    config.Default = config.Default or {}
    config.MultiSelect = config.MultiSelect or false
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "List"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Callback = config.Callback

    local rowHeight = 0
    local row = createElementRow(section, {
        Name = "List_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 18),
        Text = config.Title,
        TextColor3 = theme.SectionHeader,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- List container
    local listContainer = p.CreateCardFrame({
        Name = "ListContainer",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0.5,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = row
    })
    element.ListContainer = listContainer

    local listLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = listContainer
    })

    local itemButtons = {}

    for i, opt in ipairs(config.Options) do
        local isSelected = false
        if config.MultiSelect then
            for _, d in ipairs(config.Default) do
                if d == opt then isSelected = true break end
            end
        else
            isSelected = (opt == config.Default)
        end

        local itemBtn = p.Create("TextButton", {
            Name = "Item_" .. tostring(opt),
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            LayoutOrder = i,
            Parent = listContainer
        })

        -- Selection indicator
        local indicator = p.Create("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = isSelected and theme.Accent or theme.TextTertiary,
            BackgroundTransparency = isSelected and 0 or 0.5,
            BorderSizePixel = 0,
            Parent = itemBtn
        })
        p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = indicator})

        local itemLabel = p.CreateLabel({
            Name = "Label",
            Size = UDim2.new(1, -36, 1, 0),
            Position = UDim2.new(0, 30, 0, 0),
            Text = tostring(opt),
            TextColor3 = isSelected and theme.Accent or theme.TextPrimary,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            Parent = itemBtn
        })

        -- Divider
        if i < #config.Options then
            local itemDivider = p.Create("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, -28, 0, 0.5),
                Position = UDim2.new(0, 14, 1, 0),
                BackgroundColor3 = theme.Divider,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                Parent = itemBtn
            })
        end

        itemBtn.MouseButton1Click:Connect(function()
            if element.Locked then return end

            if config.MultiSelect then
                -- Toggle selection
                local found = false
                for j, v in ipairs(element.Value) do
                    if v == opt then
                        table.remove(element.Value, j)
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(element.Value, opt)
                end
                -- Update visuals for all items
                for _, btn in ipairs(itemButtons) do
                    local isSel = false
                    for _, v in ipairs(element.Value) do
                        if v == btn._OptionValue then isSel = true break end
                    end
                    btn._Indicator.BackgroundColor3 = isSel and theme.Accent or theme.TextTertiary
                    btn._Indicator.BackgroundTransparency = isSel and 0 or 0.5
                    btn._Label.TextColor3 = isSel and theme.Accent or theme.TextPrimary
                end
            else
                element.Value = opt
                for _, btn in ipairs(itemButtons) do
                    local isSel = (btn._OptionValue == opt)
                    p.Tween(btn._Indicator, {
                        BackgroundColor3 = isSel and theme.Accent or theme.TextTertiary,
                        BackgroundTransparency = isSel and 0 or 0.5
                    }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    p.Tween(btn._Label, {
                        TextColor3 = isSel and theme.Accent or theme.TextPrimary
                    }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end
            end

            element.Callback(element.Value)
        end)

        itemBtn.MouseEnter:Connect(function()
            p.Tween(itemBtn, {BackgroundTransparency = 0.7, BackgroundColor3 = theme.DropdownHover}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
        itemBtn.MouseLeave:Connect(function()
            p.Tween(itemBtn, {BackgroundTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)

        itemBtn._OptionValue = opt
        itemBtn._Indicator = indicator
        itemBtn._Label = itemLabel
        table.insert(itemButtons, itemBtn)
    end

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.SectionHeader}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(listContainer, {BackgroundColor3 = th.CardBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        for _, btn in ipairs(itemButtons) do
            local isSel = false
            if config.MultiSelect then
                for _, v in ipairs(element.Value) do
                    if v == btn._OptionValue then isSel = true break end
                end
            else
                isSel = (btn._OptionValue == element.Value)
            end
            p.Tween(btn._Indicator, {BackgroundColor3 = isSel and th.Accent or th.TextTertiary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            p.Tween(btn._Label, {TextColor3 = isSel and th.Accent or th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        self.Value = value
        self.Callback(value)
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- SLIDER WITH INPUT (Combined Slider + Number Input)
-- ============================================================

function ElementClass.SliderInput(section, config)
    config = config or {}
    config.Title = config.Title or "Slider Input"
    config.Value = config.Value or {}
    config.Value.Min = config.Value.Min or 0
    config.Value.Max = config.Value.Max or 100
    config.Value.Default = config.Value.Default or 50
    config.Value.Step = config.Value.Step or 0.1
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1
    config.Suffix = config.Suffix or ""

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "SliderInput"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Value.Default
    element.Min = config.Value.Min
    element.Max = config.Value.Max
    element.Step = config.Value.Step
    element.Callback = config.Callback

    local row = createElementRow(section, {
        Name = "SliderInput_" .. config.Title,
        Order = config.Order,
        Height = 68
    })
    element.Row = row

    -- Top row
    local topRow = p.Create("Frame", {
        Name = "TopRow",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = row
    })

    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = topRow
    })
    element.TitleLabel = titleLabel

    -- Inline number input
    local numInput = p.Create("TextBox", {
        Name = "NumInput",
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.InputBackground,
        BackgroundTransparency = 0.3,
        Text = tostring(config.Value.Default) .. config.Suffix,
        TextColor3 = theme.Accent,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        BorderSizePixel = 0,
        Parent = topRow
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = numInput})
    element.NumInput = numInput

    -- Slider track
    local sliderTrack = p.Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderTrack})
    element.Track = sliderTrack

    local defaultPercent = (config.Value.Default - config.Value.Min) / (config.Value.Max - config.Value.Min)
    local sliderFill = p.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(defaultPercent, 0, 1, 0),
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel = 0,
        Parent = sliderTrack
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderFill})
    element.Fill = sliderFill

    local knobSize = 18
    local sliderKnob = p.Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, knobSize, 0, knobSize),
        Position = UDim2.new(defaultPercent, -knobSize/2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = sliderTrack.ZIndex + 2,
        Parent = sliderTrack
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderKnob})
    element.Knob = sliderKnob

    local interactionArea = p.Create("TextButton", {
        Name = "Interaction",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    local dragging = false

    local function updateFromPercent(pct)
        pct = p.Clamp(pct, 0, 1)
        local rawValue = config.Value.Min + (config.Value.Max - config.Value.Min) * pct
        local steppedValue = p.Round(rawValue / config.Value.Step) * config.Value.Step
        steppedValue = p.Clamp(steppedValue, config.Value.Min, config.Value.Max)
        local newPct = (steppedValue - config.Value.Min) / (config.Value.Max - config.Value.Min)

        element.Value = steppedValue
        sliderFill.Size = UDim2.new(newPct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(newPct, -knobSize/2, 0.5, 0)
        numInput.Text = tostring(p.Round(steppedValue, 2)) .. config.Suffix
        element.Callback(steppedValue)
    end

    interactionArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local relX = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            updateFromPercent(relX)
            p.Tween(sliderKnob, {Size = UDim2.new(0, knobSize + 4, 0, knobSize + 4)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    p.Tween(sliderKnob, {Size = UDim2.new(0, knobSize, 0, knobSize)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relX = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
            updateFromPercent(relX)
        end
    end)

    -- Number input handling
    numInput.FocusLost:Connect(function()
        local text = numInput.Text:gsub(config.Suffix, ""):match("^[%d%.%-]+")
        if text then
            local num = tonumber(text)
            if num then
                num = p.Clamp(p.Round(num / config.Value.Step) * config.Value.Step, config.Value.Min, config.Value.Max)
                element.Value = num
                local pct = (num - config.Value.Min) / (config.Value.Max - config.Value.Min)
                p.Tween(sliderFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                p.Tween(sliderKnob, {Position = UDim2.new(pct, -knobSize/2, 0.5, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                element.Callback(num)
            end
        end
        numInput.Text = tostring(p.Round(element.Value, 2)) .. config.Suffix
    end)

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderTrack, {BackgroundColor3 = th.SliderTrack}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderFill, {BackgroundColor3 = th.SliderFill}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(numInput, {BackgroundColor3 = th.InputBackground, TextColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        value = p.Clamp(value, config.Value.Min, config.Value.Max)
        self.Value = value
        local pct = (value - config.Value.Min) / (config.Value.Max - config.Value.Min)
        p.Tween(sliderFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderKnob, {Position = UDim2.new(pct, -knobSize/2, 0.5, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        numInput.Text = tostring(p.Round(value, 2)) .. config.Suffix
        self.Callback(value)
    end

    function element:Lock()
        self.Locked = true
        numInput.TextEditable = false
    end

    function element:Unlock()
        self.Locked = false
        numInput.TextEditable = true
    end

    table.insert(section.Elements, element)
    return element
end


-- ============================================================
-- ENHANCED WINDOW FEATURES
-- ============================================================

--- Snap window to screen edge
function WindowClass:SnapToEdge(edge)
    edge = edge or "Center"
    local viewport = workspace.CurrentCamera.ViewportSize
    local winSize = self.WindowFrame.AbsoluteSize

    local targetPos
    if edge == "Left" then
        targetPos = UDim2.new(0, 0, 0.5, 0)
        self.WindowFrame.AnchorPoint = Vector2.new(0, 0.5)
        p.Tween(self.WindowFrame, {
            Position = targetPos,
            Size = UDim2.new(0, viewport.X * 0.5, 0, winSize.Y)
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif edge == "Right" then
        targetPos = UDim2.new(1, 0, 0.5, 0)
        self.WindowFrame.AnchorPoint = Vector2.new(1, 0.5)
        p.Tween(self.WindowFrame, {
            Position = targetPos,
            Size = UDim2.new(0, viewport.X * 0.5, 0, winSize.Y)
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif edge == "Top" then
        targetPos = UDim2.new(0.5, 0, 0, 0)
        self.WindowFrame.AnchorPoint = Vector2.new(0.5, 0)
        p.Tween(self.WindowFrame, {
            Position = targetPos,
            Size = UDim2.new(0, winSize.X, 0, viewport.Y * 0.5)
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif edge == "Bottom" then
        targetPos = UDim2.new(0.5, 0, 1, 0)
        self.WindowFrame.AnchorPoint = Vector2.new(0.5, 1)
        p.Tween(self.WindowFrame, {
            Position = targetPos,
            Size = UDim2.new(0, winSize.X, 0, viewport.Y * 0.5)
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    else
        self:Center()
    end
end

--- Minimize window (shrink to title bar)
function WindowClass:Minimize()
    if not self._isMinimized then
        self._isMinimized = true
        self._savedFullSize = self.WindowFrame.Size
        local titleH = self.Config.TitleBarHeight
        p.Tween(self.WindowFrame, {Size = UDim2.new(self.WindowFrame.Size.X.Scale, self.WindowFrame.Size.X.Offset, 0, titleH)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(self.ContentContainer, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    else
        self._isMinimized = false
        p.Tween(self.WindowFrame, {Size = self._savedFullSize or self.Config.Size}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        p.Tween(self.ContentContainer, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
end

--- Set window keybind
function WindowClass:SetKeybind(keyCode)
    -- Remove old keybind connections
    for i, conn in ipairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
            self.Connections[i] = nil
        end
    end

    self.Config.Keybind = keyCode
    if keyCode then
        local keybindConn
        keybindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == keyCode then
                self:ToggleVisibility()
            end
        end)
        table.insert(self.Connections, keybindConn)
    end
end

--- Add a status bar to the window bottom
function WindowClass:AddStatusBar(config)
    config = config or {}
    config.Height = config.Height or 24
    config.Text = config.Text or ""

    local theme = Theme.GetCurrent()
    local isMobile = p.IsMobile()

    local statusBar = p.Create("Frame", {
        Name = "StatusBar",
        Size = UDim2.new(1, 0, 0, config.Height),
        Position = UDim2.new(0, 0, 1, -config.Height),
        BackgroundColor3 = theme.TitleBar,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = self.WindowFrame
    })
    p.Create("UICorner", {
        CornerRadius = UDim.new(0, self.Config.CornerRadius),
        Parent = statusBar
    })
    -- Cover top corners
    local statusCover = p.Create("Frame", {
        Name = "TopCover",
        Size = UDim2.new(1, 0, self.Config.CornerRadius, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.TitleBar,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = statusBar.ZIndex,
        Parent = statusBar
    })

    -- Status text
    local statusLabel = p.CreateLabel({
        Name = "StatusLabel",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        Text = config.Text,
        TextColor3 = theme.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        Parent = statusBar
    })

    -- Resize main content to accommodate status bar
    local currentMainSize = self.MainContent.Size
    self.MainContent.Size = UDim2.new(
        currentMainSize.X.Scale, currentMainSize.X.Offset,
        currentMainSize.Y.Scale, currentMainSize.Y.Offset - config.Height
    )

    self.StatusBar = statusBar
    self.StatusLabel = statusLabel

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(statusBar, {BackgroundColor3 = th.TitleBar}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(statusCover, {BackgroundColor3 = th.TitleBar}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(statusLabel, {TextColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)

    return {
        SetText = function(text)
            statusLabel.Text = text
        end,
        Frame = statusBar
    }
end

--- Add search bar to window
function WindowClass:AddSearchBar(config)
    config = config or {}
    config.Placeholder = config.Placeholder or "Search..."
    config.Callback = config.Callback or function() end

    local theme = Theme.GetCurrent()
    local searchBarHeight = 36

    local searchBarContainer = p.Create("Frame", {
        Name = "SearchBar",
        Size = UDim2.new(1, -20, 0, searchBarHeight),
        Position = UDim2.new(0, 10, 0, self.Config.TitleBarHeight + 4),
        BackgroundColor3 = theme.InputBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = self.WindowFrame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = searchBarContainer})
    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.6,
        Thickness = 0.5,
        Parent = searchBarContainer
    })

    -- Search icon
    local searchIcon = Icons.Create("search", {
        Size = 14,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Color = theme.TextSecondary,
        Parent = searchBarContainer
    })

    -- Search input
    local searchInput = p.Create("TextBox", {
        Name = "SearchInput",
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = config.Placeholder,
        PlaceholderColor3 = theme.Placeholder,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = searchBarContainer
    })

    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        config.Callback(searchInput.Text)
    end)

    -- Focus effects
    searchInput.Focused:Connect(function()
        p.Tween(searchBarContainer, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    searchInput.FocusLost:Connect(function()
        p.Tween(searchBarContainer, {BackgroundTransparency = 0.3}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    -- Adjust main content position
    self.MainContent.Position = UDim2.new(
        self.MainContent.Position.X.Scale, self.MainContent.Position.X.Offset,
        0, self.Config.TitleBarHeight + searchBarHeight + 8
    )
    self.MainContent.Size = UDim2.new(
        self.MainContent.Size.X.Scale, self.MainContent.Size.X.Offset,
        1, -(self.Config.TitleBarHeight + searchBarHeight + 8)
    )

    self.SearchBar = searchBarContainer

    Theme.OnChanged(function(th)
        p.Tween(searchBarContainer, {BackgroundColor3 = th.InputBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(searchInput, {TextColor3 = th.TextPrimary, PlaceholderColor3 = th.Placeholder}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(searchIcon, {ImageColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)

    return {
        SetText = function(text) searchInput.Text = text end,
        GetText = function() return searchInput.Text end,
        Frame = searchBarContainer,
        Input = searchInput
    }
end

-- ============================================================
-- ENHANCED RESPONSIVE HANDLER
-- ============================================================

local ResponsiveHandler = {}
ResponsiveHandler.Connections = {}

function ResponsiveHandler:Watch(window)
    local lastState = p.IsMobile() and "Mobile" or "Desktop"

    local conn
    conn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        local currentState = p.IsMobile() and "Mobile" or "Desktop"
        if currentState ~= lastState then
            lastState = currentState
            self:Transition(window, currentState)
        end
    end)

    table.insert(self.Connections, conn)
    table.insert(window.Connections, conn)
end

function ResponsiveHandler:Transition(window, newState)
    local theme = Theme.GetCurrent()
    local config = window.Config

    if newState == "Mobile" then
        -- Mobile layout transition
        p.Tween(window.Sidebar, {Size = UDim2.new(0, 0, 1, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, function()
            window.Sidebar.Visible = false
        end)

        window.BottomBar.Visible = true
        window.BottomBar.Size = UDim2.new(1, 0, 0, 0)
        p.Tween(window.BottomBar, {Size = UDim2.new(1, 0, 0, config.BottomBarHeight)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        p.Tween(window.MainContent, {
            Size = UDim2.new(1, 0, 1, -config.BottomBarHeight),
            Position = UDim2.new(0, 0, 0, 0)
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

        if not window.IsFullscreen then
            p.Tween(window.WindowFrame, {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0)
            }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            window.WindowFrame.AnchorPoint = Vector2.new(0, 0)
        end
    else
        -- Desktop layout transition
        window.Sidebar.Visible = true
        window.Sidebar.Size = UDim2.new(0, 0, 1, 0)
        p.Tween(window.Sidebar, {Size = UDim2.new(0, config.SideBarWidth, 1, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        p.Tween(window.BottomBar, {Size = UDim2.new(1, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, function()
            window.BottomBar.Visible = false
        end)

        p.Tween(window.MainContent, {
            Size = UDim2.new(1, -config.SideBarWidth, 1, 0),
            Position = UDim2.new(0, config.SideBarWidth, 0, 0)
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

        if not window.IsFullscreen then
            window.WindowFrame.AnchorPoint = config.AnchorPoint
            p.Tween(window.WindowFrame, {
                Size = config.Size,
                Position = config.Position
            }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        end
    end
end

-- Hook responsive handler into window creation
local originalCreateWindow = a.CreateWindow
function a:CreateWindow(config)
    local window = originalCreateWindow(self, config)
    ResponsiveHandler:Watch(window)
    return window
end

-- ============================================================
-- WINDOW SNAP DETECTION (drag to edge)
-- ============================================================

local SnapDetection = {}
SnapDetection.Threshold = 20
SnapDetection.Enabled = true

function SnapDetection:Attach(window)
    local titleBar = window.TitleBar
    local windowFrame = window.WindowFrame
    local config = window.Config
    local isDragging = false

    -- Visual snap indicator
    local snapIndicator = p.Create("Frame", {
        Name = "SnapIndicator",
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme.GetCurrent().Accent,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 999,
        Parent = window.ScreenGui
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = snapIndicator})

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    snapIndicator.Visible = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not isDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local viewport = workspace.CurrentCamera.ViewportSize
        local mousePos = Vector2.new(input.Position.X, input.Position.Y)

        if not SnapDetection.Enabled then return end

        -- Detect edge proximity
        if mousePos.X <= SnapDetection.Threshold then
            -- Left edge snap
            snapIndicator.Size = UDim2.new(0, viewport.X * 0.5, 0, viewport.Y)
            snapIndicator.Position = UDim2.new(0, 0, 0, 0)
            snapIndicator.Visible = true
            window._pendingSnap = "Left"
        elseif mousePos.X >= viewport.X - SnapDetection.Threshold then
            -- Right edge snap
            snapIndicator.Size = UDim2.new(0, viewport.X * 0.5, 0, viewport.Y)
            snapIndicator.Position = UDim2.new(0.5, 0, 0, 0)
            snapIndicator.Visible = true
            window._pendingSnap = "Right"
        elseif mousePos.Y <= SnapDetection.Threshold then
            -- Top edge = maximize
            snapIndicator.Size = UDim2.new(1, 0, 1, 0)
            snapIndicator.Position = UDim2.new(0, 0, 0, 0)
            snapIndicator.Visible = true
            window._pendingSnap = "Top"
        else
            snapIndicator.Visible = false
            window._pendingSnap = nil
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if window._pendingSnap then
                window:SnapToEdge(window._pendingSnap)
                window._pendingSnap = nil
                snapIndicator.Visible = false
            end
        end
    end)

    Theme.OnChanged(function(th)
        p.Tween(snapIndicator, {BackgroundColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)
end

-- ============================================================
-- PERSISTENT WINDOW SETTINGS
-- ============================================================

function WindowClass:SavePosition()
    local pos = self.WindowFrame.Position
    local size = self.WindowFrame.Size
    ConfigSystem:SetFlag(self.Config.Title .. "_pos_x", pos.X.Offset)
    ConfigSystem:SetFlag(self.Config.Title .. "_pos_y", pos.Y.Offset)
    ConfigSystem:SetFlag(self.Config.Title .. "_size_x", size.X.Offset)
    ConfigSystem:SetFlag(self.Config.Title .. "_size_y", size.Y.Offset)
end

function WindowClass:LoadPosition()
    local px = ConfigSystem:GetFlag(self.Config.Title .. "_pos_x")
    local py = ConfigSystem:GetFlag(self.Config.Title .. "_pos_y")
    local sx = ConfigSystem:GetFlag(self.Config.Title .. "_size_x")
    local sy = ConfigSystem:GetFlag(self.Config.Title .. "_size_y")

    if px and py then
        self.WindowFrame.Position = UDim2.new(0, px, 0, py)
    end
    if sx and sy then
        self.WindowFrame.Size = UDim2.new(0, sx, 0, sy)
    end
end

-- Auto-save position on drag end
local origCreateWindow2 = a.CreateWindow
function a:CreateWindow(config)
    local window = origCreateWindow2(self, config)

    -- Try to load saved position
    pcall(function()
        window:LoadPosition()
    end)

    -- Save position on move
    local lastSaveTime = 0
    window.WindowFrame:GetPropertyChangedSignal("Position"):Connect(function()
        local now = tick()
        if now - lastSaveTime > 1 then
            lastSaveTime = now
            pcall(function()
                window:SavePosition()
            end)
        end
    end)

    -- Attach snap detection
    SnapDetection:Attach(window)

    -- Create watermark
    WatermarkSystem:Create(window)

    return window
end

-- ============================================================
-- ADDITIONAL SECTION METHODS
-- ============================================================

--- Add Badge element to section
function SectionClass.Create(tab, config)
    -- Extend the section with additional element methods
    local section = SectionClass.Create(tab, config)

    -- These are added after the fact via the existing section table
    -- Badge, Progress, Label, List, SliderInput are accessible via:
    -- section:Badge(...), section:ProgressBar(...), etc.
    -- Already handled by the Section:ElementName pattern below
    return section
end

-- Add extra element methods to all sections created via tab:Section
local origTabSection = nil
-- We need to patch the Tab:Section method to add extra element methods

-- Patch section to include all element types
local function patchSection(section)
    if section._patched then return section end
    section._patched = true

    function section:Badge(badgeConfig)
        return ElementClass.Badge(self, badgeConfig)
    end

    function section:ProgressBar(progressConfig)
        return ElementClass.ProgressBar(self, progressConfig)
    end

    function section:Label(labelConfig)
        return ElementClass.Label(self, labelConfig)
    end

    function section:List(listConfig)
        return ElementClass.List(self, listConfig)
    end

    function section:SliderInput(siConfig)
        return ElementClass.SliderInput(self, siConfig)
    end
end

-- Patch the tab:Section to auto-patch sections
for _, window in ipairs(ActiveWindows) do
    for _, tab in ipairs(window.Tabs) do
        for _, section in ipairs(tab.Sections) do
            patchSection(section)
        end
    end
end

-- We need to patch the Tab method's Section function
-- This is done by modifying the tab:Section method after creation
-- The simplest approach is to call patchSection in tab:Section

-- Store reference to original tab:Section
local _origTabSectionFunc = WindowClass.Tab

-- We cannot easily re-assign a method on a metatable-based object
-- Instead, we patch SectionClass.Create to call patchSection at the end
local _origSectionCreate = SectionClass.Create

SectionClass.Create = function(tab, config)
    local section = _origSectionCreate(tab, config)
    patchSection(section)
    return section
end

-- ============================================================
-- KEYBOARD SHORTCUTS
-- ============================================================

local KeyboardShortcuts = {}
KeyboardShortcuts.Registered = {}

function KeyboardShortcuts:Register(name, keyCode, callback, description)
    table.insert(self.Registered, {
        Name = name,
        KeyCode = keyCode,
        Callback = callback,
        Description = description or ""
    })
end

function KeyboardShortcuts:Unregister(name)
    for i, shortcut in ipairs(self.Registered) do
        if shortcut.Name == name then
            table.remove(self.Registered, i)
            break
        end
    end
end

-- Global input handler for shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    for _, shortcut in ipairs(KeyboardShortcuts.Registered) do
        if input.KeyCode == shortcut.KeyCode then
            shortcut.Callback()
        end
    end
end)

-- Register default shortcuts
KeyboardShortcuts:Register("Toggle Theme", Enum.KeyCode.F2, function()
    Theme.Toggle()
end, "Toggle between Dark and Light themes")

-- Expose keyboard shortcuts
a.KeyboardShortcuts = KeyboardShortcuts

-- ============================================================
-- SMOOTH NUMBER ANIMATION UTILITY
-- ============================================================

function p.AnimateNumber(from, to, duration, callback, easingStyle, easingDirection)
    easingStyle = easingStyle or Enum.EasingStyle.Quart
    easingDirection = easingDirection or Enum.EasingDirection.Out

    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local progress = p.Clamp(elapsed / duration, 0, 1)

        -- Apply easing
        local easedProgress
        if easingStyle == Enum.EasingStyle.Quart then
            if easingDirection == Enum.EasingDirection.Out then
                easedProgress = 1 - (1 - progress) ^ 4
            else
                easedProgress = progress ^ 4
            end
        elseif easingStyle == Enum.EasingStyle.Quad then
            if easingDirection == Enum.EasingDirection.Out then
                easedProgress = 1 - (1 - progress) ^ 2
            else
                easedProgress = progress ^ 2
            end
        elseif easingStyle == Enum.EasingStyle.Back then
            local c1 = 1.70158
            local c3 = c1 + 1
            easedProgress = 1 + c3 * (progress - 1) ^ 3 + c1 * (progress - 1) ^ 2
        else
            easedProgress = progress
        end

        local value = p.Lerp(from, to, easedProgress)
        callback(value, progress >= 1)

        if progress >= 1 then
            connection:Disconnect()
        end
    end)

    return connection
end

-- ============================================================
-- MULTI-TARGET TWEEN UTILITY
-- ============================================================

function p.TweenMultiple(targets, duration, easingStyle, easingDirection, callback)
    local tweens = {}
    for _, target in ipairs(targets) do
        local tween = p.Tween(target.Instance, target.Properties, duration, easingStyle, easingDirection)
        table.insert(tweens, tween)
    end
    if callback then
        task.delay(duration, callback)
    end
    return tweens
end

-- ============================================================
-- LERP COLOR3 UTILITY
-- ============================================================

function p.LerpColor3(a, b, t)
    return Color3.new(
        p.Lerp(a.R, b.R, t),
        p.Lerp(a.G, b.G, t),
        p.Lerp(a.B, b.B, t)
    )
end

-- ============================================================
-- SPRING PHYSICS UTILITY
-- ============================================================

function p.Spring(target, current, velocity, stiffness, damping, dt)
    stiffness = stiffness or 300
    damping = damping or 25
    dt = dt or 0.01

    local force = -stiffness * (current - target)
    local dampForce = -damping * velocity
    local acceleration = force + dampForce

    velocity = velocity + acceleration * dt
    current = current + velocity * dt

    return current, velocity
end

-- ============================================================
-- GRADIENT HELPER
-- ============================================================

function p.CreateGradient(parent, config)
    config = config or {}
    local colorKeys = {}
    local transparencyKeys = {}

    if config.Colors then
        for i, c in ipairs(config.Colors) do
            table.insert(colorKeys, ColorSequenceKeypoint.new(c.Time or ((i-1) / (#config.Colors - 1)), c.Color))
        end
    else
        table.insert(colorKeys, ColorSequenceKeypoint.new(0, config.StartColor or Color3.fromRGB(255, 255, 255)))
        table.insert(colorKeys, ColorSequenceKeypoint.new(1, config.EndColor or Color3.fromRGB(255, 255, 255)))
    end

    if config.Transparencies then
        for i, t in ipairs(config.Transparencies) do
            table.insert(transparencyKeys, NumberSequenceKeypoint.new(t.Time or ((i-1) / (#config.Transparencies - 1)), t.Value))
        end
    end

    local gradient = p.Create("UIGradient", {
        Color = ColorSequence.new(colorKeys),
        Rotation = config.Rotation or 0,
        Offset = config.Offset or Vector2.new(0, 0),
        Parent = parent
    })

    if #transparencyKeys > 0 then
        gradient.Transparency = NumberSequence.new(transparencyKeys)
    end

    return gradient
end

-- ============================================================
-- RIPPLE ON HOVER UTILITY
-- ============================================================

function p.AddHoverRipple(frame, options)
    options = options or {}
    local hoverColor = options.Color or Color3.fromRGB(255, 255, 255)
    local hoverTransparency = options.Transparency or 0.9

    local hoverOverlay = p.Create("Frame", {
        Name = "HoverOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = hoverColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 5,
        Parent = frame
    })
    if frame:FindFirstChildOfClass("UICorner") then
        p.Create("UICorner", {
            CornerRadius = frame:FindFirstChildOfClass("UICorner").CornerRadius,
            Parent = hoverOverlay
        })
    end

    frame.MouseEnter:Connect(function()
        p.Tween(hoverOverlay, {BackgroundTransparency = hoverTransparency}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    frame.MouseLeave:Connect(function()
        p.Tween(hoverOverlay, {BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    return hoverOverlay
end

-- ============================================================
-- CONTEXT MENU SYSTEM
-- ============================================================

local ContextMenuSystem = {}

function ContextMenuSystem:Show(parent, items, position)
    self:Hide()

    local theme = Theme.GetCurrent()
    local screenGui = parent:FindFirstAncestorOfClass("ScreenGui") or parent:FindFirstAncestorOfClass("LayerCollector")

    if not screenGui then return end

    local menuWidth = 180
    local menuHeight = #items * 34 + 8

    local menuFrame = p.CreateCardFrame({
        Name = "ContextMenu",
        Size = UDim2.new(0, menuWidth, 0, 0),
        Position = UDim2.new(0, position.X, 0, position.Y),
        BackgroundColor3 = theme.DropdownBackground,
        ClipsDescendants = true,
        ZIndex = 400,
        Parent = screenGui
    })
    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.5,
        Thickness = 0.5,
        Parent = menuFrame
    })

    local menuLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = menuFrame
    })

    local menuPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = menuFrame
    })

    for i, item in ipairs(items) do
        if item.Divider then
            local divider = p.Create("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, -8, 0, 1),
                BackgroundColor3 = theme.Divider,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = i,
                Parent = menuFrame
            })
        else
            local itemBtn = p.Create("TextButton", {
                Name = "Item_" .. (item.Title or ""),
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "",
                BorderSizePixel = 0,
                LayoutOrder = i,
                Parent = menuFrame
            })
            p.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = itemBtn})

            local iconOffset = 0
            if item.Icon then
                local itemIcon = Icons.Create(item.Icon, {
                    Size = 14,
                    Position = UDim2.new(0, 8, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Color = item.Danger and theme.Danger or theme.TextPrimary,
                    Parent = itemBtn
                })
                iconOffset = 24
            end

            local itemLabel = p.CreateLabel({
                Name = "Label",
                Size = UDim2.new(1, -iconOffset - 16, 1, 0),
                Position = UDim2.new(0, iconOffset + 10, 0, 0),
                Text = item.Title or "",
                TextColor3 = item.Danger and theme.Danger or theme.TextPrimary,
                TextSize = 13,
                Font = Enum.Font.Gotham,
                Parent = itemBtn
            })

            -- Shortcut text
            if item.Shortcut then
                local shortcutLabel = p.CreateLabel({
                    Name = "Shortcut",
                    Size = UDim2.new(0, 40, 1, 0),
                    Position = UDim2.new(1, -8, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    Text = item.Shortcut,
                    TextColor3 = theme.TextTertiary,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = itemBtn
                })
            end

            itemBtn.MouseButton1Click:Connect(function()
                if item.Callback then item.Callback() end
                self:Hide()
            end)

            itemBtn.MouseEnter:Connect(function()
                p.Tween(itemBtn, {BackgroundColor3 = theme.DropdownHover, BackgroundTransparency = 0}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)

            itemBtn.MouseLeave:Connect(function()
                p.Tween(itemBtn, {BackgroundTransparency = 1}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
        end
    end

    -- Animate in
    p.Tween(menuFrame, {Size = UDim2.new(0, menuWidth, 0, menuHeight)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Close on click outside
    local closeConn
    closeConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local menuPos = menuFrame.AbsolutePosition
            local menuSize = menuFrame.AbsoluteSize
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            local inMenu = mousePos.X >= menuPos.X and mousePos.X <= menuPos.X + menuSize.X
                and mousePos.Y >= menuPos.Y and mousePos.Y <= menuPos.Y + menuSize.Y
            if not inMenu then
                self:Hide()
                closeConn:Disconnect()
            end
        end
    end)

    self.ActiveMenu = menuFrame
    self.CloseConnection = closeConn

    return menuFrame
end

function ContextMenuSystem:Hide()
    if self.ActiveMenu and self.ActiveMenu.Parent then
        p.Tween(self.ActiveMenu, {Size = UDim2.new(0, 180, 0, 0)}, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
            self.ActiveMenu:Destroy()
            self.ActiveMenu = nil
        end)
    end
    if self.CloseConnection then
        self.CloseConnection:Disconnect()
        self.CloseConnection = nil
    end
end

a.ContextMenu = ContextMenuSystem

-- ============================================================
-- RIGHT-CLICK CONTEXT MENU FOR WINDOW
-- ============================================================

function WindowClass:EnableContextMenu()
    self.WindowFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            local mousePos = Vector2.new(input.Position.X, input.Position.Y)
            ContextMenuSystem:Show(self.WindowFrame, {
                {Title = "Minimize", Icon = "minus", Shortcut = "Ctrl+M", Callback = function() self:Minimize() end},
                {Title = "Fullscreen", Icon = "maximize", Shortcut = "F11", Callback = function() self:ToggleFullscreen() end},
                {Divider = true},
                {Title = "Toggle Theme", Icon = "moon", Shortcut = "F2", Callback = function() Theme.Toggle() end},
                {Title = "Center Window", Icon = "target", Callback = function() self:Center() end},
                {Divider = true},
                {Title = "Save Position", Icon = "download", Callback = function() self:SavePosition() end},
                {Title = "Reset Position", Icon = "refresh", Callback = function()
                    self.WindowFrame.Position = self.Config.Position
                    self.WindowFrame.Size = self.Config.Size
                end},
                {Divider = true},
                {Title = "Close Window", Icon = "x", Danger = true, Callback = function() self:Hide() end}
            }, mousePos)
        end
    end)
end


-- ============================================================
-- ADVANCED ANIMATION SYSTEM
-- ============================================================

local AnimationSystem = {}
AnimationSystem.ActiveAnimations = {}
AnimationSystem._idCounter = 0

--- Create a spring animation
function AnimationSystem:Spring(instance, property, target, config)
    config = config or {}
    config.Stiffness = config.Stiffness or 300
    config.Damping = config.Damping or 25
    config.Precision = config.Precision or 0.01
    config.OnUpdate = config.OnUpdate or nil
    config.OnComplete = config.OnComplete or nil

    local current = instance[property]
    local velocity = 0
    local id = self._idCounter + 1
    self._idCounter = id

    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        local force = -config.Stiffness * (current - target)
        local dampForce = -config.Damping * velocity
        local acceleration = force + dampForce

        velocity = velocity + acceleration * dt
        current = current + velocity * dt

        instance[property] = current

        if config.OnUpdate then
            config.OnUpdate(current)
        end

        if math.abs(velocity) < config.Precision and math.abs(current - target) < config.Precision then
            instance[property] = target
            connection:Disconnect()
            self.ActiveAnimations[id] = nil
            if config.OnComplete then
                config.OnComplete()
            end
        end
    end)

    self.ActiveAnimations[id] = connection
    return id
end

--- Cancel a spring animation
function AnimationSystem:Cancel(id)
    if self.ActiveAnimations[id] then
        self.ActiveAnimations[id]:Disconnect()
        self.ActiveAnimations[id] = nil
    end
end

--- Create a sequence of animations
function AnimationSystem:Sequence(animations)
    local currentIndex = 1
    local sequenceId = self._idCounter + 1
    self._idCounter = sequenceId

    local function playNext()
        if currentIndex > #animations then
            self.ActiveAnimations[sequenceId] = nil
            return
        end

        local anim = animations[currentIndex]
        currentIndex = currentIndex + 1

        if anim.Delay then
            task.delay(anim.Delay, playNext)
        elseif anim.Tween then
            local tweenInfo = TweenInfo.new(
                anim.Duration or 0.3,
                anim.EasingStyle or Enum.EasingStyle.Quart,
                anim.EasingDirection or Enum.EasingDirection.Out
            )
            local tween = TweenService:Create(anim.Instance, tweenInfo, anim.Properties)
            if currentIndex <= #animations then
                tween.Completed:Connect(playNext)
            else
                if anim.OnComplete then
                    tween.Completed:Connect(anim.OnComplete)
                end
            end
            tween:Play()
        elseif anim.Callback then
            anim.Callback()
            playNext()
        end
    end

    playNext()
    self.ActiveAnimations[sequenceId] = true
    return sequenceId
end

--- Shake animation (for errors/warnings)
function AnimationSystem:Shake(instance, intensity, duration)
    intensity = intensity or 5
    duration = duration or 0.4

    local originalPos = instance.Position
    local startTime = tick()

    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= duration then
            instance.Position = originalPos
            connection:Disconnect()
            return
        end

        local progress = elapsed / duration
        local decay = 1 - progress
        local offsetX = math.sin(elapsed * 50) * intensity * decay
        local offsetY = math.cos(elapsed * 70) * intensity * 0.5 * decay

        instance.Position = UDim2.new(
            originalPos.X.Scale, originalPos.X.Offset + offsetX,
            originalPos.Y.Scale, originalPos.Y.Offset + offsetY
        )
    end)
end

--- Pulse animation
function AnimationSystem:Pulse(instance, property, from, to, duration, count)
    count = count or 3
    local animations = {}
    for i = 1, count do
        table.insert(animations, {
            Instance = instance,
            Properties = {[property] = to},
            Duration = duration / (count * 2),
            EasingStyle = Enum.EasingStyle.Quad,
            EasingDirection = Enum.EasingDirection.Out
        })
        table.insert(animations, {
            Instance = instance,
            Properties = {[property] = from},
            Duration = duration / (count * 2),
            EasingStyle = Enum.EasingStyle.Quad,
            EasingDirection = Enum.EasingDirection.In
        })
    end
    return self:Sequence(animations)
end

--- Bounce animation
function AnimationSystem:Bounce(instance, intensity, duration)
    intensity = intensity or 10
    duration = duration or 0.5

    local originalPos = instance.Position
    p.Tween(instance, {
        Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset - intensity)
    }, duration * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
        p.Tween(instance, {Position = originalPos}, duration * 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

--- Fade in animation
function AnimationSystem:FadeIn(instance, duration, callback)
    duration = duration or 0.3
    instance.BackgroundTransparency = 1
    if instance:IsA("TextLabel") or instance:IsA("TextButton") then
        instance.TextTransparency = 1
    end
    if instance:IsA("ImageLabel") then
        instance.ImageTransparency = 1
    end
    instance.Visible = true

    p.Tween(instance, {BackgroundTransparency = 0}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    if instance:IsA("TextLabel") or instance:IsA("TextButton") then
        p.Tween(instance, {TextTransparency = 0}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    if instance:IsA("ImageLabel") then
        p.Tween(instance, {ImageTransparency = 0}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end

    if callback then
        task.delay(duration, callback)
    end
end

--- Fade out animation
function AnimationSystem:FadeOut(instance, duration, callback)
    duration = duration or 0.2

    p.Tween(instance, {BackgroundTransparency = 1}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    if instance:IsA("TextLabel") or instance:IsA("TextButton") then
        p.Tween(instance, {TextTransparency = 1}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end
    if instance:IsA("ImageLabel") then
        p.Tween(instance, {ImageTransparency = 1}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end

    if callback then
        task.delay(duration, callback)
    end
end

--- Scale in animation (with spring)
function AnimationSystem:ScaleIn(instance, duration, callback)
    duration = duration or 0.3
    local targetSize = instance.Size
    instance.Size = UDim2.new(0, 0, 0, 0)
    p.Tween(instance, {Size = targetSize}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out, callback)
end

--- Scale out animation
function AnimationSystem:ScaleOut(instance, duration, callback)
    duration = duration or 0.2
    p.Tween(instance, {Size = UDim2.new(0, 0, 0, 0)}, duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In, callback)
end

a.Animation = AnimationSystem

-- ============================================================
-- EXTENDED ELEMENT: RADIO BUTTON GROUP
-- ============================================================

function ElementClass.RadioGroup(section, config)
    config = config or {}
    config.Title = config.Title or "Options"
    config.Options = config.Options or {}
    config.Default = config.Default or nil
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "RadioGroup"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Callback = config.Callback
    element.RadioButtons = {}

    local rowHeight = #config.Options * 30 + 4
    local row = createElementRow(section, {
        Name = "RadioGroup_" .. config.Title,
        Order = config.Order,
        Height = rowHeight
    })
    element.Row = row

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 18),
        Text = config.Title,
        TextColor3 = theme.SectionHeader,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Radio options container
    local radioContainer = p.Create("Frame", {
        Name = "RadioContainer",
        Size = UDim2.new(1, 0, 0, rowHeight - 18),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = row
    })

    local radioLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = radioContainer
    })

    for i, opt in ipairs(config.Options) do
        local isSelected = (opt == config.Default)

        local radioRow = p.Create("TextButton", {
            Name = "Radio_" .. tostring(opt),
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = radioContainer
        })

        -- Outer circle
        local outerCircle = p.Create("Frame", {
            Name = "OuterCircle",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 4, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = theme.InputBackground,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Parent = radioRow
        })
        p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = outerCircle})
        p.Create("UIStroke", {
            Color = isSelected and theme.Accent or theme.Border,
            Thickness = 1.5,
            Parent = outerCircle
        })

        -- Inner circle (selected indicator)
        local innerCircle = p.Create("Frame", {
            Name = "InnerCircle",
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = isSelected and 0 or 1,
            BorderSizePixel = 0,
            Parent = outerCircle
        })
        p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = innerCircle})

        -- Label
        local radioLabel = p.CreateLabel({
            Name = "Label",
            Size = UDim2.new(1, -34, 1, 0),
            Position = UDim2.new(0, 30, 0, 0),
            Text = tostring(opt),
            TextColor3 = isSelected and theme.Accent or theme.TextPrimary,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            Parent = radioRow
        })

        local radioData = {
            Option = opt,
            Row = radioRow,
            OuterCircle = outerCircle,
            InnerCircle = innerCircle,
            Label = radioLabel,
            Stroke = outerCircle:FindFirstChildOfClass("UIStroke")
        }
        table.insert(element.RadioButtons, radioData)

        radioRow.MouseButton1Click:Connect(function()
            if element.Locked then return end
            element.Value = opt
            -- Update all radio buttons
            for _, rd in ipairs(element.RadioButtons) do
                local sel = (rd.Option == opt)
                local stroke = rd.OuterCircle:FindFirstChildOfClass("UIStroke")
                if sel then
                    p.Tween(rd.InnerCircle, {BackgroundTransparency = 0, Size = UDim2.new(0, 12, 0, 12)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    task.delay(0.15, function()
                        p.Tween(rd.InnerCircle, {Size = UDim2.new(0, 10, 0, 10)}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    end)
                    if stroke then p.Tween(stroke, {Color = theme.Accent}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
                    p.Tween(rd.Label, {TextColor3 = theme.Accent}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                else
                    p.Tween(rd.InnerCircle, {BackgroundTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    if stroke then p.Tween(stroke, {Color = theme.Border}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
                    p.Tween(rd.Label, {TextColor3 = theme.TextPrimary}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end
            end
            element.Callback(opt)
        end)

        radioRow.MouseEnter:Connect(function()
            p.Tween(radioRow, {BackgroundTransparency = 0.9, BackgroundColor3 = theme.DropdownHover}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
        radioRow.MouseLeave:Connect(function()
            p.Tween(radioRow, {BackgroundTransparency = 1}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
    end

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.SectionHeader}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        for _, rd in ipairs(element.RadioButtons) do
            local sel = (rd.Option == element.Value)
            p.Tween(rd.OuterCircle, {BackgroundColor3 = th.InputBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if sel then
                p.Tween(rd.InnerCircle, {BackgroundColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                local stroke = rd.OuterCircle:FindFirstChildOfClass("UIStroke")
                if stroke then p.Tween(stroke, {Color = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) end
                p.Tween(rd.Label, {TextColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                local stroke = rd.OuterCircle:FindFirstChildOfClass("UIStroke")
                if stroke then p.Tween(stroke, {Color = th.Border}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) end
                p.Tween(rd.Label, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        self.Value = value
        local th = Theme.GetCurrent()
        for _, rd in ipairs(element.RadioButtons) do
            local sel = (rd.Option == value)
            if sel then
                p.Tween(rd.InnerCircle, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local stroke = rd.OuterCircle:FindFirstChildOfClass("UIStroke")
                if stroke then p.Tween(stroke, {Color = th.Accent}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
                p.Tween(rd.Label, {TextColor3 = th.Accent}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            else
                p.Tween(rd.InnerCircle, {BackgroundTransparency = 1}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                local stroke = rd.OuterCircle:FindFirstChildOfClass("UIStroke")
                if stroke then p.Tween(stroke, {Color = th.Border}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) end
                p.Tween(rd.Label, {TextColor3 = th.TextPrimary}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end
        end
        self.Callback(value)
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- EXTENDED ELEMENT: SWITCH ROW (Multiple toggles in a row)
-- ============================================================

function ElementClass.SwitchRow(section, config)
    config = config or {}
    config.Title = config.Title or "Quick Settings"
    config.Switches = config.Switches or {}
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "SwitchRow"
    element.Title = config.Title
    element.Locked = false
    element.SwitchElements = {}

    local row = createElementRow(section, {
        Name = "SwitchRow_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 18),
        Text = config.Title,
        TextColor3 = theme.SectionHeader,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Switches container with grid
    local switchContainer = p.Create("Frame", {
        Name = "SwitchContainer",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = row
    })

    local switchLayout = p.Create("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 42),
        CellPadding = UDim2.new(0, 8, 0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = switchContainer
    })

    for i, switchConfig in ipairs(config.Switches) do
        local switchFrame = p.Create("Frame", {
            Name = "Switch_" .. (switchConfig.Title or i),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = i,
            Parent = switchContainer
        })

        local switchData = {}
        switchData.Value = switchConfig.Default or false

        -- Switch label
        local switchLabel = p.CreateLabel({
            Name = "Label",
            Size = UDim2.new(1, -48, 1, 0),
            Text = switchConfig.Title or "Switch",
            TextColor3 = theme.TextPrimary,
            TextSize = 13,
            Font = Enum.Font.GothamMedium,
            Parent = switchFrame
        })

        -- Mini toggle
        local toggleContainer = p.Create("Frame", {
            Name = "Toggle",
            Size = UDim2.new(0, 42, 0, 26),
            Position = UDim2.new(1, -2, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = switchData.Value and theme.ToggleOn or theme.ToggleOff,
            BorderSizePixel = 0,
            Parent = switchFrame
        })
        p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleContainer})

        local miniKnob = p.Create("Frame", {
            Name = "Knob",
            Size = UDim2.new(0, 22, 0, 22),
            Position = switchData.Value and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = toggleContainer.ZIndex + 1,
            Parent = toggleContainer
        })
        p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = miniKnob})

        local clickBtn = p.Create("TextButton", {
            Name = "Click",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = switchFrame
        })

        local function toggleSwitch()
            switchData.Value = not switchData.Value
            local th = Theme.GetCurrent()
            if switchData.Value then
                p.Tween(toggleContainer, {BackgroundColor3 = th.ToggleOn}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                p.Tween(miniKnob, {Position = UDim2.new(1, -24, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            else
                p.Tween(toggleContainer, {BackgroundColor3 = th.ToggleOff}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                p.Tween(miniKnob, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            end
            if switchConfig.Callback then
                switchConfig.Callback(switchData.Value)
            end
        end

        clickBtn.MouseButton1Click:Connect(function()
            if not element.Locked then toggleSwitch() end
        end)

        switchData.Frame = switchFrame
        switchData.Toggle = toggleContainer
        switchData.Knob = miniKnob
        switchData.ToggleFunction = toggleSwitch
        table.insert(element.SwitchElements, switchData)
    end

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.SectionHeader}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        for _, sw in ipairs(element.SwitchElements) do
            p.Tween(sw.Frame:FindFirstChild("Label"), {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            if sw.Value then
                p.Tween(sw.Toggle, {BackgroundColor3 = th.ToggleOn}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                p.Tween(sw.Toggle, {BackgroundColor3 = th.ToggleOff}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end
        end
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:GetValue(index)
        return self.SwitchElements[index] and self.SwitchElements[index].Value
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- EXTENDED ELEMENT: TAB BAR (Inline tab switching within a section)
-- ============================================================

function ElementClass.InlineTabs(section, config)
    config = config or {}
    config.Title = config.Title or ""
    config.Tabs = config.Tabs or {}
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "InlineTabs"
    element.Title = config.Title
    element.Locked = false
    element.SelectedTab = 1
    element.TabFrames = {}

    local row = createElementRow(section, {
        Name = "InlineTabs_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    -- Segmented control for tab selection
    if #config.Tabs > 0 then
        local segmentContainer = p.Create("Frame", {
            Name = "Segments",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = theme.InputBackground,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Parent = row
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = segmentContainer})

        local segmentLayout = p.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = segmentContainer
        })

        -- Sliding indicator
        local indicator = p.Create("Frame", {
            Name = "Indicator",
            Size = UDim2.new(1 / #config.Tabs, 0, 1, -4),
            Position = UDim2.new(0, 2, 0, 2),
            BackgroundColor3 = theme.CardBackground,
            BorderSizePixel = 0,
            ZIndex = segmentContainer.ZIndex + 1,
            Parent = segmentContainer
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = indicator})

        for i, tabData in ipairs(config.Tabs) do
            local segmentBtn = p.Create("TextButton", {
                Name = "Segment_" .. (tabData.Title or i),
                Size = UDim2.new(1 / #config.Tabs, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = tabData.Title or ("Tab " .. i),
                TextColor3 = i == 1 and theme.TextPrimary or theme.TextSecondary,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                LayoutOrder = i,
                ZIndex = segmentContainer.ZIndex + 2,
                Parent = segmentContainer
            })

            segmentBtn.MouseButton1Click:Connect(function()
                if element.Locked then return end
                element.SelectedTab = i
                -- Move indicator
                p.Tween(indicator, {
                    Position = UDim2.new((i - 1) / #config.Tabs, 2, 0, 2)
                }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

                -- Update text colors
                for j, btn in ipairs(segmentContainer:GetChildren()) do
                    if btn:IsA("TextButton") then
                        p.Tween(btn, {TextColor3 = j == i and theme.TextPrimary or theme.TextSecondary}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    end
                end

                -- Show/hide tab contents
                for j, frame in ipairs(element.TabFrames) do
                    frame.Visible = (j == i)
                end
            end)
        end

        -- Tab content frames
        for i, tabData in ipairs(config.Tabs) do
            local tabFrame = p.Create("Frame", {
                Name = "TabContent_" .. i,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = (i == 1),
                Parent = row
            })
            local tabContentLayout = p.Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tabFrame
            })
            table.insert(element.TabFrames, tabFrame)

            -- Create a mini section-like API for adding elements to inline tabs
            tabData._frame = tabFrame
        end
    end

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.SectionHeader}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        if titleLabel then titleLabel.Text = newTitle end
    end

    function element:Lock()
        self.Locked = true
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end


-- ============================================================
-- PATCH SECTION WITH ALL EXTENDED ELEMENTS
-- ============================================================

-- Ensure patchSection includes all new element types
local _originalPatchSection = patchSection

patchSection = function(section)
    if section._patched then return section end
    section._patched = true

    -- Core elements (already defined in section methods)
    -- These are handled by the section's own method definitions

    -- Extended elements
    function section:Badge(badgeConfig)
        return ElementClass.Badge(self, badgeConfig)
    end

    function section:ProgressBar(progressConfig)
        return ElementClass.ProgressBar(self, progressConfig)
    end

    function section:Label(labelConfig)
        return ElementClass.Label(self, labelConfig)
    end

    function section:List(listConfig)
        return ElementClass.List(self, listConfig)
    end

    function section:SliderInput(siConfig)
        return ElementClass.SliderInput(self, siConfig)
    end

    function section:RadioGroup(radioConfig)
        return ElementClass.RadioGroup(self, radioConfig)
    end

    function section:SwitchRow(switchConfig)
        return ElementClass.SwitchRow(self, switchConfig)
    end

    function section:InlineTabs(tabConfig)
        return ElementClass.InlineTabs(self, tabConfig)
    end

    -- Splash screen helper
    function section:SplashButton(splashConfig)
        splashConfig = splashConfig or {}
        return self:Button({
            Title = splashConfig.Title or "Show Splash",
            Icon = splashConfig.Icon or "sparkles",
            Callback = function()
                if section.Tab and section.Tab.Window then
                    SplashSystem:Show(section.Tab.Window, {
                        Title = splashConfig.SplashTitle or a.Name,
                        Duration = splashConfig.Duration or 2,
                        Icon = splashConfig.SplashIcon or nil
                    })
                end
            end
        })
    end

    -- Notification helper
    function section:NotifyButton(notifyConfig)
        notifyConfig = notifyConfig or {}
        return self:Button({
            Title = notifyConfig.Title or "Send Notification",
            Icon = notifyConfig.Icon or "bell",
            Callback = function()
                if section.Tab and section.Tab.Window then
                    NotificationSystem:Create(section.Tab.Window, {
                        Title = notifyConfig.NotifTitle or "Notification",
                        Content = notifyConfig.Content or "This is a notification!",
                        Duration = notifyConfig.Duration or 5,
                        Style = notifyConfig.Style or "Info",
                        Icon = notifyConfig.NotifIcon or nil
                    })
                end
            end
        })
    end

    -- Dialog helper
    function section:DialogButton(dialogConfig)
        dialogConfig = dialogConfig or {}
        return self:Button({
            Title = dialogConfig.Title or "Show Dialog",
            Icon = dialogConfig.Icon or "alert",
            Color = dialogConfig.Color or nil,
            Callback = function()
                if section.Tab and section.Tab.Window then
                    DialogSystem:Create(section.Tab.Window, {
                        Title = dialogConfig.DialogTitle or "Dialog",
                        Content = dialogConfig.Content or "Are you sure?",
                        Icon = dialogConfig.DialogIcon or nil,
                        Buttons = dialogConfig.Buttons or {
                            {Title = "Cancel", Color = "#8E8E93"},
                            {Title = "OK", Color = "#007AFF"}
                        }
                    })
                end
            end
        })
    end

    -- Theme toggle button
    function section:ThemeToggleButton(btnConfig)
        btnConfig = btnConfig or {}
        return self:Button({
            Title = btnConfig.Title or "Toggle Theme",
            Icon = CurrentTheme == "Dark" and "sun" or "moon",
            Callback = function()
                Theme.Toggle()
            end
        })
    end

    -- Color display (read-only color swatch)
    function section:ColorDisplay(colorConfig)
        colorConfig = colorConfig or {}
        colorConfig.Title = colorConfig.Title or "Color"
        colorConfig.Color = colorConfig.Color or "#007AFF"
        colorConfig.Order = colorConfig.Order or #self.Elements + 1

        local theme = Theme.GetCurrent()
        local colorElement = {}
        colorElement.Type = "ColorDisplay"
        colorElement.Title = colorConfig.Title
        colorElement.Locked = false
        colorElement.Value = colorConfig.Color

        local colorRow = createElementRow(self, {
            Name = "ColorDisplay_" .. colorConfig.Title,
            Order = colorConfig.Order
        })
        colorElement.Row = colorRow

        local colorTitle = p.CreateLabel({
            Name = "Title",
            Size = UDim2.new(0.6, 0, 1, 0),
            Text = colorConfig.Title,
            TextColor3 = theme.TextPrimary,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            Parent = colorRow
        })
        colorElement.TitleLabel = colorTitle

        -- Color swatch
        local swatch = p.Create("Frame", {
            Name = "Swatch",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -60, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = p.Color3FromHex(colorConfig.Color),
            BorderSizePixel = 0,
            Parent = colorRow
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = swatch})
        p.Create("UIStroke", {
            Color = theme.Border,
            Transparency = 0.5,
            Thickness = 0.5,
            Parent = swatch
        })

        -- Hex label
        local hexLabel = p.CreateLabel({
            Name = "HexLabel",
            Size = UDim2.new(0, 50, 1, 0),
            Position = UDim2.new(1, -4, 0, 0),
            Text = colorConfig.Color,
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = colorRow
        })

        function colorElement:SetTitle(newTitle)
            self.Title = newTitle
            colorTitle.Text = newTitle
        end

        function colorElement:SetColor(hexColor)
            self.Value = hexColor
            p.Tween(swatch, {BackgroundColor3 = p.Color3FromHex(hexColor)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            hexLabel.Text = hexColor
        end

        function colorElement:Lock()
            self.Locked = true
        end

        function colorElement:Unlock()
            self.Locked = false
        end

        table.insert(self.Elements, colorElement)
        return colorElement
    end

    return section
end

-- ============================================================
-- ENHANCED NOTIFICATION TYPES
-- ============================================================

--- Create a toast notification (smaller, less intrusive)
function NotificationSystem:Toast(window, config)
    config = config or {}
    config.Title = config.Title or ""
    config.Content = config.Content or ""
    config.Duration = config.Duration or 3
    config.Style = config.Style or "Info"

    local theme = Theme.GetCurrent()
    local container = self:GetContainer(window)

    local styleColors = {
        Info = theme.Info,
        Success = theme.Success,
        Warning = theme.Warning,
        Danger = theme.Danger
    }
    local styleColor = styleColors[config.Style] or theme.Info

    local toast = p.CreateGlassFrame({
        Name = "Toast",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.NotificationBackground,
        BackgroundTransparency = 0.05,
        CornerRadius = UDim.new(0, 10),
        Border = true,
        Shadow = false,
        Parent = container
    })
    toast.AutomaticSize = Enum.AutomaticSize.Y

    local toastPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = toast
    })

    local toastLayout = p.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = toast
    })

    -- Color dot
    local dot = p.Create("Frame", {
        Name = "Dot",
        Size = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = styleColor,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Parent = toast
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dot})

    -- Text
    local text = config.Title ~= "" and config.Title or config.Content
    local toastLabel = p.CreateLabel({
        Name = "Label",
        Size = UDim2.new(1, -20, 0, 14),
        Text = text,
        TextColor3 = theme.TextPrimary,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
        Parent = toast
    })

    -- Animate in
    toast.Size = UDim2.new(0, 0, 0, 0)
    task.defer(function()
        local targetSize = toast.AbsoluteSize
        toast.AutomaticSize = Enum.AutomaticSize.None
        toast.Size = UDim2.new(0, 0, 0, targetSize.Y)
        p.Tween(toast, {Size = UDim2.new(1, 0, 0, targetSize.Y)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, function()
            toast.AutomaticSize = Enum.AutomaticSize.Y
            toast.Size = UDim2.new(1, 0, 0, 0)
        end)
    end)

    -- Auto dismiss
    task.delay(config.Duration, function()
        if toast and toast.Parent then
            p.Tween(toast, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                toast:Destroy()
            end)
        end
    end)

    return toast
end

-- ============================================================
-- NOTIFICATION WITH PROGRESS (For long-running tasks)
-- ============================================================

function NotificationSystem:Progress(window, config)
    config = config or {}
    config.Title = config.Title or "Loading..."
    config.Duration = config.Duration or 10
    config.Style = config.Style or "Info"

    local theme = Theme.GetCurrent()
    local container = self:GetContainer(window)

    local notif = NotificationSystem:Create(window, {
        Title = config.Title,
        Content = "0%",
        Duration = 0, -- No auto-dismiss
        Style = config.Style
    })

    -- Override progress bar animation
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not notif or notif.Closed then
            connection:Disconnect()
            return
        end

        local elapsed = tick() - startTime
        local progress = p.Clamp(elapsed / config.Duration, 0, 1)
        local percentText = tostring(math.floor(progress * 100)) .. "%"

        -- Find content label and update
        if notif.Frame then
            local contentLabel = notif.Frame:FindFirstChild("Content", true)
            if contentLabel then
                contentLabel.Text = percentText
            end
        end

        if progress >= 1 then
            connection:Disconnect()
            task.delay(1, function()
                if notif and not notif.Closed then
                    -- Auto dismiss after completion
                    if notif.Frame and notif.Frame.Parent then
                        p.Tween(notif.Frame, {
                            Size = UDim2.new(1, 0, 0, 0),
                            BackgroundTransparency = 1
                        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                            if notif.Frame and notif.Frame.Parent then
                                notif.Frame:Destroy()
                            end
                        end)
                    end
                end
            end)
        end
    end)

    notif.Connection = connection
    return notif
end

-- ============================================================
-- WINDOW THEME PRESETS
-- ============================================================

a.ThemePresets = {
    -- Create custom theme presets
    Midnight = {
        Name = "Midnight",
        Background = p.Color3FromHex("#0D0D0F"),
        CardBackground = p.Color3FromHex("#1A1A1F"),
        TextPrimary = p.Color3FromHex("#E8E8ED"),
        TextSecondary = p.Color3FromHex("#6E6E80"),
        Accent = p.Color3FromHex("#5E5CE6"),
        ToggleOn = p.Color3FromHex("#5E5CE6"),
        SliderFill = p.Color3FromHex("#5E5CE6"),
    },
    Ocean = {
        Name = "Ocean",
        Background = p.Color3FromHex("#0A1628"),
        CardBackground = p.Color3FromHex("#132238"),
        TextPrimary = p.Color3FromHex("#E2E8F0"),
        TextSecondary = p.Color3FromHex("#64748B"),
        Accent = p.Color3FromHex("#38BDF8"),
        ToggleOn = p.Color3FromHex("#38BDF8"),
        SliderFill = p.Color3FromHex("#38BDF8"),
    },
    Rose = {
        Name = "Rose",
        Background = p.Color3FromHex("#1A0A10"),
        CardBackground = p.Color3FromHex("#2D1420"),
        TextPrimary = p.Color3FromHex("#FCE7F3"),
        TextSecondary = p.Color3FromHex("#9D5C7A"),
        Accent = p.Color3FromHex("#F472B6"),
        ToggleOn = p.Color3FromHex("#F472B6"),
        SliderFill = p.Color3FromHex("#F472B6"),
    },
    Forest = {
        Name = "Forest",
        Background = p.Color3FromHex("#0A1A0F"),
        CardBackground = p.Color3FromHex("#142D1A"),
        TextPrimary = p.Color3FromHex("#D1FAE5"),
        TextSecondary = p.Color3FromHex("#5C9A72"),
        Accent = p.Color3FromHex("#34D399"),
        ToggleOn = p.Color3FromHex("#34D399"),
        SliderFill = p.Color3FromHex("#34D399"),
    },
    Sunset = {
        Name = "Sunset",
        Background = p.Color3FromHex("#1A0F0A"),
        CardBackground = p.Color3FromHex("#2D1E14"),
        TextPrimary = p.Color3FromHex("#FEE2E2"),
        TextSecondary = p.Color3FromHex("#9A6B5C"),
        Accent = p.Color3FromHex("#FB923C"),
        ToggleOn = p.Color3FromHex("#FB923C"),
        SliderFill = p.Color3FromHex("#FB923C"),
    }
}

--- Apply a theme preset (merges with existing dark/light theme)
function a:ApplyPreset(presetName)
    local preset = self.ThemePresets[presetName]
    if not preset then
        warn("[iOS26UI] Unknown preset: " .. tostring(presetName))
        return
    end

    -- Merge preset into current theme
    local currentTheme = Theme.GetCurrent()
    for k, v in pairs(preset) do
        currentTheme[k] = v
    end

    -- Fire theme changed to update all instances
    Theme.FireThemeChanged()
end

--- Register a custom theme
function a:RegisterTheme(name, themeTable)
    -- Start from a base theme
    local base = p.DeepCopy(Theme.Themes.Dark)
    for k, v in pairs(themeTable) do
        base[k] = v
    end
    base.Name = name
    Theme.Themes[name] = base
end

-- ============================================================
-- WINDOW BLUR EFFECT
-- ============================================================

function WindowClass:EnableBlur(enabled)
    if enabled == nil then enabled = true end

    if enabled then
        -- Create a subtle light effect behind the window
        if not self._blurFrame then
            local theme = Theme.GetCurrent()
            self._blurFrame = p.Create("ImageLabel", {
                Name = "BlurEffect",
                Size = UDim2.new(1, 40, 1, 40),
                Position = UDim2.new(0, -20, 0, -20),
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 0.95,
                BorderSizePixel = 0,
                Image = "rbxassetid://6015897843",
                ImageColor3 = theme.Accent,
                ImageTransparency = 0.85,
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                ZIndex = self.WindowFrame.ZIndex - 1,
                Parent = self.WindowFrame
            })
            p.Create("UICorner", {
                CornerRadius = UDim.new(0, self.Config.CornerRadius + 10),
                Parent = self._blurFrame
            })
        end
        self._blurFrame.Visible = true
    else
        if self._blurFrame then
            self._blurFrame.Visible = false
        end
    end
end

-- ============================================================
-- DRAG & DROP BETWEEN ELEMENTS
-- ============================================================

local DragDropSystem = {}
DragDropSystem.Active = nil
DragDropSystem.Ghost = nil

function DragDropSystem:MakeDraggableElement(frame, data, onDrop)
    local isDragging = false
    local startPos = nil
    local startSize = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            startPos = frame.Position
            startSize = frame.Size

            -- Create ghost
            if not self.Ghost then
                self.Ghost = frame:Clone()
                self.Ghost.Name = "DragGhost"
                self.Ghost.BackgroundTransparency = 0.5
                self.Ghost.ZIndex = 9999
                self.Ghost.Parent = frame:FindFirstAncestorOfClass("ScreenGui") or frame:FindFirstAncestorOfClass("LayerCollector")
            end

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    if self.Ghost then
                        self.Ghost:Destroy()
                        self.Ghost = nil
                    end
                    frame.Position = startPos
                    frame.Size = startSize
                    if onDrop then
                        onDrop(data)
                    end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and self.Ghost then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local mousePos = Vector2.new(input.Position.X, input.Position.Y)
                self.Ghost.Position = UDim2.new(0, mousePos.X - self.Ghost.AbsoluteSize.X / 2, 0, mousePos.Y - self.Ghost.AbsoluteSize.Y / 2)
            end
        end
    end)
end

a.DragDrop = DragDropSystem

-- ============================================================
-- WINDOW ANIMATION PRESETS
-- ============================================================

function WindowClass:AnimateIn(style)
    style = style or "scale"
    local theme = Theme.GetCurrent()

    if style == "scale" then
        self.WindowFrame.Size = UDim2.new(0, 0, 0, 0)
        self.WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        p.Tween(self.WindowFrame, {Size = self.Config.Size}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    elseif style == "slide_left" then
        local targetPos = self.WindowFrame.Position
        self.WindowFrame.Position = UDim2.new(-1, 0, targetPos.Y.Scale, targetPos.Y.Offset)
        p.Tween(self.WindowFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif style == "slide_right" then
        local targetPos = self.WindowFrame.Position
        self.WindowFrame.Position = UDim2.new(2, 0, targetPos.Y.Scale, targetPos.Y.Offset)
        p.Tween(self.WindowFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif style == "slide_top" then
        local targetPos = self.WindowFrame.Position
        self.WindowFrame.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, -1, 0)
        p.Tween(self.WindowFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif style == "slide_bottom" then
        local targetPos = self.WindowFrame.Position
        self.WindowFrame.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, 2, 0)
        p.Tween(self.WindowFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif style == "fade" then
        self.WindowFrame.BackgroundTransparency = 1
        p.Tween(self.WindowFrame, {BackgroundTransparency = theme.GlassTransparency}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif style == "elastic" then
        self.WindowFrame.Size = UDim2.new(0, 0, 0, 0)
        self.WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        p.Tween(self.WindowFrame, {Size = self.Config.Size}, 0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    end
end

function WindowClass:AnimateOut(style, callback)
    style = style or "scale"
    callback = callback or function() end

    if style == "scale" then
        p.Tween(self.WindowFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, callback)
    elseif style == "slide_left" then
        p.Tween(self.WindowFrame, {Position = UDim2.new(-1, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, callback)
    elseif style == "slide_right" then
        p.Tween(self.WindowFrame, {Position = UDim2.new(2, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, callback)
    elseif style == "fade" then
        p.Tween(self.WindowFrame, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, callback)
    end
end

-- ============================================================
-- ELEMENT FACTORY (Create elements outside sections)
-- ============================================================

a.ElementFactory = {}

function a.ElementFactory:CreateToggle(config)
    config = config or {}
    local theme = Theme.GetCurrent()

    local toggleFrame = p.Create("Frame", {
        Name = "StandaloneToggle",
        Size = UDim2.new(0, 51, 0, 31),
        BackgroundColor3 = config.Value and theme.ToggleOn or theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = config.Parent
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleFrame})

    local knob = p.Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 27, 0, 27),
        Position = config.Value and UDim2.new(1, -29, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = toggleFrame.ZIndex + 1,
        Parent = toggleFrame
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

    local value = config.Value or false
    local clickBtn = p.Create("TextButton", {
        Name = "Click",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = toggleFrame
    })

    clickBtn.MouseButton1Click:Connect(function()
        value = not value
        local th = Theme.GetCurrent()
        if value then
            p.Tween(toggleFrame, {BackgroundColor3 = th.ToggleOn}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            p.Tween(knob, {Position = UDim2.new(1, -29, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        else
            p.Tween(toggleFrame, {BackgroundColor3 = th.ToggleOff}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            p.Tween(knob, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        end
        if config.Callback then config.Callback(value) end
    end)

    return {
        Frame = toggleFrame,
        GetValue = function() return value end,
        SetValue = function(v)
            value = v
            local th = Theme.GetCurrent()
            if v then
                p.Tween(toggleFrame, {BackgroundColor3 = th.ToggleOn}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                p.Tween(knob, {Position = UDim2.new(1, -29, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            else
                p.Tween(toggleFrame, {BackgroundColor3 = th.ToggleOff}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                p.Tween(knob, {Position = UDim2.new(0, 2, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
            end
        end
    }
end

-- ============================================================
-- COMPLETE SECTION REORDERING (Drag to reorder sections)
-- ============================================================

function WindowClass:EnableSectionReorder()
    for _, tab in ipairs(self.Tabs) do
        for _, section in ipairs(tab.Sections) do
            if section.HeaderButton then
                local isReordering = false
                local startY = 0

                section.HeaderButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        isReordering = true
                        startY = input.Position.Y
                    end
                end)

                section.HeaderButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isReordering = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if isReordering and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local deltaY = input.Position.Y - startY
                        if math.abs(deltaY) > 20 then
                            -- Swap with adjacent section
                            local currentIndex = section.Order
                            local targetIndex = deltaY > 0 and currentIndex + 1 or currentIndex - 1

                            for _, otherSection in ipairs(tab.Sections) do
                                if otherSection.Order == targetIndex then
                                    otherSection.Order = currentIndex
                                    section.Order = targetIndex
                                    section.Frame.LayoutOrder = targetIndex
                                    otherSection.Frame.LayoutOrder = currentIndex
                                    startY = input.Position.Y
                                    break
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end

-- ============================================================
-- ACCESSIBILITY HELPERS
-- ============================================================

local AccessibilityHelper = {}

function AccessibilityHelper:Announce(text)
    -- Screen reader announcement simulation
    -- In a real Roblox context, this would use ScreenReader APIs
    pcall(function()
        if game:GetService("ScreenReader") then
            game:GetService("ScreenReader"):Speak(text)
        end
    end)
end

function AccessibilityHelper:SetAccessibilityLabel(instance, label)
    if instance then
        pcall(function()
            instance.AccessibilityLabel = label
        end)
    end
end

a.Accessibility = AccessibilityHelper

-- ============================================================
-- DEBUG / PERFORMANCE MONITOR
-- ============================================================

local DebugSystem = {}
DebugSystem.Enabled = false
DebugSystem.Frame = nil
DebugSystem.Connections = {}

function DebugSystem:Toggle()
    self.Enabled = not self.Enabled
    if self.Enabled then
        self:Show()
    else
        self:Hide()
    end
end

function DebugSystem:Show()
    if self.Frame and self.Frame.Parent then
        self.Frame.Visible = true
        return
    end

    local theme = Theme.GetCurrent()
    local safeParent = p.GetSafeParent()

    local screenGui = p.Create("ScreenGui", {
        Name = "iOS26UI_Debug",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = safeParent
    })

    self.Frame = p.CreateGlassFrame({
        Name = "DebugPanel",
        Size = UDim2.new(0, 220, 0, 120),
        Position = UDim2.new(0, 10, 1, -130),
        BackgroundColor3 = theme.GlassBackground,
        BackgroundTransparency = 0.1,
        CornerRadius = UDim.new(0, 12),
        Border = true,
        Shadow = true,
        Parent = screenGui
    })

    local debugPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = self.Frame
    })

    local debugLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.Frame
    })

    -- Title
    local debugTitle = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 14),
        Text = "iOS26UI Debug",
        TextColor3 = theme.Accent,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = self.Frame
    })

    -- FPS
    local fpsLabel = p.CreateLabel({
        Name = "FPS",
        Size = UDim2.new(1, 0, 0, 12),
        Text = "FPS: --",
        TextColor3 = theme.TextPrimary,
        TextSize = 10,
        Font = Enum.Font.Code,
        Parent = self.Frame
    })

    -- Memory
    local memLabel = p.CreateLabel({
        Name = "Memory",
        Size = UDim2.new(1, 0, 0, 12),
        Text = "Memory: --",
        TextColor3 = theme.TextPrimary,
        TextSize = 10,
        Font = Enum.Font.Code,
        Parent = self.Frame
    })

    -- Active windows
    local windowLabel = p.CreateLabel({
        Name = "Windows",
        Size = UDim2.new(1, 0, 0, 12),
        Text = "Windows: --",
        TextColor3 = theme.TextPrimary,
        TextSize = 10,
        Font = Enum.Font.Code,
        Parent = self.Frame
    })

    -- Theme
    local themeLabel = p.CreateLabel({
        Name = "Theme",
        Size = UDim2.new(1, 0, 0, 12),
        Text = "Theme: --",
        TextColor3 = theme.TextPrimary,
        TextSize = 10,
        Font = Enum.Font.Code,
        Parent = self.Frame
    })

    -- Update loop
    spawn(function()
        while self.Frame and self.Frame.Parent and self.Enabled do
            local fps = math.floor(1 / RunService.Heartbeat:Wait())
            local mem = pcall(function() return math.floor(collectgarbage("count")) end)
            fpsLabel.Text = "FPS: " .. tostring(fps)
            memLabel.Text = "Memory: " .. tostring(mem and math.floor(collectgarbage("count")) or "N/A") .. " KB"
            windowLabel.Text = "Windows: " .. tostring(#ActiveWindows)
            themeLabel.Text = "Theme: " .. CurrentTheme
            task.wait(0.5)
        end
    end)

    -- Make draggable
    DragSystem.MakeDraggable(self.Frame, self.Frame)

    Theme.OnChanged(function(th)
        p.Tween(self.Frame, {BackgroundColor3 = th.GlassBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(debugTitle, {TextColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(fpsLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(memLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(windowLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(themeLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)
end

function DebugSystem:Hide()
    if self.Frame then
        self.Frame.Visible = false
    end
end

a.Debug = DebugSystem

-- ============================================================
-- INITIAL CONFIG LOAD
-- ============================================================

-- Attempt to load saved theme preference
pcall(function()
    local savedTheme = ConfigSystem:GetFlag("iOS26UI_Theme")
    if savedTheme and Theme.Themes[savedTheme] then
        CurrentTheme = savedTheme
    end
end)

-- Save theme on change
Theme.OnChanged(function(theme)
    pcall(function()
        ConfigSystem:SetFlag("iOS26UI_Theme", theme.Name)
    end)
end)


-- ============================================================
-- EVENT SYSTEM (Pub/Sub for inter-element communication)
-- ============================================================

local EventSystem = {}
EventSystem.Channels = {}

function EventSystem:Subscribe(channel, callback)
    if not self.Channels[channel] then
        self.Channels[channel] = {}
    end
    table.insert(self.Channels[channel], callback)
    return #self.Channels[channel]
end

function EventSystem:Unsubscribe(channel, index)
    if self.Channels[channel] then
        self.Channels[channel][index] = nil
    end
end

function EventSystem:Publish(channel, ...)
    if self.Channels[channel] then
        for _, callback in ipairs(self.Channels[channel]) do
            pcall(callback, ...)
        end
    end
end

function EventSystem:Clear(channel)
    if channel then
        self.Channels[channel] = {}
    else
        self.Channels = {}
    end
end

a.Events = EventSystem

-- ============================================================
-- CURSOR SYSTEM (Custom cursor styles)
-- ============================================================

local CursorSystem = {}
CursorSystem.CurrentCursor = "default"
CursorSystem.Cursors = {
    default = "rbxassetid://0",
    pointer = "rbxassetid://607816777",
    text = "rbxassetid://607816777",
    move = "rbxassetid://607816777",
    resize = "rbxassetid://607816777",
    grab = "rbxassetid://607816777",
    grabbing = "rbxassetid://607816777",
    not_allowed = "rbxassetid://607816777"
}

function CursorSystem:SetCursor(cursorType)
    self.CurrentCursor = cursorType
    -- In Roblox, cursor customization is limited
    -- This serves as a placeholder for future implementation
end

function CursorSystem:ResetCursor()
    self.CurrentCursor = "default"
end

a.Cursor = CursorSystem

-- ============================================================
-- ENHANCED TOOLTIP WITH RICH CONTENT
-- ============================================================

function TooltipSystem:ShowRich(parent, config)
    config = config or {}
    config.Title = config.Title or ""
    config.Content = config.Content or ""
    config.Position = config.Position or "Top"
    config.Icon = config.Icon or nil
    config.Color = config.Color or nil

    self:Hide()

    local theme = Theme.GetCurrent()
    local parentAbsPos = parent.AbsolutePosition
    local parentAbsSize = parent.AbsoluteSize

    local tooltipFrame = p.Create("Frame", {
        Name = "RichTooltip",
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.TooltipBackground,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 500,
        Parent = parent:FindFirstAncestorOfClass("ScreenGui") or parent:FindFirstAncestorOfClass("LayerCollector")
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = tooltipFrame})
    p.Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.5,
        Thickness = 0.5,
        Parent = tooltipFrame
    })

    local tooltipPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = tooltipFrame
    })

    local tooltipLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tooltipFrame
    })

    -- Title row
    if config.Title ~= "" then
        local titleRow = p.Create("Frame", {
            Name = "TitleRow",
            Size = UDim2.new(0, 0, 0, 16),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = tooltipFrame
        })

        local titleLayout = p.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = titleRow
        })

        if config.Icon then
            Icons.Create(config.Icon, {
                Size = 12,
                Color = config.Color and p.Color3FromHex(config.Color) or theme.Accent,
                Parent = titleRow
            })
        end

        p.CreateLabel({
            Name = "Title",
            Size = UDim2.new(0, 0, 0, 16),
            Text = config.Title,
            TextColor3 = config.Color and p.Color3FromHex(config.Color) or theme.TextPrimary,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = titleRow
        })
    end

    -- Content
    if config.Content ~= "" then
        p.Create("TextLabel", {
            Name = "Content",
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = config.Content,
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.XY,
            Parent = tooltipFrame
        })
    end

    -- Position
    task.defer(function()
        local tooltipSize = tooltipFrame.AbsoluteSize
        local centerX = parentAbsPos.X + parentAbsSize.X / 2
        local centerY = parentAbsPos.Y + parentAbsSize.Y / 2

        if config.Position == "Top" then
            tooltipFrame.Position = UDim2.new(0, centerX - tooltipSize.X / 2, 0, parentAbsPos.Y - tooltipSize.Y - 6)
        elseif config.Position == "Bottom" then
            tooltipFrame.Position = UDim2.new(0, centerX - tooltipSize.X / 2, 0, parentAbsPos.Y + parentAbsSize.Y + 6)
        elseif config.Position == "Left" then
            tooltipFrame.Position = UDim2.new(0, parentAbsPos.X - tooltipSize.X - 6, 0, centerY - tooltipSize.Y / 2)
        elseif config.Position == "Right" then
            tooltipFrame.Position = UDim2.new(0, parentAbsPos.X + parentAbsSize.X + 6, 0, centerY - tooltipSize.Y / 2)
        end

        -- Animate
        tooltipFrame.BackgroundTransparency = 1
        p.Tween(tooltipFrame, {BackgroundTransparency = 0}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    self.ActiveTooltip = tooltipFrame
    return tooltipFrame
end

-- ============================================================
-- ENHANCED INPUT VALIDATION
-- ============================================================

local InputValidator = {}

InputValidator.Patterns = {
    Number = "^[%d%.%-]+$",
    Integer = "^[%d%-]+$",
    Alphanumeric = "^[%w]+$",
    Email = "^[%w%.%%%+%-]+@[%w%.%-]+%.[%a][%a]+$",
    URL = "^https?://[%w%.%-]+%.[%a][%a]+",
    HexColor = "^#?[%x][%x][%x][%x]?[%x]?[%x]?[%x]?[%x]$",
    Username = "^[%w_]+$",
}

function InputValidator:Validate(text, pattern)
    if type(pattern) == "string" then
        return text:match(pattern) ~= nil
    end
    return true
end

function InputValidator:IsNumber(text)
    return text:match(self.Patterns.Number) ~= nil and tonumber(text) ~= nil
end

function InputValidator:IsInRange(text, min, max)
    local num = tonumber(text)
    if not num then return false end
    return num >= min and num <= max
end

function InputValidator:IsValidLength(text, minLength, maxLength)
    return #text >= (minLength or 0) and #text <= (maxLength or math.huge)
end

a.Validator = InputValidator

-- ============================================================
-- ENHANCED DROPDOWN WITH SEARCH
-- ============================================================

function ElementClass.SearchDropdown(section, config)
    config = config or {}
    config.Title = config.Title or "Search Dropdown"
    config.Options = config.Options or {}
    config.Default = config.Default or nil
    config.Callback = config.Callback or function() end
    config.Placeholder = config.Placeholder or "Search..."
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "SearchDropdown"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Options = config.Options
    element.Callback = config.Callback
    element.IsOpen = false

    local row = createElementRow(section, {
        Name = "SearchDropdown_" .. config.Title,
        Order = config.Order,
        Height = 42
    })
    element.Row = row

    -- Title
    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.4, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    -- Value display
    local valueLabel = p.CreateLabel({
        Name = "ValueLabel",
        Size = UDim2.new(0.5, -20, 1, 0),
        Position = UDim2.new(0.4, 0, 0, 0),
        Text = config.Default or config.Placeholder,
        TextColor3 = theme.TextSecondary,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row
    })
    element.ValueLabel = valueLabel

    -- Chevron
    local chevron = Icons.Create("chevron_down", {
        Size = 14,
        Position = UDim2.new(1, -4, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Color = theme.TextSecondary,
        Parent = row
    })
    element.Chevron = chevron

    -- Click area
    local clickArea = p.Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    -- Popup
    local dropdownPopup = nil
    local searchInput = nil
    local optionContainer = nil
    local optionButtons = {}
    local filteredOptions = p.DeepCopy(config.Options)

    local function createPopup()
        dropdownPopup = p.CreateCardFrame({
            Name = "SearchPopup",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 2),
            BackgroundColor3 = theme.DropdownBackground,
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 100,
            Parent = row
        })
        p.Create("UIStroke", {
            Color = theme.Border,
            Transparency = 0.5,
            Thickness = 0.5,
            Parent = dropdownPopup
        })

        -- Search input
        local searchFrame = p.Create("Frame", {
            Name = "SearchFrame",
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundColor3 = theme.InputBackground,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = dropdownPopup
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = searchFrame})
        local searchPad = p.Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = searchFrame
        })

        searchInput = p.Create("TextBox", {
            Name = "SearchInput",
            Size = UDim2.new(1, -8, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = config.Placeholder,
            PlaceholderColor3 = theme.Placeholder,
            TextColor3 = theme.TextPrimary,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
            Parent = searchFrame
        })

        -- Options container (scrollable)
        optionContainer = p.Create("ScrollingFrame", {
            Name = "Options",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.TextSecondary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 100,
            Parent = dropdownPopup
        })
        local optLayout = p.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = optionContainer
        })

        -- Populate options
        element:RefreshOptions(config.Options)
    end

    function element:RefreshOptions(options)
        self.Options = options
        filteredOptions = p.DeepCopy(options)

        if optionContainer then
            -- Clear existing
            for _, child in ipairs(optionContainer:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("Frame") then
                    child:Destroy()
                end
            end
            optionButtons = {}

            for i, opt in ipairs(options) do
                local optBtn = p.Create("TextButton", {
                    Name = "Option_" .. tostring(opt),
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                    ZIndex = 101,
                    Parent = optionContainer
                })

                local optLabel = p.CreateLabel({
                    Name = "Label",
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    Text = tostring(opt),
                    TextColor3 = theme.TextPrimary,
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    Parent = optBtn
                })

                local checkIcon = Icons.Create("check", {
                    Size = 12,
                    Position = UDim2.new(1, -10, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Color = theme.Accent,
                    Parent = optBtn
                })
                checkIcon.Visible = (opt == element.Value)

                optBtn.MouseButton1Click:Connect(function()
                    element.Value = opt
                    valueLabel.Text = tostring(opt)
                    valueLabel.TextColor3 = theme.Accent
                    for _, btn in ipairs(optionButtons) do
                        if btn._CheckIcon then
                            btn._CheckIcon.Visible = (btn._OptionValue == opt)
                        end
                    end
                    element.Callback(opt)
                    closeDropdown()
                end)

                optBtn.MouseEnter:Connect(function()
                    p.Tween(optBtn, {BackgroundColor3 = theme.DropdownHover, BackgroundTransparency = 0}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end)
                optBtn.MouseLeave:Connect(function()
                    p.Tween(optBtn, {BackgroundTransparency = 1}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end)

                optBtn._OptionValue = opt
                optBtn._CheckIcon = checkIcon
                table.insert(optionButtons, optBtn)
            end
        end
    end

    function element:FilterOptions(query)
        query = query:lower()
        for _, btn in ipairs(optionButtons) do
            if query == "" then
                btn.Visible = true
            else
                local match = tostring(btn._OptionValue):lower():find(query, 1, true)
                btn.Visible = match ~= nil
            end
        end
    end

    local function openDropdown()
        if element.IsOpen or element.Locked then return end
        element.IsOpen = true

        if not dropdownPopup then createPopup() end

        dropdownPopup.Visible = true
        dropdownPopup.Size = UDim2.new(1, 0, 0, 0)

        local visibleCount = #config.Options
        local maxVisible = math.min(visibleCount, 6)
        local searchHeight = 34
        local optionsHeight = maxVisible * 30 + 4
        local totalHeight = searchHeight + optionsHeight

        p.Tween(dropdownPopup, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        p.Tween(chevron, {Rotation = 180}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        -- Focus search
        task.delay(0.1, function()
            if searchInput and searchInput.Parent then
                searchInput:CaptureFocus()
            end
        end)

        -- Search handler
        if searchInput then
            searchInput:GetPropertyChangedSignal("Text"):Connect(function()
                element:FilterOptions(searchInput.Text)
            end)
        end
    end

    function closeDropdown()
        if not element.IsOpen then return end
        element.IsOpen = false
        if dropdownPopup then
            p.Tween(dropdownPopup, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                dropdownPopup.Visible = false
                if searchInput then searchInput.Text = "" end
            end)
            p.Tween(chevron, {Rotation = 0}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end

    clickArea.MouseButton1Click:Connect(function()
        if element.IsOpen then
            closeDropdown()
        else
            openDropdown()
        end
    end)

    -- Close on outside click
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if element.IsOpen and dropdownPopup then
                local mousePos = input.Position
                local popupPos = dropdownPopup.AbsolutePosition
                local popupSize = dropdownPopup.AbsoluteSize
                local rowPos = row.AbsolutePosition
                local rowSize = row.AbsoluteSize
                local inPopup = mousePos.X >= popupPos.X and mousePos.X <= popupPos.X + popupSize.X
                    and mousePos.Y >= popupPos.Y and mousePos.Y <= popupPos.Y + popupSize.Y
                local inRow = mousePos.X >= rowPos.X and mousePos.X <= rowPos.X + rowSize.X
                    and mousePos.Y >= rowPos.Y and mousePos.Y <= rowPos.Y + rowSize.Y
                if not inPopup and not inRow then
                    closeDropdown()
                end
            end
        end
    end)

    -- Theme
    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(valueLabel, {TextColor3 = element.Value and th.Accent or th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(chevron, {ImageColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        self.Value = value
        valueLabel.Text = tostring(value)
        valueLabel.TextColor3 = Theme.GetCurrent().Accent
        for _, btn in ipairs(optionButtons) do
            if btn._CheckIcon then
                btn._CheckIcon.Visible = (btn._OptionValue == value)
            end
        end
        self.Callback(value)
    end

    function element:SetOptions(newOptions)
        config.Options = newOptions
        self:RefreshOptions(newOptions)
    end

    function element:Lock()
        self.Locked = true
        closeDropdown()
    end

    function element:Unlock()
        self.Locked = false
    end

    table.insert(section.Elements, element)
    return element
end

-- Add to section patching
local _prevPatchSection = patchSection
patchSection = function(section)
    _prevPatchSection(section)
    if section._patched2 then return section end
    section._patched2 = true

    function section:SearchDropdown(sdConfig)
        return ElementClass.SearchDropdown(self, sdConfig)
    end
    return section
end

-- ============================================================
-- KEYFRAME ANIMATION SYSTEM
-- ============================================================

local KeyframeAnimation = {}
KeyframeAnimation.Animations = {}

function KeyframeAnimation:Create(name, keyframes, config)
    config = config or {}
    config.Loop = config.Loop or false
    config.Duration = config.Duration or 1

    local anim = {
        Name = name,
        Keyframes = keyframes,
        Duration = config.Duration,
        Loop = config.Loop,
        Playing = false,
        Connection = nil
    }

    self.Animations[name] = anim
    return anim
end

function KeyframeAnimation:Play(name, instance)
    local anim = self.Animations[name]
    if not anim then return end

    anim.Playing = true
    local startTime = tick()

    if anim.Connection then
        anim.Connection:Disconnect()
    end

    anim.Connection = RunService.Heartbeat:Connect(function()
        if not anim.Playing then return end

        local elapsed = tick() - startTime
        local progress = (elapsed % anim.Duration) / anim.Duration

        -- Find the two keyframes we're between
        local prevFrame = nil
        local nextFrame = nil

        for i, kf in ipairs(anim.Keyframes) do
            if kf.Time <= progress then
                prevFrame = kf
            end
            if kf.Time >= progress and not nextFrame then
                nextFrame = kf
            end
        end

        if prevFrame and nextFrame and prevFrame ~= nextFrame then
            local frameProgress = (progress - prevFrame.Time) / (nextFrame.Time - prevFrame.Time)
            for prop, value in pairs(prevFrame.Properties) do
                if nextFrame.Properties[prop] then
                    if typeof(value) == "number" then
                        instance[prop] = p.Lerp(value, nextFrame.Properties[prop], frameProgress)
                    elseif typeof(value) == "UDim2" then
                        instance[prop] = UDim2.new(
                            p.Lerp(value.X.Scale, nextFrame.Properties[prop].X.Scale, frameProgress),
                            p.Lerp(value.X.Offset, nextFrame.Properties[prop].X.Offset, frameProgress),
                            p.Lerp(value.Y.Scale, nextFrame.Properties[prop].Y.Scale, frameProgress),
                            p.Lerp(value.Y.Offset, nextFrame.Properties[prop].Y.Offset, frameProgress)
                        )
                    elseif typeof(value) == "Color3" then
                        instance[prop] = p.LerpColor3(value, nextFrame.Properties[prop], frameProgress)
                    end
                end
            end
        end

        if not anim.Loop and progress >= 1 then
            anim.Playing = false
            anim.Connection:Disconnect()
        end
    end)
end

function KeyframeAnimation:Stop(name)
    local anim = self.Animations[name]
    if anim then
        anim.Playing = false
        if anim.Connection then
            anim.Connection:Disconnect()
        end
    end
end

a.KeyframeAnimation = KeyframeAnimation

-- ============================================================
-- WINDOW STATE PERSISTENCE
-- ============================================================

function WindowClass:SaveState()
    local state = {
        Position = {self.WindowFrame.Position.X.Scale, self.WindowFrame.Position.X.Offset, self.WindowFrame.Position.Y.Scale, self.WindowFrame.Position.Y.Offset},
        Size = {self.WindowFrame.Size.X.Scale, self.WindowFrame.Size.X.Offset, self.WindowFrame.Size.Y.Scale, self.WindowFrame.Size.Y.Offset},
        Visible = self.IsVisible,
        Fullscreen = self.IsFullscreen,
        Minimized = self._isMinimized or false,
        Transparency = self.TransparencyValue
    }

    local stateKey = "iOS26UI_Window_" .. self.Config.Title
    ConfigSystem:SetFlag(stateKey, HttpService:JSONEncode(state))
end

function WindowClass:LoadState()
    local stateKey = "iOS26UI_Window_" .. self.Config.Title
    local stateJson = ConfigSystem:GetFlag(stateKey)

    if stateJson then
        pcall(function()
            local state = HttpService:JSONDecode(stateJson)
            if state.Position then
                self.WindowFrame.Position = UDim2.new(state.Position[1], state.Position[2], state.Position[3], state.Position[4])
            end
            if state.Size then
                self.WindowFrame.Size = UDim2.new(state.Size[1], state.Size[2], state.Size[3], state.Size[4])
            end
            if state.Transparency then
                self:SetTransparency(state.Transparency)
            end
        end)
    end
end

-- ============================================================
-- EASING FUNCTIONS LIBRARY
-- ============================================================

a.Easing = {}

function a.Easing.Linear(t)
    return t
end

function a.Easing.QuadIn(t)
    return t * t
end

function a.Easing.QuadOut(t)
    return 1 - (1 - t) * (1 - t)
end

function a.Easing.QuadInOut(t)
    return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
end

function a.Easing.CubicIn(t)
    return t * t * t
end

function a.Easing.CubicOut(t)
    return 1 - (1 - t) ^ 3
end

function a.Easing.CubicInOut(t)
    return t < 0.5 and 4 * t * t * t or 1 - (-2 * t + 2) ^ 3 / 2
end

function a.Easing.QuartIn(t)
    return t * t * t * t
end

function a.Easing.QuartOut(t)
    return 1 - (1 - t) ^ 4
end

function a.Easing.QuartInOut(t)
    return t < 0.5 and 8 * t * t * t * t or 1 - (-2 * t + 2) ^ 4 / 2
end

function a.Easing.QuintIn(t)
    return t ^ 5
end

function a.Easing.QuintOut(t)
    return 1 - (1 - t) ^ 5
end

function a.Easing.QuintInOut(t)
    return t < 0.5 and 16 * t ^ 5 or 1 - (-2 * t + 2) ^ 5 / 2
end

function a.Easing.ExpoIn(t)
    return t == 0 and 0 or 2 ^ (10 * t - 10)
end

function a.Easing.ExpoOut(t)
    return t == 1 and 1 or 1 - 2 ^ (-10 * t)
end

function a.Easing.ExpoInOut(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    return t < 0.5 and 2 ^ (20 * t - 10) / 2 or (2 - 2 ^ (-20 * t + 10)) / 2
end

function a.Easing.CircIn(t)
    return 1 - math.sqrt(1 - t * t)
end

function a.Easing.CircOut(t)
    return math.sqrt(1 - (t - 1) * (t - 1))
end

function a.Easing.CircInOut(t)
    return t < 0.5 and (1 - math.sqrt(1 - (2 * t) ^ 2)) / 2 or (math.sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2
end

function a.Easing.BackIn(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return c3 * t * t * t - c1 * t * t
end

function a.Easing.BackOut(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

function a.Easing.BackInOut(t)
    local c1 = 1.70158
    local c2 = c1 * 1.525
    return t < 0.5 and ((2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2)) / 2
        or ((2 * t - 2) ^ 2 * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
end

function a.Easing.ElasticIn(t)
    if t == 0 or t == 1 then return t end
    local c4 = (2 * math.pi) / 3
    return -(2 ^ (10 * t - 10)) * math.sin((t * 10 - 10.75) * c4)
end

function a.Easing.ElasticOut(t)
    if t == 0 or t == 1 then return t end
    local c4 = (2 * math.pi) / 3
    return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

function a.Easing.ElasticInOut(t)
    if t == 0 or t == 1 then return t end
    local c5 = (2 * math.pi) / 4.5
    if t < 0.5 then
        return -(2 ^ (20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
    else
        return (2 ^ (-20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1
    end
end

function a.Easing.BounceIn(t)
    return 1 - a.Easing.BounceOut(1 - t)
end

function a.Easing.BounceOut(t)
    local n1 = 7.5625
    local d1 = 2.75
    if t < 1 / d1 then
        return n1 * t * t
    elseif t < 2 / d1 then
        t = t - 1.5 / d1
        return n1 * t * t + 0.75
    elseif t < 2.5 / d1 then
        t = t - 2.25 / d1
        return n1 * t * t + 0.9375
    else
        t = t - 2.625 / d1
        return n1 * t * t + 0.984375
    end
end

function a.Easing.BounceInOut(t)
    return t < 0.5 and (1 - a.Easing.BounceOut(1 - 2 * t)) / 2 or (1 + a.Easing.BounceOut(2 * t - 1)) / 2
end

-- ============================================================
-- COLOR UTILITIES
-- ============================================================

a.ColorUtils = {}

function a.ColorUtils:HueToRGB(h, s, v)
    h = h / 360
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    local r, g, b
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return Color3.fromRGB(math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

function a.ColorUtils:RGBToHue(color3)
    local r, g, b = color3.R, color3.G, color3.B
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v

    v = max
    local d = max - min
    s = max == 0 and 0 or d / max

    if max == min then
        h = 0
    else
        if max == r then h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h * 360, s, v
end

function a.ColorUtils:Lighten(color3, amount)
    amount = amount or 0.1
    local r = math.min(1, color3.R + amount)
    local g = math.min(1, color3.G + amount)
    local b = math.min(1, color3.B + amount)
    return Color3.new(r, g, b)
end

function a.ColorUtils:Darken(color3, amount)
    amount = amount or 0.1
    local r = math.max(0, color3.R - amount)
    local g = math.max(0, color3.G - amount)
    local b = math.max(0, color3.B - amount)
    return Color3.new(r, g, b)
end

function a.ColorUtils:WithAlpha(color3, alpha)
    return Color3.fromRGB(
        math.floor(color3.R * 255),
        math.floor(color3.G * 255),
        math.floor(color3.B * 255)
    ), 1 - alpha
end

function a.ColorUtils:GeneratePalette(baseColor, count)
    count = count or 5
    local h, s, v = a.ColorUtils:RGBToHue(baseColor)
    local palette = {}

    for i = 1, count do
        local lightness = 0.3 + (i - 1) * (0.5 / (count - 1))
        local newV = v * lightness
        table.insert(palette, a.ColorUtils:HueToRGB(h, s, newV))
    end

    return palette
end

-- ============================================================
-- MATH UTILITIES
-- ============================================================

a.Math = {}

function a.Math:Map(value, inMin, inMax, outMin, outMax)
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

function a.Math:Wrap(value, min, max)
    local range = max - min
    return ((value - min) % range) + min
end

function a.Math:PingPong(t, length)
    t = t % (length * 2)
    return length - math.abs(t - length)
end

function a.Math:MoveTowards(current, target, maxDelta)
    if math.abs(target - current) <= maxDelta then
        return target
    end
    return current + math.sign(target - current) * maxDelta
end

function a.Math:SmoothStep(edge0, edge1, x)
    local t = p.Clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
end

function a.Math:LerpAngle(a, b, t)
    local delta = ((b - a + 180) % 360) - 180
    return a + delta * t
end

-- ============================================================
-- SCREEN UTILITIES
-- ============================================================

a.Screen = {}

function a.Screen:GetViewportSize()
    return workspace.CurrentCamera.ViewportSize
end

function a.Screen:GetCenter()
    local vp = self:GetViewportSize()
    return UDim2.new(0.5, 0, 0.5, 0), Vector2.new(vp.X / 2, vp.Y / 2)
end

function a.Screen:IsPointInFrame(point, frame)
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    return point.X >= pos.X and point.X <= pos.X + size.X
        and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

function a.Screen:GetScale()
    local vp = self:GetViewportSize()
    return math.min(vp.X / 1920, vp.Y / 1080)
end

function a.Screen:GetSafeArea()
    local vp = self:GetViewportSize()
    local inset = pcall(function() return game:GetService("GuiService"):GetGuiInset() end)
    return {
        Top = 0,
        Bottom = 0,
        Left = 0,
        Right = 0,
        Width = vp.X,
        Height = vp.Y
    }
end

-- ============================================================
-- EXTENDED ELEMENT: TIMESTAMP / CLOCK DISPLAY
-- ============================================================

function ElementClass.Clock(section, config)
    config = config or {}
    config.Title = config.Title or "Time"
    config.Format = config.Format or "24h"
    config.ShowSeconds = config.ShowSeconds ~= false
    config.ShowDate = config.ShowDate or false
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "Clock"
    element.Title = config.Title
    element.Locked = false

    local row = createElementRow(section, {
        Name = "Clock_" .. config.Title,
        Order = config.Order
    })
    element.Row = row

    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.5, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    local timeLabel = p.CreateLabel({
        Name = "Time",
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        Text = "",
        TextColor3 = theme.Accent,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row
    })
    element.TimeLabel = timeLabel

    spawn(function()
        while timeLabel and timeLabel.Parent do
            local date = os.date("*t")
            local hours = date.hour
            local ampm = ""
            if config.Format == "12h" then
                ampm = hours >= 12 and " PM" or " AM"
                hours = hours % 12
                if hours == 0 then hours = 12 end
            end
            local timeStr
            if config.ShowSeconds then
                timeStr = string.format("%02d:%02d:%02d", hours, date.min, date.sec) .. ampm
            else
                timeStr = string.format("%02d:%02d", hours, date.min) .. ampm
            end
            if config.ShowDate then
                timeStr = os.date("%m/%d") .. " " .. timeStr
            end
            timeLabel.Text = timeStr
            task.wait(0.5)
        end
    end)

    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(timeLabel, {TextColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end
    function element:Lock() self.Locked = true end
    function element:Unlock() self.Locked = false end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- FINAL SECTION PATCHING (Include all new elements)
-- ============================================================

local _finalPatchSection = patchSection
patchSection = function(section)
    _finalPatchSection(section)
    if section._patched3 then return section end
    section._patched3 = true

    function section:Clock(clockConfig)
        return ElementClass.Clock(self, clockConfig)
    end

    function section:MarkerSlider(msConfig)
        return ElementClass.MarkerSlider(self, msConfig)
    end

    function section:NotificationLog(nlConfig)
        return ElementClass.NotificationLog(self, nlConfig)
    end

    function section:SearchDropdown(sdConfig)
        return ElementClass.SearchDropdown(self, sdConfig)
    end

    function section:RadioGroup(radioConfig)
        return ElementClass.RadioGroup(self, radioConfig)
    end

    function section:SwitchRow(switchConfig)
        return ElementClass.SwitchRow(self, switchConfig)
    end

    function section:InlineTabs(tabConfig)
        return ElementClass.InlineTabs(self, tabConfig)
    end

    function section:Badge(badgeConfig)
        return ElementClass.Badge(self, badgeConfig)
    end

    function section:ProgressBar(progressConfig)
        return ElementClass.ProgressBar(self, progressConfig)
    end

    function section:Label(labelConfig)
        return ElementClass.Label(self, labelConfig)
    end

    function section:List(listConfig)
        return ElementClass.List(self, listConfig)
    end

    function section:SliderInput(siConfig)
        return ElementClass.SliderInput(self, siConfig)
    end

    function section:ColorDisplay(colorConfig)
        -- Color swatch display (defined in patchSection)
        colorConfig = colorConfig or {}
        colorConfig.Title = colorConfig.Title or "Color"
        colorConfig.Color = colorConfig.Color or "#007AFF"
        colorConfig.Order = colorConfig.Order or #self.Elements + 1

        local theme = Theme.GetCurrent()
        local colorElement = {}
        colorElement.Type = "ColorDisplay"
        colorElement.Title = colorConfig.Title
        colorElement.Locked = false
        colorElement.Value = colorConfig.Color

        local colorRow = createElementRow(self, {
            Name = "ColorDisplay_" .. colorConfig.Title,
            Order = colorConfig.Order
        })
        colorElement.Row = colorRow

        local colorTitle = p.CreateLabel({
            Name = "Title",
            Size = UDim2.new(0.6, 0, 1, 0),
            Text = colorConfig.Title,
            TextColor3 = theme.TextPrimary,
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            Parent = colorRow
        })

        local swatch = p.Create("Frame", {
            Name = "Swatch",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -60, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = p.Color3FromHex(colorConfig.Color),
            BorderSizePixel = 0,
            Parent = colorRow
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = swatch})
        p.Create("UIStroke", {Color = theme.Border, Transparency = 0.5, Thickness = 0.5, Parent = swatch})

        local hexLabel = p.CreateLabel({
            Name = "HexLabel",
            Size = UDim2.new(0, 50, 1, 0),
            Position = UDim2.new(1, -4, 0, 0),
            Text = colorConfig.Color,
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = colorRow
        })

        function colorElement:SetTitle(newTitle)
            self.Title = newTitle
            colorTitle.Text = newTitle
        end
        function colorElement:SetColor(hexColor)
            self.Value = hexColor
            p.Tween(swatch, {BackgroundColor3 = p.Color3FromHex(hexColor)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            hexLabel.Text = hexColor
        end
        function colorElement:Lock() self.Locked = true end
        function colorElement:Unlock() self.Locked = false end

        table.insert(self.Elements, colorElement)
        return colorElement
    end

    return section
end

-- ============================================================
-- WINDOW EXTENDED METHODS
-- ============================================================

function WindowClass:GetTabCount()
    return #self.Tabs
end

function WindowClass:GetActiveTab()
    return self.ActiveTab
end

function WindowClass:SelectTabByIndex(index)
    if index >= 1 and index <= #self.Tabs then
        self.Tabs[index]:Select()
    end
end

function WindowClass:CycleTab(direction)
    direction = direction or 1
    local currentIdx = 1
    for i, tab in ipairs(self.Tabs) do
        if tab == self.ActiveTab then
            currentIdx = i
            break
        end
    end
    local nextIdx = currentIdx + direction
    if nextIdx > #self.Tabs then nextIdx = 1 end
    if nextIdx < 1 then nextIdx = #self.Tabs end
    self.Tabs[nextIdx]:Select()
end

function WindowClass:ToggleMiniMode()
    if not self._miniMode then
        self._miniMode = true
        self._savedBeforeMini = {
            Size = self.WindowFrame.Size,
            Position = self.WindowFrame.Position,
            AnchorPoint = self.WindowFrame.AnchorPoint
        }
        self.Sidebar.Visible = false
        self.BottomBar.Visible = false
        local miniWidth = 200
        local miniHeight = self.Config.TitleBarHeight + 40
        p.Tween(self.WindowFrame, {Size = UDim2.new(0, miniWidth, 0, miniHeight)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        self.MainContent.Size = UDim2.new(1, 0, 1, -self.Config.TitleBarHeight)
        self.MainContent.Position = UDim2.new(0, 0, 0, self.Config.TitleBarHeight)
    else
        self._miniMode = false
        local isMobile = p.IsMobile()
        if isMobile then
            self.BottomBar.Visible = true
        else
            self.Sidebar.Visible = true
        end
        if self._savedBeforeMini then
            p.Tween(self.WindowFrame, {Size = self._savedBeforeMini.Size}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
        if isMobile then
            self.MainContent.Size = UDim2.new(1, 0, 1, -self.Config.BottomBarHeight)
        else
            self.MainContent.Size = UDim2.new(1, -self.Config.SideBarWidth, 1, 0)
            self.MainContent.Position = UDim2.new(0, self.Config.SideBarWidth, 0, 0)
        end
    end
end

function WindowClass:SetPinned(pinned)
    self._pinned = pinned
    if pinned then
        self._pinConnection = RunService.Heartbeat:Connect(function()
            if self._pinned and self.ScreenGui and self.ScreenGui.Parent then
                local parent = self.ScreenGui.Parent
                self.ScreenGui.Parent = nil
                self.ScreenGui.Parent = parent
            end
        end)
    else
        if self._pinConnection then
            self._pinConnection:Disconnect()
            self._pinConnection = nil
        end
    end
end

-- Keyboard shortcut: Ctrl+Tab to cycle tabs
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Tab and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        for _, window in ipairs(ActiveWindows) do
            if window.IsVisible then
                local direction = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and -1 or 1
                window:CycleTab(direction)
            end
        end
    end
end)

-- Z-Order Management
local ZOrderManager = {}
ZOrderManager.CurrentTop = 0

function ZOrderManager:BringToFront(window)
    ZOrderManager.CurrentTop = ZOrderManager.CurrentTop + 1
    if window.ScreenGui.Parent then
        window.ScreenGui.Parent = nil
        local safeParent = p.GetSafeParent()
        window.ScreenGui.Parent = safeParent
    end
end

for _, window in ipairs(ActiveWindows) do
    window.WindowFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            ZOrderManager:BringToFront(window)
        end
    end)
end

-- ============================================================
-- FINAL INITIALIZATION
-- ============================================================

-- Register global keyboard shortcuts
KeyboardShortcuts:Register("Debug Panel", Enum.KeyCode.F3, function()
    DebugSystem:Toggle()
end, "Toggle debug/performance panel")

-- Publish library loaded event
EventSystem:Publish("iOS26UI_Loaded", a.Version)

-- Version check and compatibility
pcall(function()
    local warnings = {}
    if not pcall(function() writefile end) then
        table.insert(warnings, "File I/O not available - config persistence disabled")
    end
    if not pcall(function() setclipboard end) then
        table.insert(warnings, "Clipboard not available - copy functionality disabled")
    end
    for _, warning in ipairs(warnings) do
        warn("[iOS26UI] " .. warning)
    end
end)

warn("[iOS26UI] Library v" .. a.Version .. " loaded successfully")
warn("[iOS26UI] Theme: " .. CurrentTheme)


--[[ 
============================================================
iOS 26 UI LIBRARY - COMPLETE API USAGE EXAMPLE
============================================================

local iOS26UI = loadstring(game:HttpGet("URL"))()

-- Create Window
local Window = iOS26UI:CreateWindow({
    Title = "iOS 26 UI",
    Author = "Lobster",
    Theme = "Dark",
    Size = UDim2.new(0, 580, 0, 420),
    Keybind = Enum.KeyCode.RightShift
})

-- Enable context menu and blur
Window:EnableContextMenu()
Window:EnableBlur(true)

-- Create Tabs
local HomeTab = Window:Tab({Title = "General", Icon = "home"})
local SettingsTab = Window:Tab({Title = "Settings", Icon = "settings"})
local VisualsTab = Window:Tab({Title = "Visuals", Icon = "palette"})

-- Create Sections
local MainSection = HomeTab:Section({Title = "Main Settings"})
local ActionsSection = HomeTab:Section({Title = "Actions", Collapsible = true})
local InfoSection = HomeTab:Section({Title = "Information"})

-- Button
MainSection:Button({
    Title = "Click Me",
    Icon = "zap",
    Callback = function()
        print("Button clicked!")
    end
})

-- Colored Button
ActionsSection:Button({
    Title = "Danger Action",
    Color = "#FF3B30",
    Callback = function()
        print("Danger!")
    end
})

-- Toggle
local featureToggle = MainSection:Toggle({
    Title = "Enable Feature",
    Default = false,
    Callback = function(value)
        print("Feature:", value)
    end
})

-- Slider
MainSection:Slider({
    Title = "Speed",
    Value = {Min = 0, Max = 100, Default = 50, Step = 1},
    Suffix = "%",
    Callback = function(value)
        print("Speed:", value)
    end
})

-- Dropdown
MainSection:Dropdown({
    Title = "Select Mode",
    Options = {"Easy", "Medium", "Hard", "Extreme"},
    Default = "Medium",
    Callback = function(value)
        print("Mode:", value)
    end
})

-- Searchable Dropdown
VisualsTab:Section({Title = "Search"}):SearchDropdown({
    Title = "Find Item",
    Options = {"Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"},
    Placeholder = "Search fruits...",
    Callback = function(value)
        print("Selected:", value)
    end
})

-- Input
MainSection:Input({
    Title = "Player Name",
    Placeholder = "Enter name...",
    Callback = function(value)
        print("Name:", value)
    end
})

-- Checkbox
MainSection:Checkbox({
    Title = "Auto Farm",
    Default = false,
    Callback = function(value)
        print("Auto Farm:", value)
    end
})

-- Keybind
MainSection:Keybind({
    Title = "Toggle Key",
    Default = Enum.KeyCode.E,
    Callback = function(key)
        print("Key pressed:", key.Name)
    end
})

-- Color Picker
VisualsTab:Section({Title = "Colors"}):ColorPicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(0, 122, 255),
    Callback = function(color)
        print("Color:", color)
    end
})

-- Paragraph with Buttons
InfoSection:Paragraph({
    Title = "About",
    Content = "iOS 26 UI Library with Liquid Glass effects.",
    Buttons = {
        {Title = "GitHub", Callback = function() print("GitHub") end},
        {Title = "Discord", Callback = function() print("Discord") end}
    }
})

-- Divider
MainSection:Divider({Title = "Advanced"})

-- Code Block
InfoSection:Code({
    Title = "Example",
    Content = "local ui = iOS26UI:CreateWindow({Title = 'My UI'})\nprint('Hello, iOS 26!')"
})

-- Image
VisualsTab:Section({Title = "Preview"}):Image({
    Title = "Logo",
    Source = "rbxassetid://123456789",
    Size = UDim2.new(1, 0, 0, 150)
})

-- Group
local groupSection = SettingsTab:Section({Title = "Quick Settings"})
local group = groupSection:Group({Title = "Toggles"})
group:Toggle({Title = "Fast Mode", Callback = function(v) end})
group:Toggle({Title = "Safe Mode", Callback = function(v) end})

-- Badge
MainSection:Badge({Title = "Status", Text = "Online", Color = "#34C759"})

-- Progress Bar
local progress = MainSection:ProgressBar({
    Title = "Download",
    Value = 0,
    Max = 100,
    ShowPercent = true
})
-- Update: progress:SetValue(75)

-- Radio Group
SettingsTab:Section({Title = "Difficulty"}):RadioGroup({
    Title = "Select Difficulty",
    Options = {"Easy", "Medium", "Hard"},
    Default = "Medium",
    Callback = function(value)
        print("Difficulty:", value)
    end
})

-- Switch Row
SettingsTab:Section({Title = "Quick Toggles"}):SwitchRow({
    Title = "Quick Settings",
    Switches = {
        {Title = "WiFi", Default = true, Callback = function(v) end},
        {Title = "Bluetooth", Default = false, Callback = function(v) end},
        {Title = "AirDrop", Default = true, Callback = function(v) end},
        {Title = "VPN", Default = false, Callback = function(v) end}
    }
})

-- Clock Display
InfoSection:Clock({Title = "Local Time", Format = "12h", ShowSeconds = true})

-- Color Display
InfoSection:ColorDisplay({Title = "Theme Accent", Color = "#007AFF"})

-- Notification
Window:Notify({
    Title = "Welcome!",
    Content = "iOS 26 UI Library loaded successfully.",
    Duration = 5,
    Style = "Success",
    Icon = "sparkles"
})

-- Dialog
Window:Dialog({
    Title = "Confirm Action",
    Content = "Are you sure you want to proceed?",
    Buttons = {
        {Title = "Cancel", Color = "#8E8E93", Callback = function() print("Cancelled") end},
        {Title = "Confirm", Color = "#007AFF", Callback = function() print("Confirmed") end}
    }
})

-- Theme operations
iOS26UI:ToggleTheme()
iOS26UI:ApplyPreset("Ocean")

-- Window operations
Window:Center()
Window:AddStatusBar({Text = "Ready"})
Window:AddSearchBar({Placeholder = "Search settings..."})

-- Element methods
featureToggle:SetValue(true)
featureToggle:SetTitle("New Title")
featureToggle:Lock()
featureToggle:Unlock()

-- Animation system
iOS26UI.Animation:Shake(Window.WindowFrame, 5, 0.4)
iOS26UI.Animation:Bounce(Window.WindowFrame, 10, 0.5)

-- Events
iOS26UI.Events:Subscribe("MyEvent", function(data)
    print("Event received:", data)
end)
iOS26UI.Events:Publish("MyEvent", "Hello!")

-- Debug
iOS26UI.Debug:Toggle()

-- Window state
Window:SaveState()
Window:ToggleMiniMode()

-- Config
iOS26UI:SetFlag("mySetting", true)
print(iOS26UI:GetFlag("mySetting"))

-- iOS System Colors
local blue = iOS26UI.Colors.SystemBlue
local palette = iOS26UI.ColorUtils:GeneratePalette(blue, 5)

-- Easing functions
local easedValue = iOS26UI.Easing.ElasticOut(0.5)

-- Math utilities
local mapped = iOS26UI.Math:Map(50, 0, 100, 0, 1)

-- Screen info
local isMobile = iOS26UI:IsMobile()
local viewport = iOS26UI.Screen:GetViewportSize()

============================================================
]]


-- ============================================================
-- EXTENDED ELEMENT: NOTIFICATION LOG
-- ============================================================

function ElementClass.NotificationLog(section, config)
    config = config or {}
    config.Title = config.Title or "Notifications"
    config.MaxLogs = config.MaxLogs or 10
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "NotificationLog"
    element.Title = config.Title
    element.Locked = false
    element.Logs = {}

    local row = createElementRow(section, {
        Name = "NotificationLog_" .. config.Title,
        Order = config.Order,
        Height = 0
    })
    row.AutomaticSize = Enum.AutomaticSize.Y
    element.Row = row

    local logContainer = p.CreateCardFrame({
        Name = "LogContainer",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0.5,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = row
    })

    local logLayout = p.Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = logContainer
    })

    local logPadding = p.Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = logContainer
    })

    local logTitle = p.CreateLabel({
        Name = "LogTitle",
        Size = UDim2.new(1, 0, 0, 16),
        Text = config.Title,
        TextColor3 = theme.SectionHeader,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Parent = logContainer
    })

    local clearBtn = p.Create("TextButton", {
        Name = "ClearBtn",
        Size = UDim2.new(0, 40, 0, 16),
        Position = UDim2.new(1, 0, 0, 6),
        BackgroundTransparency = 1,
        Text = "Clear",
        TextColor3 = theme.Danger,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 100,
        Parent = logContainer
    })

    clearBtn.MouseButton1Click:Connect(function()
        element:Clear()
    end)

    local placeholder = p.CreateLabel({
        Name = "Placeholder",
        Size = UDim2.new(1, 0, 0, 30),
        Text = "No notifications yet",
        TextColor3 = theme.TextTertiary,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = logContainer
    })

    function element:AddLog(message, style)
        style = style or "Info"
        local styleColors = {
            Info = theme.Info,
            Success = theme.Success,
            Warning = theme.Warning,
            Danger = theme.Danger
        }
        local styleColor = styleColors[style] or theme.Info
        placeholder.Visible = false

        local logEntry = p.Create("Frame", {
            Name = "LogEntry",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = #self.Logs + 1,
            Parent = logContainer
        })

        local dot = p.Create("Frame", {
            Name = "Dot",
            Size = UDim2.new(0, 6, 0, 6),
            Position = UDim2.new(0, 2, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = styleColor,
            BorderSizePixel = 0,
            Parent = logEntry
        })
        p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dot})

        local timeStr = os.date("%H:%M")
        local msgLabel = p.CreateLabel({
            Name = "Message",
            Size = UDim2.new(1, -56, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            Text = message,
            TextColor3 = theme.TextSecondary,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = logEntry
        })

        local timeLabel = p.CreateLabel({
            Name = "Time",
            Size = UDim2.new(0, 36, 1, 0),
            Position = UDim2.new(1, -2, 0, 0),
            Text = timeStr,
            TextColor3 = theme.TextTertiary,
            TextSize = 9,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = logEntry
        })

        table.insert(self.Logs, {Message = message, Style = style, Frame = logEntry})

        if #self.Logs > config.MaxLogs then
            local oldest = table.remove(self.Logs, 1)
            if oldest.Frame and oldest.Frame.Parent then
                oldest.Frame:Destroy()
            end
        end
    end

    function element:Clear()
        for _, log in ipairs(self.Logs) do
            if log.Frame and log.Frame.Parent then
                log.Frame:Destroy()
            end
        end
        self.Logs = {}
        placeholder.Visible = true
    end

    Theme.OnChanged(function(th)
        p.Tween(logTitle, {TextColor3 = th.SectionHeader}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(logContainer, {BackgroundColor3 = th.CardBackground}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(placeholder, {TextColor3 = th.TextTertiary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(clearBtn, {TextColor3 = th.Danger}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        logTitle.Text = newTitle
    end
    function element:Lock() self.Locked = true end
    function element:Unlock() self.Locked = false end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- MARKER SLIDER (Slider with labeled tick marks)
-- ============================================================

function ElementClass.MarkerSlider(section, config)
    config = config or {}
    config.Title = config.Title or "Marker Slider"
    config.Value = config.Value or {}
    config.Value.Min = config.Value.Min or 0
    config.Value.Max = config.Value.Max or 100
    config.Value.Default = config.Value.Default or 50
    config.Value.Step = config.Value.Step or 1
    config.Markers = config.Markers or {}
    config.Callback = config.Callback or function() end
    config.Order = config.Order or #section.Elements + 1
    config.Suffix = config.Suffix or ""

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "MarkerSlider"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Value.Default
    element.Min = config.Value.Min
    element.Max = config.Value.Max
    element.Step = config.Value.Step
    element.Callback = config.Callback

    local row = createElementRow(section, {
        Name = "MarkerSlider_" .. config.Title,
        Order = config.Order,
        Height = 72
    })
    element.Row = row

    local topRow = p.Create("Frame", {
        Name = "TopRow",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = row
    })

    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.6, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = topRow
    })
    element.TitleLabel = titleLabel

    local valueLabel = p.CreateLabel({
        Name = "ValueLabel",
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        Text = tostring(config.Value.Default) .. config.Suffix,
        TextColor3 = theme.Accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = topRow
    })
    element.ValueLabel = valueLabel

    local sliderTrack = p.Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = theme.SliderTrack,
        BorderSizePixel = 0,
        Parent = row
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderTrack})

    local defaultPercent = (config.Value.Default - config.Value.Min) / (config.Value.Max - config.Value.Min)
    local sliderFill = p.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(defaultPercent, 0, 1, 0),
        BackgroundColor3 = theme.SliderFill,
        BorderSizePixel = 0,
        Parent = sliderTrack
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderFill})

    local knobSize = 18
    local sliderKnob = p.Create("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, knobSize, 0, knobSize),
        Position = UDim2.new(defaultPercent, -knobSize/2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = sliderTrack.ZIndex + 2,
        Parent = sliderTrack
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderKnob})

    -- Marker tick marks and labels
    for _, marker in ipairs(config.Markers) do
        local mPct = (marker.Value - config.Value.Min) / (config.Value.Max - config.Value.Min)
        local tickMark = p.Create("Frame", {
            Name = "Tick_" .. tostring(marker.Value),
            Size = UDim2.new(0, 1, 0, 6),
            Position = UDim2.new(mPct, 0, 1, 0),
            BackgroundColor3 = theme.TextTertiary,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = sliderTrack
        })
        if marker.Label then
            local markerRow = p.Create("Frame", {
                Name = "MarkerRow",
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.new(0, 0, 0, 38),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = row
            })
            local mLabel = p.CreateLabel({
                Name = "MarkerLabel",
                Size = UDim2.new(0, 40, 1, 0),
                Position = UDim2.new(mPct, -20, 0, 0),
                Text = marker.Label,
                TextColor3 = theme.TextTertiary,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = markerRow
            })
        end
    end

    local interactionArea = p.Create("TextButton", {
        Name = "Interaction",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    local dragging = false

    local function updateSlider(input)
        local relX = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
        local percent = p.Clamp(relX, 0, 1)
        local rawValue = config.Value.Min + (config.Value.Max - config.Value.Min) * percent
        local steppedValue = p.Round(rawValue / config.Value.Step) * config.Value.Step
        steppedValue = p.Clamp(steppedValue, config.Value.Min, config.Value.Max)
        local newPercent = (steppedValue - config.Value.Min) / (config.Value.Max - config.Value.Min)
        element.Value = steppedValue
        sliderFill.Size = UDim2.new(newPercent, 0, 1, 0)
        sliderKnob.Position = UDim2.new(newPercent, -knobSize/2, 0.5, 0)
        valueLabel.Text = tostring(steppedValue) .. config.Suffix
        element.Callback(steppedValue)
    end

    interactionArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
            p.Tween(sliderKnob, {Size = UDim2.new(0, knobSize + 4, 0, knobSize + 4)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    p.Tween(sliderKnob, {Size = UDim2.new(0, knobSize, 0, knobSize)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)

    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(valueLabel, {TextColor3 = th.Accent}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderTrack, {BackgroundColor3 = th.SliderTrack}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(sliderFill, {BackgroundColor3 = th.SliderFill}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        value = p.Clamp(value, config.Value.Min, config.Value.Max)
        value = p.Round(value / config.Value.Step) * config.Value.Step
        self.Value = value
        local pct = (value - config.Value.Min) / (config.Value.Max - config.Value.Min)
        sliderFill.Size = UDim2.new(pct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pct, -knobSize/2, 0.5, 0)
        valueLabel.Text = tostring(value) .. config.Suffix
        self.Callback(value)
    end

    function element:Lock() self.Locked = true end
    function element:Unlock() self.Locked = false end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- SEARCH DROPDOWN (Dropdown with search/filter)
-- ============================================================

function ElementClass.SearchDropdown(section, config)
    config = config or {}
    config.Title = config.Title or "Search Dropdown"
    config.Options = config.Options or {}
    config.Default = config.Default or nil
    config.Callback = config.Callback or function() end
    config.Placeholder = config.Placeholder or "Search..."
    config.Order = config.Order or #section.Elements + 1

    local theme = Theme.GetCurrent()
    local element = {}
    element.Type = "SearchDropdown"
    element.Title = config.Title
    element.Locked = false
    element.Value = config.Default
    element.Options = config.Options
    element.Callback = config.Callback
    element.IsOpen = false

    local row = createElementRow(section, {
        Name = "SearchDropdown_" .. config.Title,
        Order = config.Order,
        Height = 42
    })
    element.Row = row

    local titleLabel = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0.4, 0, 1, 0),
        Text = config.Title,
        TextColor3 = theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        Parent = row
    })
    element.TitleLabel = titleLabel

    local valueLabel = p.CreateLabel({
        Name = "ValueLabel",
        Size = UDim2.new(0.5, -20, 1, 0),
        Position = UDim2.new(0.4, 0, 0, 0),
        Text = config.Default or config.Placeholder,
        TextColor3 = theme.TextSecondary,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row
    })
    element.ValueLabel = valueLabel

    local chevron = Icons.Create("chevron_down", {
        Size = 14,
        Position = UDim2.new(1, -4, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Color = theme.TextSecondary,
        Parent = row
    })

    local clickArea = p.Create("TextButton", {
        Name = "ClickArea",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })

    local dropdownPopup = nil
    local searchInput = nil
    local optionContainer = nil
    local optionButtons = {}

    local function buildOptions(options, filter)
        filter = (filter or ""):lower()
        if optionContainer then
            for _, child in ipairs(optionContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            optionButtons = {}
            for i, opt in ipairs(options) do
                if filter ~= "" then
                    if not tostring(opt):lower():find(filter, 1, true) then
                        continue
                    end
                end
                local optBtn = p.Create("TextButton", {
                    Name = "Option_" .. tostring(opt),
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                    ZIndex = 101,
                    Parent = optionContainer
                })
                local optLabel = p.CreateLabel({
                    Name = "Label",
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    Text = tostring(opt),
                    TextColor3 = theme.TextPrimary,
                    TextSize = 13,
                    Font = Enum.Font.Gotham,
                    Parent = optBtn
                })
                local checkIcon = Icons.Create("check", {
                    Size = 12,
                    Position = UDim2.new(1, -10, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Color = theme.Accent,
                    Parent = optBtn
                })
                checkIcon.Visible = (opt == element.Value)
                optBtn.MouseButton1Click:Connect(function()
                    element.Value = opt
                    valueLabel.Text = tostring(opt)
                    valueLabel.TextColor3 = theme.Accent
                    element.Callback(opt)
                    closeSearchDropdown()
                end)
                optBtn.MouseEnter:Connect(function()
                    p.Tween(optBtn, {BackgroundColor3 = theme.DropdownHover, BackgroundTransparency = 0}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end)
                optBtn.MouseLeave:Connect(function()
                    p.Tween(optBtn, {BackgroundTransparency = 1}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end)
                optBtn._OptionValue = opt
                optBtn._CheckIcon = checkIcon
                table.insert(optionButtons, optBtn)
            end
        end
    end

    local function createSearchPopup()
        dropdownPopup = p.CreateCardFrame({
            Name = "SearchPopup",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 2),
            BackgroundColor3 = theme.DropdownBackground,
            ClipsDescendants = true,
            Visible = false,
            ZIndex = 100,
            Parent = row
        })
        p.Create("UIStroke", {Color = theme.Border, Transparency = 0.5, Thickness = 0.5, Parent = dropdownPopup})

        local searchFrame = p.Create("Frame", {
            Name = "SearchFrame",
            Size = UDim2.new(1, -8, 0, 30),
            BackgroundColor3 = theme.InputBackground,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = dropdownPopup
        })
        p.Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = searchFrame})
        p.Create("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = searchFrame})

        searchInput = p.Create("TextBox", {
            Name = "SearchInput",
            Size = UDim2.new(1, -8, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            PlaceholderText = config.Placeholder,
            PlaceholderColor3 = theme.Placeholder,
            TextColor3 = theme.TextPrimary,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
            Parent = searchFrame
        })

        optionContainer = p.Create("ScrollingFrame", {
            Name = "Options",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.TextSecondary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 100,
            Parent = dropdownPopup
        })
        p.Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Parent = optionContainer})

        buildOptions(config.Options)

        searchInput:GetPropertyChangedSignal("Text"):Connect(function()
            buildOptions(config.Options, searchInput.Text)
        end)
    end

    local function openSearchDropdown()
        if element.IsOpen or element.Locked then return end
        element.IsOpen = true
        if not dropdownPopup then createSearchPopup() end
        dropdownPopup.Visible = true
        dropdownPopup.Size = UDim2.new(1, 0, 0, 0)
        local maxVisible = math.min(#config.Options, 6)
        local totalHeight = 34 + maxVisible * 30 + 4
        p.Tween(dropdownPopup, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        p.Tween(chevron, {Rotation = 180}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        task.delay(0.1, function()
            if searchInput and searchInput.Parent then searchInput:CaptureFocus() end
        end)
    end

    function closeSearchDropdown()
        if not element.IsOpen then return end
        element.IsOpen = false
        if dropdownPopup then
            p.Tween(dropdownPopup, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In, function()
                dropdownPopup.Visible = false
                if searchInput then searchInput.Text = "" end
            end)
            p.Tween(chevron, {Rotation = 0}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end

    clickArea.MouseButton1Click:Connect(function()
        if element.IsOpen then closeSearchDropdown() else openSearchDropdown() end
    end)

    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if element.IsOpen and dropdownPopup then
                local mousePos = input.Position
                local pp = dropdownPopup.AbsolutePosition
                local ps = dropdownPopup.AbsoluteSize
                local rp = row.AbsolutePosition
                local rs = row.AbsoluteSize
                local inPopup = mousePos.X >= pp.X and mousePos.X <= pp.X + ps.X and mousePos.Y >= pp.Y and mousePos.Y <= pp.Y + ps.Y
                local inRow = mousePos.X >= rp.X and mousePos.X <= rp.X + rs.X and mousePos.Y >= rp.Y and mousePos.Y <= rp.Y + rs.Y
                if not inPopup and not inRow then closeSearchDropdown() end
            end
        end
    end)

    Theme.OnChanged(function(th)
        p.Tween(titleLabel, {TextColor3 = th.TextPrimary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(valueLabel, {TextColor3 = element.Value and th.Accent or th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        p.Tween(chevron, {ImageColor3 = th.TextSecondary}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if row._Divider then
            p.Tween(row._Divider, {BackgroundColor3 = th.Divider}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
    end)

    function element:SetTitle(newTitle)
        self.Title = newTitle
        titleLabel.Text = newTitle
    end

    function element:SetValue(value)
        self.Value = value
        valueLabel.Text = tostring(value)
        valueLabel.TextColor3 = Theme.GetCurrent().Accent
        self.Callback(value)
    end

    function element:SetOptions(newOptions)
        config.Options = newOptions
        self.Options = newOptions
        buildOptions(newOptions, searchInput and searchInput.Text or "")
    end

    function element:Lock() self.Locked = true closeSearchDropdown() end
    function element:Unlock() self.Locked = false end

    table.insert(section.Elements, element)
    return element
end

-- ============================================================
-- WINDOW STATE SAVE/LOAD
-- ============================================================

function WindowClass:SaveState()
    local state = {
        PosX_S = self.WindowFrame.Position.X.Scale,
        PosX_O = self.WindowFrame.Position.X.Offset,
        PosY_S = self.WindowFrame.Position.Y.Scale,
        PosY_O = self.WindowFrame.Position.Y.Offset,
        SizeX_S = self.WindowFrame.Size.X.Scale,
        SizeX_O = self.WindowFrame.Size.X.Offset,
        SizeY_S = self.WindowFrame.Size.Y.Scale,
        SizeY_O = self.WindowFrame.Size.Y.Offset,
        Visible = self.IsVisible,
        Transparency = self.TransparencyValue
    }
    local stateKey = "iOS26UI_Window_" .. self.Config.Title
    ConfigSystem:SetFlag(stateKey, HttpService:JSONEncode(state))
end

function WindowClass:LoadState()
    local stateKey = "iOS26UI_Window_" .. self.Config.Title
    local stateJson = ConfigSystem:GetFlag(stateKey)
    if stateJson then
        pcall(function()
            local state = HttpService:JSONDecode(stateJson)
            self.WindowFrame.Position = UDim2.new(state.PosX_S, state.PosX_O, state.PosY_S, state.PosY_O)
            self.WindowFrame.Size = UDim2.new(state.SizeX_S, state.SizeX_O, state.SizeY_S, state.SizeY_O)
            if state.Transparency then
                self:SetTransparency(state.Transparency)
            end
        end)
    end
end

-- ============================================================
-- WINDOW ANIMATION PRESETS
-- ============================================================

function WindowClass:AnimateIn(style)
    style = style or "scale"
    if style == "scale" then
        self.WindowFrame.Size = UDim2.new(0, 0, 0, 0)
        p.Tween(self.WindowFrame, {Size = self.Config.Size}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    elseif style == "slide_left" then
        local targetPos = self.WindowFrame.Position
        self.WindowFrame.Position = UDim2.new(-1, 0, targetPos.Y.Scale, targetPos.Y.Offset)
        p.Tween(self.WindowFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif style == "slide_bottom" then
        local targetPos = self.WindowFrame.Position
        self.WindowFrame.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, 2, 0)
        p.Tween(self.WindowFrame, {Position = targetPos}, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    elseif style == "elastic" then
        self.WindowFrame.Size = UDim2.new(0, 0, 0, 0)
        p.Tween(self.WindowFrame, {Size = self.Config.Size}, 0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    elseif style == "fade" then
        self.WindowFrame.BackgroundTransparency = 1
        p.Tween(self.WindowFrame, {BackgroundTransparency = Theme.GetCurrent().GlassTransparency}, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end
end

function WindowClass:AnimateOut(style, callback)
    style = style or "scale"
    callback = callback or function() end
    if style == "scale" then
        p.Tween(self.WindowFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, callback)
    elseif style == "slide_left" then
        p.Tween(self.WindowFrame, {Position = UDim2.new(-1, 0, 0.5, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In, callback)
    elseif style == "fade" then
        p.Tween(self.WindowFrame, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, callback)
    end
end

-- ============================================================
-- WINDOW BLUR EFFECT
-- ============================================================

function WindowClass:EnableBlur(enabled)
    if enabled == nil then enabled = true end
    if enabled then
        if not self._blurFrame then
            local theme = Theme.GetCurrent()
            self._blurFrame = p.Create("ImageLabel", {
                Name = "BlurEffect",
                Size = UDim2.new(1, 40, 1, 40),
                Position = UDim2.new(0, -20, 0, -20),
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 0.95,
                BorderSizePixel = 0,
                Image = "rbxassetid://6015897843",
                ImageColor3 = theme.Accent,
                ImageTransparency = 0.85,
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(49, 49, 450, 450),
                ZIndex = self.WindowFrame.ZIndex - 1,
                Parent = self.WindowFrame
            })
            p.Create("UICorner", {CornerRadius = UDim.new(0, self.Config.CornerRadius + 10), Parent = self._blurFrame})
        end
        self._blurFrame.Visible = true
    else
        if self._blurFrame then self._blurFrame.Visible = false end
    end
end


-- ============================================================
-- ADDITIONAL WINDOW FEATURES
-- ============================================================

--- Set window anchor point
function WindowClass:SetAnchorPoint(anchorPoint)
    local currentPos = self.WindowFrame.Position
    local currentSize = self.WindowFrame.Size
    local currentAP = self.WindowFrame.AnchorPoint

    -- Calculate position change
    local deltaX = (anchorPoint.X - currentAP.X) * currentSize.X.Offset
    local deltaY = (anchorPoint.Y - currentAP.Y) * currentSize.Y.Offset

    self.WindowFrame.AnchorPoint = anchorPoint
    self.WindowFrame.Position = UDim2.new(
        currentPos.X.Scale, currentPos.X.Offset + deltaX,
        currentPos.Y.Scale, currentPos.Y.Offset + deltaY
    )
end

--- Get window absolute position and size
function WindowClass:GetBounds()
    return {
        Position = self.WindowFrame.AbsolutePosition,
        Size = self.WindowFrame.AbsoluteSize
    }
end

--- Check if point is inside window
function WindowClass:IsPointInside(x, y)
    local pos = self.WindowFrame.AbsolutePosition
    local size = self.WindowFrame.AbsoluteSize
    return x >= pos.X and x <= pos.X + size.X
        and y >= pos.Y and y <= pos.Y + size.Y
end

--- Set window opacity (alias for transparency)
function WindowClass:SetOpacity(opacity)
    self:SetTransparency(1 - opacity)
end

--- Flash window border
function WindowClass:Flash(color, count)
    color = color or Theme.GetCurrent().Accent
    count = count or 3
    local stroke = self.WindowFrame:FindFirstChild("WindowStroke")
    if not stroke then return end
    local originalColor = stroke.Color
    local originalTransparency = stroke.Transparency

    for i = 1, count do
        task.delay((i - 1) * 0.3, function()
            p.Tween(stroke, {Color = color, Transparency = 0}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            task.delay(0.15, function()
                p.Tween(stroke, {Color = originalColor, Transparency = originalTransparency}, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            end)
        end)
    end
end

--- Add a tab quickly
function WindowClass:QuickTab(title, icon)
    return self:Tab({Title = title, Icon = icon})
end

-- ============================================================
-- ELEMENT STATE PERSISTENCE
-- ============================================================

local ElementPersistence = {}

function ElementPersistence:SaveElement(element, windowTitle)
    if not element.Type or not element.Title then return end
    local key = windowTitle .. "_" .. element.Type .. "_" .. element.Title
    if element.Value ~= nil then
        local valueToSave = element.Value
        if typeof(valueToSave) == "Color3" then
            valueToSave = p.Color3ToHex(valueToSave)
        elseif typeof(valueToSave) == "EnumItem" then
            valueToSave = valueToSave.Name
        end
        ConfigSystem:SetFlag(key, valueToSave)
    end
end

function ElementPersistence:LoadElement(element, windowTitle)
    if not element.Type or not element.Title then return end
    local key = windowTitle .. "_" .. element.Type .. "_" .. element.Title
    local savedValue = ConfigSystem:GetFlag(key)
    if savedValue ~= nil and element.SetValue then
        pcall(function()
            element:SetValue(savedValue)
        end)
    end
end

a.Persistence = ElementPersistence

-- ============================================================
-- WINDOW AUTO-SAVE ELEMENT VALUES
-- ============================================================

function WindowClass:AutoSaveElements()
    for _, tab in ipairs(self.Tabs) do
        for _, section in ipairs(tab.Sections) do
            for _, element in ipairs(section.Elements) do
                ElementPersistence:SaveElement(element, self.Config.Title)
            end
        end
    end
end

function WindowClass:AutoLoadElements()
    for _, tab in ipairs(self.Tabs) do
        for _, section in ipairs(tab.Sections) do
            for _, element in ipairs(section.Elements) do
                ElementPersistence:LoadElement(element, self.Config.Title)
            end
        end
    end
end

-- ============================================================
-- WINDOW SCREENSHOT (Capture UI as image)
-- ============================================================

function WindowClass:CaptureScreenshot()
    -- This is a placeholder for UI screenshot functionality
    -- In a real implementation, this would use viewport capture
    warn("[iOS26UI] Screenshot capture not available in this environment")
    return nil
end

-- ============================================================
-- ELEMENT HOVER EFFECTS HELPER
-- ============================================================

function p.AddHoverEffect(frame, hoverProps, duration)
    duration = duration or 0.2
    local originalProps = {}
    for k, _ in pairs(hoverProps) do
        originalProps[k] = frame[k]
    end

    frame.MouseEnter:Connect(function()
        p.Tween(frame, hoverProps, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)

    frame.MouseLeave:Connect(function()
        p.Tween(frame, originalProps, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
end

-- ============================================================
-- ELEMENT CLICK EFFECT HELPER
-- ============================================================

function p.AddClickEffect(frame, config)
    config = config or {}
    local scaleDown = config.ScaleDown or 0.95
    local clickDuration = config.ClickDuration or 0.08
    local releaseDuration = config.ReleaseDuration or 0.3
    local releaseEasing = config.ReleaseEasing or Enum.EasingStyle.Back
    local onClick = config.OnClick or function() end

    local originalSize = frame.Size

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            p.Tween(frame, {
                Size = UDim2.new(
                    originalSize.X.Scale, originalSize.X.Offset * scaleDown,
                    originalSize.Y.Scale, originalSize.Y.Offset * scaleDown
                )
            }, clickDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            p.Tween(frame, {Size = originalSize}, releaseDuration, releaseEasing, Enum.EasingDirection.Out)
            onClick()
        end
    end)
end

-- ============================================================
-- ELEMENT FOCUS RING HELPER
-- ============================================================

function p.AddFocusRing(frame, config)
    config = config or {}
    local color = config.Color or Theme.GetCurrent().Accent
    local thickness = config.Thickness or 2
    local cornerRadius = config.CornerRadius or UDim.new(0, 12)
    local padding = config.Padding or 4

    local focusRing = p.Create("Frame", {
        Name = "FocusRing",
        Size = UDim2.new(1, padding * 2, 1, padding * 2),
        Position = UDim2.new(0, -padding, 0, -padding),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = frame.ZIndex + 100,
        Parent = frame
    })
    p.Create("UICorner", {CornerRadius = cornerRadius, Parent = focusRing})
    p.Create("UIStroke", {
        Color = color,
        Thickness = thickness,
        Parent = focusRing
    })

    return focusRing
end

-- ============================================================
-- DYNAMIC SCALING HELPER
-- ============================================================

function p.GetDynamicScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local baseWidth = 1920
    local baseHeight = 1080
    local scaleX = vp.X / baseWidth
    local scaleY = vp.Y / baseHeight
    return math.min(scaleX, scaleY)
end

function p.ScaleUDim2(original, scaleFactor)
    return UDim2.new(
        original.X.Scale,
        math.floor(original.X.Offset * scaleFactor),
        original.Y.Scale,
        math.floor(original.Y.Offset * scaleFactor)
    )
end

function p.ScaleUDim(original, scaleFactor)
    return UDim.new(original.Scale, math.floor(original.Offset * scaleFactor))
end

-- ============================================================
-- RESPONSIVE FONT SIZE
-- ============================================================

function p.GetResponsiveTextSize(baseSize)
    local scale = p.GetDynamicScale()
    return math.max(8, math.floor(baseSize * math.max(0.7, math.min(1.2, scale))))
end

-- ============================================================
-- ELEMENT FACTORY EXTENSIONS
-- ============================================================

a.ElementFactory.CreateButton = function(config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local btn = p.Create("TextButton", {
        Name = config.Name or "FactoryButton",
        Size = config.Size or UDim2.new(0, 120, 0, 36),
        Position = config.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.Color or theme.Accent,
        BackgroundTransparency = 0,
        Text = config.Text or "Button",
        TextColor3 = theme.AccentText,
        TextSize = config.TextSize or 14,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = config.Parent
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, config.CornerRadius or 10), Parent = btn})

    if config.Callback then
        btn.MouseButton1Click:Connect(config.Callback)
    end

    p.ApplyPressScale(btn, 0.96, 0.1)

    return btn
end

a.ElementFactory.CreateCard = function(config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local card = p.CreateCardFrame({
        Name = config.Name or "FactoryCard",
        Size = config.Size or UDim2.new(1, 0, 0, 60),
        Position = config.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = config.Color or theme.CardBackground,
        Parent = config.Parent
    })
    return card
end

a.ElementFactory.CreateLabel = function(config)
    config = config or {}
    return p.CreateLabel({
        Name = config.Name or "FactoryLabel",
        Size = config.Size or UDim2.new(1, 0, 0, 20),
        Position = config.Position or UDim2.new(0, 0, 0, 0),
        Text = config.Text or "",
        TextColor3 = config.Color or Theme.GetCurrent().TextPrimary,
        TextSize = config.TextSize or 14,
        Font = config.Font or Enum.Font.GothamMedium,
        TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left,
        Parent = config.Parent
    })
end

-- ============================================================
-- FINAL LIBRARY CLEANUP ON SCRIPT EXIT
-- ============================================================

-- Register cleanup for when the script is destroyed
local function setupCleanup()
    local ancestryChangedConn
    ancestryChangedConn = script.AncestryChanged:Connect(function()
        if not script:IsDescendantOf(game) then
            -- Cleanup all windows
            for _, window in ipairs(ActiveWindows) do
                pcall(function()
                    if window.ScreenGui and window.ScreenGui.Parent then
                        window.ScreenGui:Destroy()
                    end
                end)
            end
            ActiveWindows = {}
            if ancestryChangedConn then
                ancestryChangedConn:Disconnect()
            end
        end
    end)
end

pcall(setupCleanup)

-- ============================================================
-- LIBRARY METATABLE & TYPE CHECKING
-- ============================================================

-- Set metatable for library
setmetatable(a, {
    __index = function(self, key)
        local lowerKey = key:sub(1, 1):lower() .. key:sub(2)
        if rawget(self, lowerKey) then
            return rawget(self, lowerKey)
        end
        return nil
    end,
    __tostring = function()
        return "iOS26UI v" .. a.Version
    end,
    __call = function(self, config)
        return self:CreateWindow(config)
    end
})

-- ============================================================
-- TYPE DEFINITIONS (For IDE autocomplete hints)
-- ============================================================

--[[
    Type definitions for autocomplete support:

    Window = {
        Tabs: table,
        ActiveTab: Tab,
        IsVisible: boolean,
        IsFullscreen: boolean,
        IsLocked: boolean,
        WindowFrame: Frame,
        ScreenGui: ScreenGui,
        TitleBar: Frame,
        Sidebar: Frame,
        BottomBar: Frame,
        MainContent: ScrollingFrame,

        Tab: function(config) -> Tab,
        ToggleVisibility: function(),
        ToggleFullscreen: function(),
        SetTransparency: function(value: number),
        SetTitle: function(title: string),
        Show: function(),
        Hide: function(),
        Lock: function(),
        Unlock: function(),
        Center: function(),
        MoveTo: function(position: UDim2),
        Resize: function(size: UDim2),
        SnapToEdge: function(edge: string),
        Minimize: function(),
        SetKeybind: function(keyCode: EnumItem),
        AddStatusBar: function(config) -> table,
        AddSearchBar: function(config) -> table,
        EnableContextMenu: function(),
        EnableBlur: function(enabled: boolean),
        EnableSectionReorder: function(),
        SavePosition: function(),
        LoadPosition: function(),
        SaveState: function(),
        LoadState: function(),
        AnimateIn: function(style: string),
        AnimateOut: function(style: string, callback: function),
        ToggleMiniMode: function(),
        SetPinned: function(pinned: boolean),
        Notify: function(config) -> table,
        Dialog: function(config) -> table,
        GetTab: function(name: string) -> Tab,
        SelectTab: function(name: string),
        CycleTab: function(direction: number),
        Flash: function(color: Color3, count: number),
        Destroy: function()
    }

    Tab = {
        Title: string,
        Icon: string,
        IsSelected: boolean,
        Locked: boolean,
        Sections: table,
        ContentFrame: Frame,

        Section: function(config) -> Section,
        SetTitle: function(title: string),
        Lock: function(),
        Unlock: function(),
        Select: function()
    }

    Section = {
        Title: string,
        IsCollapsed: boolean,
        Locked: boolean,
        Elements: table,

        Button: function(config) -> Element,
        Toggle: function(config) -> Element,
        Slider: function(config) -> Element,
        Dropdown: function(config) -> Element,
        Input: function(config) -> Element,
        Checkbox: function(config) -> Element,
        Keybind: function(config) -> Element,
        ColorPicker: function(config) -> Element,
        Paragraph: function(config) -> Element,
        Divider: function(config) -> Element,
        Code: function(config) -> Element,
        Image: function(config) -> Element,
        Group: function(config) -> Element,
        Badge: function(config) -> Element,
        ProgressBar: function(config) -> Element,
        Label: function(config) -> Element,
        List: function(config) -> Element,
        SliderInput: function(config) -> Element,
        RadioGroup: function(config) -> Element,
        SwitchRow: function(config) -> Element,
        InlineTabs: function(config) -> Element,
        SearchDropdown: function(config) -> Element,
        Clock: function(config) -> Element,
        MarkerSlider: function(config) -> Element,
        NotificationLog: function(config) -> Element,
        ColorDisplay: function(config) -> Element,
        SetTitle: function(title: string),
        Collapse: function(),
        Expand: function(),
        Lock: function(),
        Unlock: function()
    }

    Element = {
        Type: string,
        Title: string,
        Value: any,
        Locked: boolean,

        SetTitle: function(title: string),
        SetValue: function(value: any),
        Lock: function(),
        Unlock: function()
    }
]]

-- ============================================================
-- END OF iOS 26 UI LIBRARY
-- ============================================================
-- Total elements: 25+ UI element types
-- Total window features: 30+ methods
-- Theme system: Dark, Light + 5 presets + custom
-- Animation system: 10+ easing functions, spring physics
-- Responsive: Mobile + Desktop adaptive layout
-- Persistence: Config save/load, element state persistence
-- Accessibility: Screen reader support, keyboard navigation
-- Debug: Performance monitor, FPS counter
-- Events: Pub/Sub system for inter-component communication
-- ============================================================


-- ============================================================
-- ADDITIONAL UI HELPERS
-- ============================================================

--- Create a circular progress indicator
function p.CreateCircularProgress(parent, config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local size = config.Size or 40
    local thickness = config.Thickness or 3
    local progress = config.Progress or 0

    local container = p.Create("Frame", {
        Name = "CircularProgress",
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
        Parent = parent
    })

    local bgCircle = p.Create("Frame", {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.SliderTrack,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = container
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = bgCircle})
    p.Create("UIStroke", {
        Color = theme.SliderTrack,
        Thickness = thickness,
        Transparency = 0.5,
        Parent = bgCircle
    })

    local progressLabel = p.CreateLabel({
        Name = "Percent",
        Size = UDim2.new(1, 0, 1, 0),
        Text = tostring(math.floor(progress * 100)) .. "%",
        TextColor3 = theme.TextPrimary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = container
    })

    return {
        Container = container,
        SetProgress = function(value)
            progress = p.Clamp(value, 0, 1)
            progressLabel.Text = tostring(math.floor(progress * 100)) .. "%"
        end,
        Destroy = function()
            container:Destroy()
        end
    }
end

--- Create a skeleton loading placeholder
function p.CreateSkeleton(parent, config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local width = config.Width or 100
    local height = config.Height or 16
    local cornerRadius = config.CornerRadius or 4

    local skeleton = p.Create("Frame", {
        Name = "Skeleton",
        Size = UDim2.new(0, width, 0, height),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = parent
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, cornerRadius), Parent = skeleton})

    -- Shimmer overlay
    local shimmer = p.Create("Frame", {
        Name = "Shimmer",
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(-0.4, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Parent = skeleton
    })
    p.Create("UICorner", {CornerRadius = UDim.new(0, cornerRadius), Parent = shimmer})

    -- Animate shimmer
    spawn(function()
        while skeleton and skeleton.Parent do
            p.Tween(shimmer, {Position = UDim2.new(1, 0, 0, 0)}, 1, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
            task.wait(1)
            shimmer.Position = UDim2.new(-0.4, 0, 0, 0)
        end
    end)

    return skeleton
end

--- Create an iOS-style spinner
function p.CreateSpinner(parent, config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local size = config.Size or 24
    local color = config.Color or theme.Accent

    local spinner = p.Create("ImageLabel", {
        Name = "Spinner",
        Size = UDim2.new(0, size, 0, size),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = color,
        ImageTransparency = 0,
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent
    })

    -- Rotate continuously
    spawn(function()
        while spinner and spinner.Parent do
            p.Tween(spinner, {Rotation = spinner.Rotation + 360}, 0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
            task.wait(0.8)
        end
    end)

    return spinner
end

--- Create an iOS-style badge count
function p.CreateCountBadge(parent, count, config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local maxCount = config.MaxCount or 99
    local displayCount = math.min(count, maxCount)
    local text = count > maxCount and tostring(maxCount) .. "+" or tostring(displayCount)

    local badgeSize = #text <= 1 and 18 or 22

    local badge = p.Create("Frame", {
        Name = "CountBadge",
        Size = UDim2.new(0, badgeSize, 0, badgeSize),
        BackgroundColor3 = theme.BadgeBackground,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = parent
    })
    p.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = badge})

    local badgeLabel = p.CreateLabel({
        Name = "Count",
        Size = UDim2.new(1, 0, 1, 0),
        Text = text,
        TextColor3 = theme.BadgeText,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = badge
    })

    return {
        Frame = badge,
        SetCount = function(newCount)
            displayCount = math.min(newCount, maxCount)
            badgeLabel.Text = newCount > maxCount and tostring(maxCount) .. "+" or tostring(displayCount)
        end
    }
end

--- Create an iOS-style separator with inset
function p.CreateInsetSeparator(parent, config)
    config = config or {}
    local theme = Theme.GetCurrent()
    local inset = config.Inset or 16

    local separator = p.Create("Frame", {
        Name = "InsetSeparator",
        Size = UDim2.new(1, 0, 0, 0.5),
        BackgroundColor3 = theme.Divider,
        BackgroundTransparency = config.Transparency or 0.3,
        BorderSizePixel = 0,
        Parent = parent
    })
    p.Create("UIPadding", {
        PaddingLeft = UDim.new(0, inset),
        PaddingRight = UDim.new(0, inset),
        Parent = separator
    })

    return separator
end

--- Create an iOS-style header/footer
function p.CreateiOSHeader(parent, config)
    config = config or {}
    local theme = Theme.GetCurrent()

    local header = p.Create("Frame", {
        Name = "iOSHeader",
        Size = UDim2.new(1, 0, 0, config.Height or 44),
        BackgroundColor3 = theme.CardBackground,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = parent
    })

    if config.Blur then
        p.Create("ImageLabel", {
            Name = "Blur",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://6015897843",
            ImageColor3 = theme.CardBackground,
            ImageTransparency = 0.3,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            Parent = header
        })
    end

    p.Create("UIStroke", {
        Color = theme.Divider,
        Transparency = 0.5,
        Thickness = 0.5,
        Parent = header
    })

    local title = p.CreateLabel({
        Name = "Title",
        Size = UDim2.new(1, 0, 1, 0),
        Text = config.Title or "",
        TextColor3 = theme.TextPrimary,
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = header
    })

    return {
        Frame = header,
        Title = title,
        SetTitle = function(text) title.Text = text end
    }
end

-- ============================================================
-- UTILITY: CLIPBOARD HELPER
-- ============================================================

function a.CopyToClipboard(text)
    local success = pcall(function()
        setclipboard(text)
    end)
    return success
end

-- ============================================================
-- UTILITY: RANDOM COLOR GENERATOR
-- ============================================================

function a.RandomColor()
    return Color3.fromRGB(
        math.random(50, 255),
        math.random(50, 255),
        math.random(50, 255)
    )
end

function a.RandomiOSColor()
    local colors = {
        a.Colors.SystemBlue, a.Colors.SystemGreen, a.Colors.SystemIndigo,
        a.Colors.SystemOrange, a.Colors.SystemPink, a.Colors.SystemPurple,
        a.Colors.SystemRed, a.Colors.SystemTeal, a.Colors.SystemYellow
    }
    return colors[math.random(1, #colors)]
end

-- ============================================================
-- UTILITY: TIMESTAMP FORMATTING
-- ============================================================

function a.FormatTimestamp(timestamp, format)
    format = format or "full"
    if format == "full" then
        return os.date("%Y-%m-%d %H:%M:%S", timestamp)
    elseif format == "date" then
        return os.date("%Y-%m-%d", timestamp)
    elseif format == "time" then
        return os.date("%H:%M:%S", timestamp)
    elseif format == "short" then
        return os.date("%m/%d %H:%M", timestamp)
    elseif format == "relative" then
        local diff = os.time() - (timestamp or os.time())
        if diff < 60 then return "just now"
        elseif diff < 3600 then return math.floor(diff / 60) .. "m ago"
        elseif diff < 86400 then return math.floor(diff / 3600) .. "h ago"
        else return math.floor(diff / 86400) .. "d ago"
        end
    end
    return tostring(timestamp)
end

-- ============================================================
-- UTILITY: NUMBER FORMATTING
-- ============================================================

function a.FormatNumber(num, format)
    format = format or "default"
    if format == "compact" then
        if num >= 1e9 then return string.format("%.1fB", num / 1e9)
        elseif num >= 1e6 then return string.format("%.1fM", num / 1e6)
        elseif num >= 1e3 then return string.format("%.1fK", num / 1e3)
        else return tostring(num) end
    elseif format == "comma" then
        local formatted = tostring(num)
        local k
        while true do
            formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then break end
        end
        return formatted
    elseif format == "percent" then
        return string.format("%.1f%%", num * 100)
    end
    return tostring(num)
end

-- ============================================================
-- UTILITY: TEXT HELPERS
-- ============================================================

function a.TruncateText(text, maxLength, suffix)
    maxLength = maxLength or 50
    suffix = suffix or "..."
    if #text <= maxLength then return text end
    return text:sub(1, maxLength - #suffix) .. suffix
end

function a.Capitalize(text)
    return text:sub(1, 1):upper() .. text:sub(2)
end

function a.TitleCase(text)
    return text:gsub("(%l)(%w*)", function(first, rest) return first:upper() .. rest end)
end

-- ============================================================
-- END OF iOS 26 UI LIBRARY
-- Version: 1.0.0
-- Elements: 25+ | Window Methods: 30+ | Theme Presets: 7
-- Easing Functions: 20+ | Utility Functions: 50+
-- ============================================================

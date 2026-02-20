-- 脚本类型：LocalScript
-- 放置位置：StarterPlayer > StarterPlayerScripts 或 StarterGui
-- 功能：电脑端Z键长按/松开 + 手机端右上角按钮点击切换治疗状态

-- 1. 引入核心服务
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- 2. 初始化核心变量
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = nil
local CooldownFolder = nil
local Humanoid = nil

-- 核心状态变量
local isHealing = false       -- 是否正在治疗（对应长按Z键状态）
local hasSentHealRequest = false -- 是否已发送治疗请求（避免重复发送）

-- 3. 等待角色加载（含复活重连）
local function waitForCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    CooldownFolder = Character:WaitForChild("CooldownFolder", 10)
    Humanoid = Character:WaitForChild("Humanoid", 10)

    -- 角色复活后重置状态和实例
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        Character = newChar
        CooldownFolder = newChar:WaitForChild("CooldownFolder", 10)
        Humanoid = newChar:WaitForChild("Humanoid", 10)
        isHealing = false
        hasSentHealRequest = false
        -- 同步手机按钮文本
        if healButton then
            healButton.Text = "治疗友方"
        end
    end)
end
waitForCharacter()

-- 4. 核心治疗逻辑（保留原函数所有校验）
local function startHealFriend()
    -- 安全校验
    if not Character or not CooldownFolder or not Humanoid then
        warn("治疗失败：角色核心实例未加载")
        return
    end
    if isHealing then return end -- 已在治疗中，不重复执行

    -- 原逻辑1：冷却检查
    if CooldownFolder:FindFirstChild("FriendHeal_Cooldown") and CooldownFolder.FriendHeal_Cooldown.Value == true then
        warn("治疗失败：技能冷却中")
        return
    end

    -- 原逻辑2：攻击状态检查
    if CooldownFolder:FindFirstChild("ActiveM1") and CooldownFolder.ActiveM1.Value == true then
        warn("治疗失败：正在普通攻击")
        return
    end

    -- 原逻辑3：自身存活检查
    if Humanoid.Health <= 0 then
        warn("治疗失败：自身已死亡")
        return
    end

    -- 发送开始治疗请求
    local healRemote = ReplicatedStorage:FindFirstChild("HealFriendTitanClockMan")
    if healRemote then
        healRemote:FireServer("start")
        hasSentHealRequest = true
        isHealing = true
        print("开始治疗友方")
    else
        warn("治疗失败：远程事件 HealFriendTitanClockMan 不存在")
    end
end

-- 5. 停止治疗逻辑
local function stopHealFriend()
    if not isHealing then return end -- 未在治疗中，不执行

    -- 发送停止治疗请求
    if hasSentHealRequest then
        local healRemote = ReplicatedStorage:FindFirstChild("HealFriendTitanClockMan")
        if healRemote then
            healRemote:FireServer("stop")
            print("停止治疗友方")
        end
        hasSentHealRequest = false
    end
    isHealing = false
end

-- 6. 电脑端Z键长按/松开逻辑（保留）
-- 6.1 按下Z键：开始治疗
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Z then
        startHealFriend()
    end
end)

-- 6.2 松开Z键：停止治疗
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Z then
        stopHealFriend()
    end
end)

-- 7. 手机端UI适配：右上角治疗按钮（核心新增）
local healButton = nil -- 按钮实例
local function createMobileHealButton()
    -- 创建屏幕GUI容器
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HealFriendMobileUI"
    screenGui.Parent = PlayerGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = false -- 适配手机刘海屏

    -- 创建按钮（大小80x80，足够大不遮挡，右上角留出边距）
    local button = Instance.new("TextButton")
    button.Name = "HealFriendButton"
    button.Parent = screenGui
    -- 位置：右上角（X: 屏幕右-90像素，Y: 顶部20像素）
    button.Position = UDim2.new(1, -90, 0, 20)
    -- 大小：80x80像素（手机上清晰可见，易点击）
    button.Size = UDim2.new(0, 80, 0, 80)
    -- 样式美化（避免太简陋，易识别）
    button.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- 绿色（治疗标识）
    button.BackgroundTransparency = 0.1
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 2
    button.CornerRadius = UDim.new(0, 10) -- 圆角，更美观
    -- 文本设置
    button.Text = "治疗友方"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true -- 文本自适应按钮大小
    button.TextSize = 14
    button.Font = Enum.Font.SourceSansBold

    -- 按钮点击逻辑：切换治疗状态（点一下开始，再点一下停止）
    button.MouseButton1Click:Connect(function()
        if not isHealing then
            -- 第一次点击：开始治疗
            startHealFriend()
            button.Text = "停止治疗"
            button.BackgroundColor3 = Color3.fromRGB(244, 67, 54) -- 红色（停止标识）
        else
            -- 第二次点击：停止治疗
            stopHealFriend()
            button.Text = "治疗友方"
            button.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- 恢复绿色
        end
    end)

    -- 适配手机横屏/竖屏切换（可选，增强适配性）
    RunService.RenderStepped:Connect(function()
        -- 防止按钮被手机虚拟按键遮挡
        local safeArea = GuiService:GetSafeAreaInsets()
        button.Position = UDim2.new(1, -90 - safeArea.Right, 0, 20 + safeArea.Top)
    end)

    healButton = button
    return button
end

-- 检测是否为移动设备，自动创建按钮
if UserInputService.TouchEnabled then
    createMobileHealButton()
    print("手机端UI已加载：右上角绿色按钮点击开始/停止治疗")
else
    print("电脑端模式：Z键长按开始治疗，松开停止")
end

-- 8. 服务端状态查询（复刻原代码逻辑）
local holdRemote = ReplicatedStorage:FindFirstChild("HoldHealFriend") 
if not holdRemote then
    holdRemote = Instance.new("RemoteFunction")
    holdRemote.Name = "HoldHealFriend"
    holdRemote.Parent = ReplicatedStorage
end
holdRemote.OnClientInvoke = function()
    return isHealing -- 服务端查询当前是否在治疗状态
end

-- 初始化提示
print("HealFriend脚本加载完成：")
if UserInputService.TouchEnabled then
    print("- 手机端：点击右上角按钮切换治疗/停止")
else
    print("- 电脑端：按住Z键治疗，松开停止")
end

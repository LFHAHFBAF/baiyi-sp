-- 【客户端LocalScript】必须放 StarterPlayer > StarterPlayerScripts
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local mouse = LocalPlayer:GetMouse()

-- 核心变量
local Character = nil
local HumanoidRootPart = nil
local CooldownFolder = nil
local Humanoid = nil
local isHealing = false       
local hasSentHealRequest = false
local healButton = nil -- 全局按钮引用，方便更新文本

-- ====================== 1. 角色加载（带调试） ======================
local function waitForCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
    CooldownFolder = Character:WaitForChild("CooldownFolder", 10)
    Humanoid = Character:WaitForChild("Humanoid", 10)

    -- 复活重置
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        Character = newChar
        HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart", 5)
        CooldownFolder = newChar:WaitForChild("CooldownFolder", 5)
        Humanoid = newChar:WaitForChild("Humanoid", 5)
        isHealing = false
        hasSentHealRequest = false
        if healButton then
            healButton.Text = "治疗"
            healButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        end
    end)
end
waitForCharacter()

-- ====================== 2. 核心：更新按钮文本（调试信息直接显示） ======================
-- 显示提示后，3秒自动恢复原文本
local function updateButtonText(text, isWarn)
    if not healButton then return end
    -- 记录当前按钮的原始文本（用于恢复）
    local originalText = isHealing and "停止" or "治疗"
    local originalColor = isHealing and Color3.fromRGB(244, 67, 54) or Color3.fromRGB(76, 175, 80)

    -- 设置提示文本和颜色（警告用红色，正常用白色）
    healButton.Text = text
    if isWarn then
        healButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- 警告红
    end

    -- 3秒后恢复原文本和颜色
    task.delay(3, function()
        if healButton and healButton.Parent then
            healButton.Text = originalText
            healButton.BackgroundColor3 = originalColor
        end
    end)
end

-- ====================== 3. 电脑端：鼠标选目标 ======================
local function getTargetFromMouse()
    if not mouse or not Character or not HumanoidRootPart then
        updateButtonText("鼠标/角色未加载", true)
        return nil
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local camera = Workspace.CurrentCamera
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * 1000
    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)

    if not rayResult then
        updateButtonText("未瞄准任何对象", true)
        return nil
    end

    local hitPart = rayResult.Instance
    local targetChar = hitPart:FindFirstAncestorOfClass("Model")
    if not targetChar then
        updateButtonText("非玩家角色", true)
        return nil
    end

    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    if not targetPlayer or targetPlayer == LocalPlayer then
        updateButtonText("无有效玩家", true)
        return nil
    end

    local targetHumanoid = targetChar:FindFirstChild("Humanoid")
    if not targetHumanoid or targetHumanoid.Health <= 0 then
        updateButtonText("目标已死亡", true)
        return nil
    end

    return targetPlayer
end

-- ====================== 4. 手机端：自动选最近玩家 ======================
local function findNearestPlayer()
    if not Character or not HumanoidRootPart then
        updateButtonText("角色未加载", true)
        return nil
    end

    local nearestPlayer = nil
    local shortestDistance = math.huge
    local myPosition = HumanoidRootPart.Position
    local playerCount = #Players:GetPlayers()

    if playerCount <= 1 then
        updateButtonText("无其他玩家", true)
        return nil
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if not targetChar then continue end
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            if not targetRoot then continue end
            local targetHumanoid = targetChar:FindFirstChild("Humanoid")
            if not targetHumanoid or targetHumanoid.Health <= 0 then continue end

            local distance = (myPosition - targetRoot.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = player
            end
        end
    end

    if not nearestPlayer then
        updateButtonText("无存活玩家", true)
        return nil
    end

    -- 成功找到，显示目标名称（正常提示）
    updateButtonText("目标："..nearestPlayer.Name, false)
    return nearestPlayer
end

-- ====================== 5. 核心治疗逻辑 ======================
local function startHealFriend()
    -- 基础校验
    if not Character or not CooldownFolder or not Humanoid then
        updateButtonText("核心实例缺失", true)
        return
    end
    if isHealing then 
        updateButtonText("已在治疗中", true)
        return 
    end

    -- 冷却检查
    local cooldownValue = CooldownFolder:FindFirstChild("FriendHeal_Cooldown")
    if cooldownValue and cooldownValue.Value == true then
        updateButtonText("技能冷却中", true)
        return
    end

    -- 攻击状态检查
    local activeM1 = CooldownFolder:FindFirstChild("ActiveM1")
    if activeM1 and activeM1.Value == true then
        updateButtonText("正在攻击中", true)
        return
    end

    -- 自身存活检查
    if Humanoid.Health <= 0 then
        updateButtonText("自身已死亡", true)
        return
    end

    -- 分设备选目标
    local targetPlayer = nil
    if UserInputService.TouchEnabled then
        targetPlayer = findNearestPlayer()
    else
        targetPlayer = getTargetFromMouse()
    end
    if not targetPlayer then return end

    -- 远程事件检查
    local healRemote = ReplicatedStorage:FindFirstChild("HealFriendTitanClockMan")
    if not healRemote then
        updateButtonText("远程事件缺失", true)
        return
    end

    -- 执行治疗
    healRemote:FireServer("start", targetPlayer)
    hasSentHealRequest = true
    isHealing = true
    healButton.Text = "停止"
    healButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    updateButtonText("治疗中："..targetPlayer.Name, false)
end

-- ====================== 6. 停止治疗逻辑 ======================
local function stopHealFriend()
    if not isHealing then 
        updateButtonText("未在治疗中", true)
        return 
    end

    local healRemote = ReplicatedStorage:FindFirstChild("HealFriendTitanClockMan")
    if healRemote and hasSentHealRequest then
        healRemote:FireServer("stop")
        updateButtonText("已停止治疗", false)
        hasSentHealRequest = false
    end
    isHealing = false
    healButton.Text = "治疗"
    healButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
end

-- ====================== 7. 电脑端Z键绑定 ======================
if not UserInputService.TouchEnabled then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Z then
            startHealFriend()
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Z then
            stopHealFriend()
        end
    end)
end

-- ====================== 8. 手机端按钮（核心：直接显示调试信息） ======================
local function createMobileHealButton()
    if not UserInputService.TouchEnabled then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HealFriendMobileUI"
    screenGui.Parent = PlayerGui
    screenGui.DisplayOrder = 999
    screenGui.IgnoreGuiInset = false

    -- 按钮：50x50像素 + 右上角顶部5像素（小且靠上）
    healButton = Instance.new("TextButton")
    healButton.Name = "HealFriendButton"
    healButton.Parent = screenGui
    healButton.Position = UDim2.new(1, -60, 0, 5) -- 上移到顶部5像素
    healButton.Size = UDim2.new(0, 50, 0, 50)     -- 50x50（小但易点击）
    -- 交互保障
    healButton.Active = true
    healButton.Selectable = true
    healButton.ZIndex = 100
    -- 初始样式
    healButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- 绿色
    healButton.BackgroundTransparency = 0.1
    healButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    healButton.BorderSizePixel = 2
    healButton.CornerRadius = UDim.new(0, 8) -- 圆角
    healButton.Text = "治疗"
    healButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    healButton.TextScaled = true -- 文本自适应按钮大小
    healButton.Font = Enum.Font.SourceSansBold

    -- 手机点击逻辑：直接触发治疗+按钮显示结果
    local function onButtonClick()
        if not isHealing then
            startHealFriend() -- 点击开始治疗，按钮显示调试信息
        else
            stopHealFriend()  -- 点击停止治疗，按钮显示结果
        end
    end
    -- 绑定触摸+点击事件（确保手机能触发）
    healButton.TouchTap:Connect(onButtonClick)
    healButton.MouseButton1Click:Connect(onButtonClick)

    -- 适配刘海屏/虚拟按键
    RunService.RenderStepped:Connect(function()
        local safeArea = GuiService:GetSafeAreaInsets()
        healButton.Position = UDim2.new(1, -60 - safeArea.Right, 0, 5 + safeArea.Top)
    end)
end
-- 创建手机按钮
createMobileHealButton()

-- ====================== 9. 服务端状态查询 ======================
local holdRemote = ReplicatedStorage:FindFirstChild("HoldHealFriend") 
if not holdRemote then
    holdRemote = Instance.new("RemoteFunction")
    holdRemote.Name = "HoldHealFriend"
    holdRemote.Parent = ReplicatedStorage
end
holdRemote.OnClientInvoke = function()
    return isHealing
end

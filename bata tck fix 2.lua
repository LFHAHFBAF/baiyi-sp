-- 脚本类型：LocalScript
-- 放置位置：StarterPlayer > StarterPlayerScripts
-- 核心：电脑=鼠标选目标 / 手机=自动选最近 + 手机按钮调小上移

-- 1. 引入核心服务
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

-- 2. 初始化核心变量
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local mouse = LocalPlayer:GetMouse() -- 电脑端鼠标对象（核心）

local Character = nil
local HumanoidRootPart = nil
local CooldownFolder = nil
local Humanoid = nil

-- 核心状态变量
local isHealing = false       
local hasSentHealRequest = false

-- 3. 角色加载（确保核心部件就绪）
local function waitForCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
    CooldownFolder = Character:WaitForChild("CooldownFolder", 10)
    Humanoid = Character:WaitForChild("Humanoid", 10)

    -- 角色复活重置
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

-- 4. 【电脑端】鼠标选目标：射线检测鼠标指向的玩家
local function getTargetFromMouse()
    -- 安全校验：鼠标/自身角色未就绪
    if not mouse or not Character or not HumanoidRootPart then
        warn("[电脑端] 鼠标/角色未加载，无法选目标")
        return nil
    end

    -- 发射射线（从相机到鼠标指向位置）
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {Character} -- 排除自己
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local camera = Workspace.CurrentCamera
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * 1000 -- 射线长度1000 studs

    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
    if not rayResult then return nil end

    -- 从射线击中的部件找所属玩家
    local hitPart = rayResult.Instance
    local targetChar = hitPart:FindFirstAncestorOfClass("Model")
    if not targetChar then return nil end

    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    -- 验证目标玩家：存在、存活、不是自己
    if targetPlayer and targetPlayer ~= LocalPlayer then
        local targetHumanoid = targetChar:FindFirstChild("Humanoid")
        if targetHumanoid and targetHumanoid.Health > 0 then
            return targetPlayer
        end
    end

    return nil -- 未找到有效目标
end

-- 5. 【手机端】自动选最近的玩家
local function findNearestPlayer()
    if not Character or not HumanoidRootPart then
        warn("[手机端] 角色/根部件未加载，无法选最近玩家")
        return nil
    end

    local nearestPlayer = nil
    local shortestDistance = math.huge
    local myPosition = HumanoidRootPart.Position

    -- 遍历所有玩家找最近存活的
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                if targetHumanoid and targetHumanoid.Health > 0 then
                    local distance = (myPosition - targetChar.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
    end

    return nearestPlayer
end

-- 6. 核心治疗逻辑（分设备选目标）
local function startHealFriend()
    -- 基础校验（通用）
    if not Character or not CooldownFolder or not Humanoid then
        warn("[治疗失败] 角色核心实例未加载")
        return
    end
    if isHealing then 
        print("[治疗提示] 已在治疗中，无需重复触发")
        return 
    end

    -- 通用校验：冷却/攻击/存活
    if CooldownFolder:FindFirstChild("FriendHeal_Cooldown") and CooldownFolder.FriendHeal_Cooldown.Value == true then
        warn("[治疗失败] 技能冷却中")
        return
    end
    if CooldownFolder:FindFirstChild("ActiveM1") and CooldownFolder.ActiveM1.Value == true then
        warn("[治疗失败] 正在普通攻击")
        return
    end
    if Humanoid.Health <= 0 then
        warn("[治疗失败] 自身已死亡")
        return
    end

    -- 分设备获取目标
    local targetPlayer = nil
    if UserInputService.TouchEnabled then
        -- 手机端：自动选最近
        targetPlayer = findNearestPlayer()
        if not targetPlayer then
            warn("[手机端] 未找到可治疗的最近玩家（无其他存活玩家）")
            return
        end
    else
        -- 电脑端：鼠标选目标
        targetPlayer = getTargetFromMouse()
        if not targetPlayer then
            warn("[电脑端] 鼠标未指向有效玩家，请瞄准其他存活玩家")
            return
        end
    end

    -- 发送治疗请求（带目标玩家）
    local healRemote = ReplicatedStorage:FindFirstChild("HealFriendTitanClockMan")
    if healRemote then
        healRemote:FireServer("start", targetPlayer)
        hasSentHealRequest = true
        isHealing = true
        -- 不同设备的提示
        if UserInputService.TouchEnabled then
            print(string.format("[手机端] 开始治疗最近玩家：%s", targetPlayer.Name))
        else
            print(string.format("[电脑端] 开始治疗鼠标指向的玩家：%s", targetPlayer.Name))
        end
    else
        warn("[治疗失败] 远程事件 HealFriendTitanClockMan 不存在")
    end
end

-- 7. 停止治疗逻辑（通用）
local function stopHealFriend()
    if not isHealing then 
        print("[治疗提示] 未在治疗中，无需停止")
        return 
    end

    if hasSentHealRequest then
        local healRemote = ReplicatedStorage:FindFirstChild("HealFriendTitanClockMan")
        if healRemote then
            healRemote:FireServer("stop")
            print("[治疗成功] 停止治疗")
        end
        hasSentHealRequest = false
    end
    isHealing = false
end

-- 8. 电脑端：Z键长按+鼠标选目标触发
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService.TouchEnabled then return end -- 手机端不触发此逻辑
    -- 按下Z键触发治疗（鼠标已选目标）
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Z then
        startHealFriend()
    end
end)
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or UserInputService.TouchEnabled then return end
    -- 松开Z键停止治疗
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Z then
        stopHealFriend()
    end
end)

-- 9. 手机端UI：50x50 + 顶部5像素 + 点击切换
local healButton = nil
local function createMobileHealButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HealFriendMobileUI"
    screenGui.Parent = PlayerGui
    screenGui.DisplayOrder = 999 -- 防遮挡
    screenGui.IgnoreGuiInset = false

    -- 按钮：50x50像素 + 右上角顶部5像素
    local button = Instance.new("TextButton")
    button.Name = "HealFriendButton"
    button.Parent = screenGui
    button.Position = UDim2.new(1, -60, 0, 5) -- 上移到顶部5像素
    button.Size = UDim2.new(0, 50, 0, 50)     -- 调小到50x50
    -- 交互保障
    button.Active = true
    button.Selectable = true
    button.ZIndex = 100
    -- 样式
    button.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    button.BackgroundTransparency = 0.1
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 2
    button.CornerRadius = UDim.new(0, 8)
    button.Text = "治疗"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold

    -- 手机点击切换治疗状态
    local function onButtonClick()
        if not isHealing then
            startHealFriend() -- 自动选最近玩家
            button.Text = "停止"
            button.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
        else
            stopHealFriend()
            button.Text = "治疗"
            button.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        end
    end
    button.TouchTap:Connect(onButtonClick) -- 手机原生触摸
    button.MouseButton1Click:Connect(onButtonClick) -- 兼容

    -- 适配刘海屏
    RunService.RenderStepped:Connect(function()
        local safeArea = GuiService:GetSafeAreaInsets()
        button.Position = UDim2.new(1, -60 - safeArea.Right, 0, 5 + safeArea.Top)
    end)

    healButton = button
    print("[手机端] 治疗按钮已创建（50x50，顶部5像素）")
    return button
end

-- 仅手机端创建按钮
if UserInputService.TouchEnabled then
    createMobileHealButton()
end

-- 10. 服务端状态查询（通用）
local holdRemote = ReplicatedStorage:FindFirstChild("HoldHealFriend") 
if not holdRemote then
    holdRemote = Instance.new("RemoteFunction")
    holdRemote.Name = "HoldHealFriend"
    holdRemote.Parent = ReplicatedStorage
end
holdRemote.OnClientInvoke = function()
    return isHealing
end

-- 初始化提示
if UserInputService.TouchEnabled then
    print("=== HealFriend脚本加载完成 ===")
    print("- 手机端：点击右上角按钮→自动治疗最近玩家")
    print("- 按钮尺寸：50x50 | 位置：顶部5像素")
else
    print("=== HealFriend脚本加载完成 ===")
    print("- 电脑端：按住Z键→治疗鼠标指向的玩家，松开停止")
end

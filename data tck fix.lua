-- 专属自我治疗（长按X触发）- 最终修复版（手机长按持续治疗）
-- 放置位置：StarterPlayerScripts 或 StarterCharacterScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 核心变量
local Character = nil
local CooldownFolder = nil
local Humanoid = nil
local mouse = LocalPlayer:GetMouse()
local isSelfHealing = false
local healLoop = nil

-- 服务器状态同步（必须保留）
game.ReplicatedStorage.HoldSkill3.OnClientInvoke = function()
    return isSelfHealing
end

-- ===================== 手机触摸适配核心修改 =====================
local mobileGui = nil
local healButton = nil

local function setupMobileButton()
    task.wait(0.5) -- 等待手机UI加载完成
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    -- 创建/获取移动端UI容器
    local mobileSupport = playerGui:FindFirstChild("MobileSupport") or Instance.new("ScreenGui")
    mobileSupport.Name = "MobileSupport"
    mobileSupport.Parent = playerGui

    local mainFrame = mobileSupport:FindFirstChild("Main") or Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 200, 0, 200)
    mainFrame.Position = UDim2.new(1, -220, 1, -220) -- 右下角
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = mobileSupport

    -- 创建治疗按钮
    if healButton then healButton:Destroy() end
    healButton = Instance.new("TextButton")
    healButton.Name = "HealButton"
    healButton.Size = UDim2.new(0, 80, 0, 80)
    healButton.Position = UDim2.new(0, 0, 0, 0)
    healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    healButton.Text = "治疗"
    healButton.TextColor3 = Color3.new(1,1,1)
    healButton.Font = Enum.Font.SourceSansBold
    healButton.TextSize = 20
    healButton.AutoButtonColor = false -- 关闭自动变色，避免干扰

    -- 圆角按钮
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 40)
    corner.Parent = healButton
    healButton.Parent = mainFrame

    -- ============= 手机专属触摸事件（核心修复） =============
    -- 触摸开始（按下按钮）→ 开始持续治疗
    healButton.TouchStarted:Connect(function(touchInput)
        touchInput.Position = touchInput.Position -- 防止触摸事件被吞
        startSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200) -- 按下变深
    end)

    -- 触摸结束（松开按钮）→ 停止治疗
    healButton.TouchEnded:Connect(function()
        stopSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- 恢复原色
    end)

    -- 触摸取消（手指移开按钮）→ 停止治疗（兜底）
    healButton.TouchCanceled:Connect(function()
        stopSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    end)

    print("手机治疗按钮加载完成，长按持续治疗")
end

-- ===================== 角色初始化 =====================
local function setupCharacter()
    -- 等待角色加载
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    CooldownFolder = Character:WaitForChild("CooldownFolder", 10)
    Humanoid = Character:WaitForChild("Humanoid", 10)

    -- 角色死亡：停止治疗+销毁脚本/按钮
    Humanoid.Died:Connect(function()
        isSelfHealing = false
        if healLoop then task.cancel(healLoop) end
        if healButton then healButton:Destroy() end
        script:Destroy()
        print("角色死亡，治疗脚本已销毁")
    end)

    -- 角色销毁：重新初始化
    Character.Destroying:Connect(function()
        isSelfHealing = false
        setupCharacter()
    end)

    -- 手机端创建按钮
    if UserInputService.TouchEnabled then
        setupMobileButton()
    end
end

-- ===================== 持续治疗逻辑（核心） =====================
function startSelfHeal()
    -- 防重复触发
    if isSelfHealing then return end

    -- 基础校验（冷却/攻击/角色存活）
    local isCooldown = CooldownFolder and CooldownFolder:FindFirstChild("SelfHeal_Cooldown") and CooldownFolder.SelfHeal_Cooldown.Value
    local isAttacking = CooldownFolder and CooldownFolder:FindFirstChild("ActiveM1") and CooldownFolder.ActiveM1.Value
    local isDead = not Character or not Humanoid or Humanoid.Health <= 0

    if isCooldown or isAttacking or isDead then
        return
    end

    -- 标记治疗中，开始循环发送请求
    isSelfHealing = true
    print("开始持续治疗")

    -- 循环发送治疗请求（每0.1秒1次，手机/电脑通用）
    healLoop = task.spawn(function()
        while isSelfHealing and Humanoid.Health > 0 do
            local healEvent = ReplicatedStorage:FindFirstChild("SelfHealTitanClockMan")
            if healEvent then
                healEvent:FireServer(mouse.Hit.Position)
            end
            task.wait(0.1) -- 治疗频率，可微调（0.1-0.2秒最佳）
        end
    end)
end

-- ===================== 停止治疗逻辑 =====================
function stopSelfHeal()
    if not isSelfHealing then return end

    -- 终止循环+重置状态
    isSelfHealing = false
    if healLoop then
        task.cancel(healLoop)
        healLoop = nil
    end
    print("停止持续治疗")
end

-- ===================== 电脑端X键绑定 =====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.X then
        startSelfHeal()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.X then
        stopSelfHeal()
    end
end)

-- 初始化脚本
setupCharacter()
print("自我治疗脚本加载完成（电脑X键/手机长按按钮均支持持续治疗）")

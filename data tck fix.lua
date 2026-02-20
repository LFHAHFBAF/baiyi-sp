-- 专属自我治疗（长按X触发）- 最终完整版（无按键冲突+手机长按持续）
-- 放置位置：StarterPlayerScripts 或 StarterCharacterScripts

-- 1. 获取核心服务
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- 2. 核心变量定义（全局可访问）
local Character = nil
local CooldownFolder = nil
local Humanoid = nil
local mouse = LocalPlayer:GetMouse()
local isSelfHealing = false  -- 标记是否正在治疗
local healLoop = nil         -- 治疗循环引用
local healButton = nil       -- 手机治疗按钮引用

-- 3. 服务器状态同步（必须保留，服务器通过这个获取治疗状态）
game.ReplicatedStorage.HoldSkill3.OnClientInvoke = function()
    return isSelfHealing
end

-- 4. 手机按钮创建函数（复用原有容器，不冲突）
local function setupMobileButton()
    task.wait(0.5) -- 等待原有MobileSupport加载完成
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    -- 复用原有脚本的MobileSupport容器（不新建，避免顶走按键）
    local mobileSupport = playerGui:FindFirstChild("MobileSupport")
    if not mobileSupport then return end
    local mainFrame = mobileSupport:FindFirstChild("Main")
    if not mainFrame then return end

    -- 销毁旧按钮（防止重复创建）
    if healButton then healButton:Destroy() end

    -- 创建治疗按钮（放在原有按键空白处，90,90是F键旁空白，不重叠）
    healButton = Instance.new("TextButton")
    healButton.Name = "XButton" -- 和原有按键命名统一（E/R/T/F/Y/G/Q/LMB）
    healButton.Size = UDim2.new(0, 80, 0, 80)  -- 和原有按键尺寸一致
    healButton.Position = UDim2.new(0, 90, 0, 90) -- 关键：空白位置，不顶走其他按键
    healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- 蓝色（和原有按键区分）
    healButton.Text = "治疗"
    healButton.TextColor3 = Color3.new(1, 1, 1)
    healButton.Font = Enum.Font.SourceSansBold
    healButton.TextSize = 20
    healButton.AutoButtonColor = false -- 关闭自动变色，避免触摸异常

    -- 圆角按钮（和原有按键样式统一）
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 40)
    corner.Parent = healButton
    healButton.Parent = mainFrame -- 挂到原有Main容器，不新建

    -- 手机专属触摸事件（长按持续响应）
    healButton.TouchStarted:Connect(function(touchInput)
        touchInput.Position = touchInput.Position -- 防止触摸事件被吞
        startSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200) -- 按下变深
    end)

    healButton.TouchEnded:Connect(function()
        stopSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- 松开恢复
    end)

    healButton.TouchCanceled:Connect(function()
        stopSelfHeal()
        healButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- 移开恢复
    end)

    print("手机治疗按钮创建完成（位置：90,90，不影响原有按键）")
end

-- 5. 角色初始化函数（加载角色+监听死亡）
local function setupCharacter()
    -- 等待角色加载完成
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    -- 等待冷却文件夹（原有脚本的核心容器）
    CooldownFolder = Character:WaitForChild("CooldownFolder", 10)
    -- 等待人形对象
    Humanoid = Character:WaitForChild("Humanoid", 10)

    -- 角色死亡：停止治疗+销毁脚本/按钮（彻底清理）
    Humanoid.Died:Connect(function()
        isSelfHealing = false
        if healLoop then task.cancel(healLoop) end -- 终止治疗循环
        if healButton then healButton:Destroy() end -- 销毁手机按钮
        script:Destroy() -- 销毁脚本
        print("角色死亡，自我治疗脚本已销毁")
    end)

    -- 人形对象销毁：重置治疗状态
    Humanoid.Destroying:Connect(function()
        isSelfHealing = false
    end)

    -- 角色销毁：重新初始化（重生后可用）
    Character.Destroying:Connect(function()
        isSelfHealing = false
        setupCharacter()
    end)

    -- 仅手机端创建按钮（PC端不创建）
    if UserInputService.TouchEnabled then
        setupMobileButton()
    end
end

-- 6. 开始治疗逻辑（长按持续发送请求）
function startSelfHeal()
    -- 防重复触发
    if isSelfHealing then return end

    -- 核心校验（和原有脚本逻辑一致）
    -- 校验1：冷却中
    local isOnCooldown = CooldownFolder and CooldownFolder:FindFirstChild("SelfHeal_Cooldown") and CooldownFolder.SelfHeal_Cooldown.Value
    -- 校验2：正在普通攻击（M1）
    local isAttacking = CooldownFolder and CooldownFolder:FindFirstChild("ActiveM1") and CooldownFolder.ActiveM1.Value
    -- 校验3：角色死亡/无效
    local isCharacterInvalid = not Character or not Humanoid or Humanoid.Health <= 0

    if isOnCooldown or isAttacking or isCharacterInvalid then
        return
    end

    -- 标记治疗中，开始循环发送请求
    isSelfHealing = true
    print("开始持续自我治疗")

    -- 循环发送治疗请求（每0.1秒1次，频率适中）
    healLoop = task.spawn(function()
        while isSelfHealing and Humanoid.Health > 0 do
            local healEvent = ReplicatedStorage:FindFirstChild("SelfHealTitanClockMan")
            if healEvent then
                healEvent:FireServer(mouse.Hit.Position)
            end
            task.wait(0.1) -- 治疗频率，可微调（0.08-0.2秒最佳）
        end
    end)
end

-- 7. 停止治疗逻辑（松开按键/按钮时执行）
function stopSelfHeal()
    if not isSelfHealing then return end

    -- 终止治疗循环
    isSelfHealing = false
    if healLoop then
        task.cancel(healLoop)
        healLoop = nil
    end
    print("停止持续自我治疗")
end

-- 8. 电脑端X键绑定（长按/松开）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end -- 过滤聊天/UI输入
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

-- 9. 初始化脚本（首次执行）
setupCharacter()
print("自我治疗脚本加载完成！")
print("PC端：长按X键持续治疗 | 手机端：长按右下角治疗按钮持续治疗")

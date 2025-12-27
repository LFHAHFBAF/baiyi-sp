local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local localEvacuate = false
local localIsActivated = false
local upwardForce
local downwardForce
local horizontalLock
local isApplyingUpward = false
local hasStarted = false

local function clearAllConstraints()
    if upwardForce then
        upwardForce:Destroy()
        upwardForce = nil
    end
    if downwardForce then
        downwardForce:Destroy()
        downwardForce = nil
    end
    if horizontalLock then
        horizontalLock:Destroy()
        horizontalLock = nil
    end
    isApplyingUpward = false
end

local function startCoreFunction()
    if hasStarted then return end
    hasStarted = true
    localEvacuate = false
    localIsActivated = true

    local char = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid", 10)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)

    if not (humanoid and hrp and hrp.Parent) then
        warn("无法获取角色关键部件，核心功能无法执行")
        return
    end
    humanoid.PlatformStand = false

    clearAllConstraints()
    isApplyingUpward = true
    horizontalLock = Instance.new("BodyPosition")
    horizontalLock.Name = "HorizontalPositionLock"
    horizontalLock.Parent = hrp
    horizontalLock.Position = hrp.Position
    horizontalLock.MaxForce = Vector3.new(1e9, 0, 1e9)
    horizontalLock.D = 500
    horizontalLock.P = 1e6

    upwardForce = Instance.new("BodyForce")
    upwardForce.Name = "UpwardContinuousForce"
    upwardForce.Parent = hrp
    upwardForce.Force = Vector3.new(0, 10000, 0)

    task.spawn(function()
        while task.wait(0.25) do
            local jeffrey = workspace:FindFirstChild("Jeffrey")
            if jeffrey then jeffrey:Destroy() end
        end
    end)

    task.spawn(function()
        while task.wait(0.1) do
            if not (hrp and hrp.Parent and humanoid) then
                clearAllConstraints()
                break
            end

            local waveVal = workspace:FindFirstChild("Wave")
            local timerVal = workspace:FindFirstChild("TimerWave")

            if waveVal and timerVal then
                local wave = waveVal.Value
                local timer = timerVal.Value

                if wave == 4 and not localEvacuate and timer == 5 then
                    localEvacuate = true
                end

                if wave == 4 and localEvacuate and timer < 5 then
                    if isApplyingUpward then
                        upwardForce:Destroy()
                        upwardForce = nil
                        downwardForce = Instance.new("BodyForce")
                        downwardForce.Name = "DownwardContinuousForce"
                        downwardForce.Parent = hrp
                        downwardForce.Force = Vector3.new(0, -10000, 0)
                        isApplyingUpward = false
                    end
                end
            end
        end
    end)
end

startCoreFunction()

Player.CharacterRemoving:Connect(clearAllConstraints)

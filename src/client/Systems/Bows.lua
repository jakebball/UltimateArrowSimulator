local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ModelUtils = require(ReplicatedStorage.Shared.Utils.ModelUtils)

local Bows = {}

local Players = game.Players

local HOVER_SPEED = 1
local HOVER_AMPLITUDE = 0.5

local fireDebounce = false

local mouse = Players.LocalPlayer:GetMouse()

function Bows.UpdateBows(player)

    if player.Character == nil then
        return
    end 

    if player.Character:FindFirstChild("HumanoidRootPart") == nil then
        return
    end
    
    local equippedItems = HttpService:JSONDecode(player:GetAttribute("equippedItems"))

    local playerBow = equippedItems.playerBowSlot

    if playerBow == nil then
        for _,child in workspace.Bows[player.UserId]:GetChildren() do
            child:Destroy()
        end

        return
    end

    local bowModel = workspace.Bows[player.UserId]:FindFirstChild(playerBow)
    local movementPart = workspace.Bows[player.UserId]:FindFirstChild("MovementRoot-" .. playerBow)

    local currentTime = os.clock()

    local yOffset = math.sin(currentTime * HOVER_SPEED) * HOVER_AMPLITUDE

    local targetCFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(3.5, yOffset, 0) * CFrame.new(0, 1, 0)

    targetCFrame = CFrame.new(targetCFrame.Position, mouse.Hit.Position) * CFrame.Angles(0, math.rad(90), 0)

    if bowModel == nil then
        bowModel = ReplicatedStorage.Assets.Bows:FindFirstChild(playerBow):Clone()
        bowModel.Name = playerBow
        bowModel:PivotTo(targetCFrame)
        bowModel.Parent = workspace.Bows[player.UserId]

        movementPart = Instance.new("Part")
        movementPart.Name = "MovementRoot-" .. playerBow
        movementPart.Transparency = 1
        movementPart.CanCollide = false
        movementPart.CFrame = targetCFrame
        movementPart.Parent = workspace.Bows[player.UserId]

        local attachment = Instance.new("Attachment")
        attachment.Parent = movementPart    

        local alignPosition = Instance.new("AlignPosition")
        alignPosition.MaxForce = math.huge
        alignPosition.Responsiveness = 45
        alignPosition.MaxVelocity = math.huge
        alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPosition.Attachment0 = attachment
        alignPosition.Parent = movementPart

        local alignOrientation = Instance.new("AlignOrientation")
        alignOrientation.RigidityEnabled = true
        alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignOrientation.Attachment0 = attachment
        alignOrientation.Parent = movementPart

        local arrow = ReplicatedStorage.Assets.Arrows[playerBow]:Clone()
        arrow.Name = "Arrow"
        arrow.WorldPivot = arrow.Notch.CFrame
        arrow.Parent = bowModel

        local weld = Instance.new("Weld")   
        weld.Part0 = bowModel.MiddleNock
        weld.Part1 = bowModel.LowerNock
        weld.C0 = CFrame.new(0, -1.43, 0)
        weld.Parent = bowModel.MiddleNock
    end

    movementPart.AlignPosition.Position = targetCFrame.Position
    movementPart.AlignOrientation.CFrame = targetCFrame

    bowModel.Arrow:PivotTo(bowModel.MiddleNock.CFrame)
    bowModel:PivotTo(movementPart.CFrame)
    
    for _,child in workspace.Bows[player.UserId]:GetChildren() do
        if equippedItems.playerBowSlot ~= child.Name and string.find(child.Name, "MovementRoot") == nil then
            child:Destroy()
        end
    end
end

function Bows.FireBow(player)
    for _,bowId in HttpService:JSONDecode(player:GetAttribute("equippedItems")) do
        local bowModel = workspace.Bows[player.UserId]:FindFirstChild(bowId)

        if bowModel and bowModel:FindFirstChild("MiddleNock") then
            local tween = TweenService:Create(
                bowModel.MiddleNock.Weld, 
                TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), 
                { C0 = CFrame.new(0, -1.43, 1) }
            )
            tween:Play()
            tween.Completed:Wait()

            task.wait()
            
            local fireTween = TweenService:Create(
                bowModel.MiddleNock.Weld,
                TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
                { C0 = CFrame.new(0, -1.43, 0) }
            )
            fireTween:Play()

            local arrow = bowModel.Arrow:Clone()
            arrow.Parent = workspace

            local v = mouse.Hit.Position - arrow:GetPivot().Position
            local t = v.Magnitude / 140
            local targetCFrame = CFrame.lookAlong(mouse.Hit.Position - mouse.Hit.LookVector, -v)

            local fireTweenArrow = TweenService:Create(
                arrow.Notch,
                TweenInfo.new(t, Enum.EasingStyle.Linear),
                { CFrame = targetCFrame }
            )
            fireTweenArrow:Play()

            ModelUtils.toggleVisiblity(bowModel.Arrow, false)

            task.wait(1)

            ModelUtils.toggleVisiblity(bowModel.Arrow, true)
        end
    end
end

function Bows.Start()
    RunService.Heartbeat:Connect(function()
        for _,player in Players:GetPlayers() do

            if player:GetAttribute("equippedItems") == nil or player:GetAttribute("bows") == nil then
                continue
            end

            if workspace.Bows:FindFirstChild(player.UserId) == nil then
                local bowFolder = Instance.new("Folder")
                bowFolder.Name = player.UserId
                bowFolder.Parent = workspace.Bows
            end
            
            Bows.UpdateBows(player)
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent then
            if input.UserInputType == Enum.UserInputType.MouseButton1 and fireDebounce == false then
                fireDebounce = true

                Bows.FireBow(Players.LocalPlayer)

                task.wait(0.25)

                fireDebounce = false
            end
        end
    end)
end

return Bows
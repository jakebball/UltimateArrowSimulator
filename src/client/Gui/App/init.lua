local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)

local MusicPlayer = require(script.MusicPlayer)
local HUD = require(script.HUD)
local Backpack = require(script.Backpack)
local ShootingRange = require(script.ShootingRange)
local SimulationMatrix = require(script.SimulationMatrix)

local CameraUtils = require(ReplicatedStorage.Shared.Utils.CameraUtils)

local SAVE_TEMPLATE = require(script.Parent.Parent.SaveTemplate)

local e = React.createElement

local menuStates = {
	["gameplay"] = {
		"musicPlayer",
		"hud",
	},
	["backpack"] = {
		"musicPlayer",
		"backpack",
	},
	["shootingRange"] = {
		"musicPlayer",
		"shootingRange",
	},
	["simulationMatrix"] = {
		"musicPlayer",
		"simulationMatrix",
	},
}

local blurredMenus = {
	"backpack",
	"simulationMatrix",
}

local tableAttributes = {
	"bows",
	"equippedItems",
	"simulationTokens",
	"unlockedRanges",
}

local function App(props)
	local menuState, setMenuState = React.useState("gameplay")
	local playerdata, setPlayerdata = React.useState(SAVE_TEMPLATE)

	React.useEffect(function()
		local connections = {}

		table.insert(
			connections,
			ReplicatedStorage.Bindables.SetGuiState.Event:Connect(function(newGuiState)
				setMenuState(newGuiState)
			end)
		)

		for key, _defaultValue in SAVE_TEMPLATE do
			table.insert(
				connections,
				Players.LocalPlayer:GetAttributeChangedSignal(key):Connect(function()
					setPlayerdata(function(oldPlayerdata)
						oldPlayerdata = table.clone(oldPlayerdata)

						local newValue = Players.LocalPlayer:GetAttribute(key)

						if table.find(tableAttributes, key) ~= nil then
							newValue = HttpService:JSONDecode(newValue)
						end

						oldPlayerdata[key] = newValue

						return oldPlayerdata
					end)
				end)
			)
		end

		return function()
			for _, v in connections do
				v:Disconnect()
			end
		end
	end, {})

	React.useEffect(function()
		if menuState ~= "shootingRange" then
			CameraUtils.SetBlur(table.find(blurredMenus, menuState) ~= nil, 16)
		end
	end, { menuState })

	return e(React.Fragment, {}, {
		MusicPlayer = e(MusicPlayer, {
			visible = table.find(menuStates[menuState], "musicPlayer"),
		}),

		HUD = e(HUD, {
			visible = table.find(menuStates[menuState], "hud"),
			playerdata = playerdata,
			setMenuState = setMenuState,
			menuState = menuState,
		}),

		Backpack = e(Backpack, {
			visible = table.find(menuStates[menuState], "backpack"),
			playerdata = playerdata,
			systems = props.systems,
		}),

		ShootingRange = e(ShootingRange, {
			visible = table.find(menuStates[menuState], "shootingRange"),
			playerdata = playerdata,
			systems = props.systems,
			setMenuState = setMenuState,
		}),

		SimulationMatrix = e(SimulationMatrix, {
			visible = table.find(menuStates[menuState], "simulationMatrix"),
			playerdata = playerdata,
			systems = props.systems,
			setMenuState = setMenuState,
		}),
	})
end

return App

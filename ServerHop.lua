local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local GAME_ID = 7449423635 -- Blox Fruits main game ID
local API_URL = "https://games.roblox.com/v1/games/" .. GAME_ID .. "/servers/Public?sortOrder=Desc&limit=100"
local hopActive = false
local timeRemaining = 10

-- Validate that this script is only running in Blox Fruits
if game.PlaceId ~= GAME_ID then
	error("This server hopper is exclusive to Blox Fruits (Game ID: " .. GAME_ID .. "). Current game ID: " .. game.PlaceId)
end

local function getServers()
	local url = "https://games.roblox.com/v1/games/" .. GAME_ID .. "/servers/Public?sortOrder=Desc&limit=100"
	
	local success, result = pcall(function()
		local response = game:HttpGet(url, true)
		return response
	end)
	
	if not success then
		warn("HttpGet failed: " .. tostring(result))
		-- Try alternative method
		return getServersAlternative()
	end
	
	local success2, decoded = pcall(function()
		return game:GetService("HttpService"):JSONDecode(result)
	end)
	
	if not success2 then
		warn("JSON decode failed")
		return {}
	end
	
	return decoded.data or {}
end

local function getServersAlternative()
	-- Fallback: just teleport to random job ID
	warn("Using alternative hopping method")
	return {
		{id = "00000000-0000-0000-0000-000000000001", playing = 1, maxPlayers = 10}
	}
end

-- Create GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Text = "Server Hop"
title.BorderSizePixel = 0
title.Parent = mainFrame

-- Timer Label
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0, 40)
timerLabel.Position = UDim2.new(0, 0, 0, 35)
timerLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
timerLabel.TextSize = 14
timerLabel.Text = "Ready"
timerLabel.BorderSizePixel = 0
timerLabel.Parent = mainFrame

-- Start Button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(1, -10, 0, 35)
startButton.Position = UDim2.new(0, 5, 0, 110)
startButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextSize = 14
startButton.Text = "Start Hop"
startButton.BorderSizePixel = 0
startButton.Parent = mainFrame

-- Stop Button
local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0, 0, 0, 35)
stopButton.Position = UDim2.new(0, 5, 0, 110)
stopButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextSize = 14
stopButton.Text = "Stop"
stopButton.BorderSizePixel = 0
stopButton.Visible = false
stopButton.Parent = mainFrame

-- Server hopping function (defined after GUI creation so timerLabel exists)
local function hopServer()
	print("Attempting to server hop...")
	
	-- Generate random JobID - sometimes this works without API
	local jobId = game:GetService("HttpService"):GenerateGUID(false)
	
	print("Generated JobID: " .. jobId)
	mainFrame:FindFirstChild("TimerLabel").Text = "Hopping..."
	
	local success = pcall(function()
		TeleportService:TeleportToPlaceInstance(GAME_ID, jobId, Players.LocalPlayer)
	end)
	
	if not success then
		warn("Teleport failed")
		mainFrame:FindFirstChild("TimerLabel").Text = "Teleport failed"
	else
		print("Teleport initiated")
	end
end

-- Start button clicked
startButton.MouseButton1Click:Connect(function()
	hopActive = true
	timeRemaining = 10
	startButton.Visible = false
	stopButton.Visible = true
	
	for i = 10, 0, -1 do
		if not hopActive then break end
		timeRemaining = i
		local minutes = math.floor(i / 60)
		local seconds = i % 60
		timerLabel.Text = string.format("Hopping in: %d:%02d", minutes, seconds)
		wait(1)
	end
	
	if hopActive then
		hopServer()
		hopActive = false
		startButton.Visible = true
		stopButton.Visible = false
		timerLabel.Text = "Ready"
	end
end)

-- Stop button clicked
stopButton.MouseButton1Click:Connect(function()
	hopActive = false
	startButton.Visible = true
	stopButton.Visible = false
	timerLabel.Text = "Cancelled"
	wait(1)
	timerLabel.Text = "Ready"
end)
-- Replace OWNER and REPOSITORY with your GitHub account and repository.
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/OWNER/REPOSITORY/main/ZiiqBase.lua"))()
local window = UI:CreateWindow({Title="My Hub", Subtitle="My project", Tabs={{Id="main",Title="General",Section="Workspace"}}})
local tab = window:GetTab("main")
tab:AddSection("Controls")
tab:AddToggle({Title="Enabled", Callback=function(value) print(value) end})
tab:AddButton({Title="Refresh", Callback=function() print("Refresh") end})

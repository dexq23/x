local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("ZiiqBase"))
local window = UI:CreateWindow({
    Title = "My Hub",
    Subtitle = "Reusable UI",
    Theme = "Black",
    Tabs = {
        {Id="main", Title="General", Section="Workspace", Icon="farm"},
        {Id="settings", Title="Settings", Section="Preferences", Icon="settings"},
    },
})
local main = window:GetTab("main")
main:AddSection("Controls")
main:AddButton({Title="Refresh", ButtonText="Run", Callback=function() print("Refresh") end})
local enabled = main:AddToggle({Title="Enabled", Default=false, Callback=function(value) print("Enabled",value) end})
main:AddDropdown({Title="Mode", Options={"Normal","Fast","Quiet"}, Default="Normal", Callback=function(value) print(value) end})
window:GetTab("settings"):AddDropdown({Title="Theme", Options={"Black","White","Purple","Red"}, Default="Black", Callback=function(value) window:SetTheme(value) end})
-- enabled:SetValue(true)
-- window:Destroy()

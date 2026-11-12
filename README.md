# ZIIQ UI Base

Reusable Luau UI extracted from ui.lua. Keeps the dark layout, four themes, draggable window, resize grip, responsive scaling, and touch toggle. No game actions, spy detection, Kick, or external code dependencies are included. Mobile interaction is supported in code; Delta has not been tested.

## Roblox Studio

Copy ZiiqBase.lua into a ModuleScript named ZiiqBase in ReplicatedStorage. Put example.client.lua into a LocalScript in StarterPlayerScripts. Run on the client.

## GitHub

Upload the contents of this directory to the root of your repository. Edit OWNER and REPOSITORY in example.github.lua. That loader requires an environment providing game:HttpGet and loadstring; standard Roblox LocalScripts use the ModuleScript example instead. No repository has been published automatically.

## API

```lua
local window = UI:CreateWindow({
    Title = "My Hub", Subtitle = "My project", Theme = "Black",
    ToggleKey = Enum.KeyCode.RightShift,
    Tabs = {{Id="main",Title="General",Section="Workspace",Icon="farm"}},
})
local tab = window:GetTab("main")
tab:AddSection("Controls")
tab:AddButton({Title="Refresh",Description="Optional",ButtonText="Run",Callback=function() end})
local toggle = tab:AddToggle({Title="Enabled",Default=false,Callback=function(value) end})
toggle:SetValue(true) -- SetValue(value, true) suppresses callback
local value = toggle:GetValue()
local dropdown = tab:AddDropdown({Title="Mode",Options={"A","B"},Default="A",Callback=function(value) end})
dropdown:SetOptions({"A","B","C"})
window:SelectTab("main")
window:SetTheme("Purple")
window:Toggle()
window:Destroy()
```

Declare all tabs in CreateWindow. Each window replaces the previous ZIIQ window. Theme names: Black, White, Purple, Red. Built-in icons: farm, combat, move, settings. Dropdown also accepts Multi=true (callback receives the selected table). Callbacks run asynchronously and report errors through warn. Config persistence and gameplay behavior belong in your calling script.

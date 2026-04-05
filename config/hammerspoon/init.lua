require("hs.ipc")

-- Find the largest screen by pixel area
local function largestScreen()
  local best = hs.screen.mainScreen()
  local bestArea = 0
  for _, s in ipairs(hs.screen.allScreens()) do
    local mode = s:currentMode()
    local area = mode.w * mode.h
    if area > bestArea then
      bestArea = area
      best = s
    end
  end
  return best
end

function tileApps()
  local screen = largestScreen()
  local frame = screen:frame()

  local leftHalf = hs.geometry.rect(
    frame.x, frame.y,
    frame.w / 2, frame.h
  )
  local rightHalf = hs.geometry.rect(
    frame.x + frame.w / 2, frame.y,
    frame.w / 2, frame.h
  )

  -- Use bundle IDs to avoid matching helper processes
  local alacritty = hs.application.get("org.alacritty")
  if alacritty then
    for _, win in ipairs(alacritty:allWindows()) do
      win:setFrame(leftHalf)
    end
  end

  -- Emacs daemon has no bundle ID; find by name and pick the one with windows
  for _, app in ipairs(hs.application.runningApplications()) do
    if app:name() == "emacs" or app:name() == "Emacsclient" then
      local wins = app:allWindows()
      for _, win in ipairs(wins) do
        win:setFrame(rightHalf)
      end
    end
  end
end

-- Retry tiling until Emacs has a window (up to 10 seconds)
local function tileWithRetry(attempts)
  tileApps()
  if attempts > 0 then
    local hasEmacsWindow = false
    for _, app in ipairs(hs.application.runningApplications()) do
      if (app:name() == "emacs" or app:name() == "Emacsclient") and #app:allWindows() > 0 then
        hasEmacsWindow = true
        break
      end
    end
    if not hasEmacsWindow then
      hs.timer.doAfter(1, function() tileWithRetry(attempts - 1) end)
    end
  end
end

-- Auto-tile when either app launches
local watcher = hs.application.watcher.new(function(name, event, app)
  if event == hs.application.watcher.launched then
    if name:lower() == "alacritty" or name == "Emacs" or name == "Emacsclient" then
      tileWithRetry(10)
    end
  end
end)
watcher:start()

-- Reload config automatically when it changes
local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  hs.reload()
end)
configWatcher:start()

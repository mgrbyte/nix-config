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

  local emacsclient = hs.application.get("org.gnu.Emacsclient")
  if emacsclient then
    for _, win in ipairs(emacsclient:allWindows()) do
      win:setFrame(rightHalf)
    end
  end

  -- Fallback: try the Emacs daemon process
  if not emacsclient then
    local emacs = hs.application.get("org.gnu.Emacs")
    if emacs then
      for _, win in ipairs(emacs:allWindows()) do
        win:setFrame(rightHalf)
      end
    end
  end
end

-- Auto-tile when either app launches
local watcher = hs.application.watcher.new(function(name, event, app)
  if event == hs.application.watcher.launched then
    if name:lower() == "alacritty" or name == "Emacs" or name == "Emacsclient" then
      hs.timer.doAfter(1, tileApps)
    end
  end
end)
watcher:start()

-- Reload config automatically when it changes
local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
  hs.reload()
end)
configWatcher:start()

    -- Custom (my personal configs)
import Custom.MyGridMenu
import Custom.MyKeys
import Custom.MyLayouts
import Custom.MyPrompts
import Custom.MyScratchpads
import Custom.MyTreeMenu
import Custom.MyVariables

    -- Base
import XMonad
import Data.Monoid
import System.IO (hPutStrLn)
import XMonad.Actions.MouseResize

    -- Hooks
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.EwmhDesktops  -- for some fullscreen events, also for xcomposite in obs.
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat)
import XMonad.Hooks.ServerMode
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory

    -- Utilities
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce

myStartupHook :: X ()
myStartupHook = do
          spawnOnce "nitrogen --restore &"
          spawnOnce "picom &"
          spawnOnce "nm-applet &"
          spawnOnce "volumeicon &"
          spawnOnce "trayer --edge top --align right --widthtype request --padding 6 --SetDockType true --SetPartialStrut true --expand true --monitor 1 --transparent true --alpha 0 --tint 0x292d3e --height 22 &"
          spawnOnce "/usr/bin/emacs --daemon &"
          -- spawnOnce "kak -d -s mysession &"
          setWMName "LG3D"

xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where
        doubleLts '<' = "<<"
        doubleLts x   = [x]

myWorkspaces :: [String]
myWorkspaces = clickable . (map xmobarEscape)
               -- $ ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
               $ ["dev", "www", "sys", "doc", "vbox", "chat", "mus", "vid", "gfx"]
  where
        clickable l = [ "<action=xdotool key super+" ++ show (n) ++ "> " ++ ws ++ " </action>" |
                      (i,ws) <- zip [1..9] l,
                      let n = i ]

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8!
     -- I'm doing it this way because otherwise I would have to write out
     -- the full name of my workspaces.
     [ className =? "obs"     --> doShift ( myWorkspaces !! 7 )
     , title =? "firefox"     --> doShift ( myWorkspaces !! 1 )
     , className =? "mpv"     --> doShift ( myWorkspaces !! 7 )
     , className =? "vlc"     --> doShift ( myWorkspaces !! 7 )
     , className =? "Gimp"    --> doShift ( myWorkspaces !! 8 )
     , className =? "Gimp"    --> doFloat
     , title =? "Oracle VM VirtualBox Manager"     --> doFloat
     , className =? "VirtualBox Manager" --> doShift  ( myWorkspaces !! 4 )
     , (className =? "firefox" <&&> resource =? "Dialog") --> doFloat  -- Float Firefox Dialog
     ] <+> namedScratchpadManageHook myScratchPads

myLogHook :: X ()
myLogHook = fadeInactiveLogHook fadeAmount
    where fadeAmount = 1.0

main :: IO ()
main = do
    -- Launching three instances of xmobar on their monitors.
    xmproc0 <- spawnPipe "xmobar -x 0 /home/dt/.config/xmobar/xmobarrc0"
    xmproc1 <- spawnPipe "xmobar -x 1 /home/dt/.config/xmobar/xmobarrc2"
    xmproc2 <- spawnPipe "xmobar -x 2 /home/dt/.config/xmobar/xmobarrc1"
    -- the xmonad, ya know...what the WM is named after!
    xmonad $ ewmh def
        { manageHook = ( isFullscreen --> doFullFloat ) <+> myManageHook <+> manageDocks
        -- Run xmonad commands from command line with "xmonadctl command". Commands include:
        -- shrink, expand, next-layout, default-layout, restart-wm, xterm, kill, refresh, run,
        -- focus-up, focus-down, swap-up, swap-down, swap-master, sink, quit-wm. You can run
        -- "xmonadctl 0" to generate full list of commands written to ~/.xsession-errors.
        , handleEventHook    = serverModeEventHookCmd
                               <+> serverModeEventHook
                               <+> serverModeEventHookF "XMONAD_PRINT" (io . putStrLn)
                               <+> docksEventHook
        , modMask            = myModMask
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , layoutHook         = myLayoutHook
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormColor
        , focusedBorderColor = myFocusColor
        , logHook = workspaceHistoryHook <+> myLogHook <+> dynamicLogWithPP xmobarPP
                        { ppOutput = \x -> hPutStrLn xmproc0 x  >> hPutStrLn xmproc1 x  >> hPutStrLn xmproc2 x
                        , ppCurrent = xmobarColor "#c3e88d" "" . wrap "[" "]" -- Current workspace in xmobar
                        , ppVisible = xmobarColor "#c3e88d" ""                -- Visible but not current workspace
                        , ppHidden = xmobarColor "#82AAFF" "" . wrap "*" ""   -- Hidden workspaces in xmobar
                        , ppHiddenNoWindows = xmobarColor "#c792ea" ""        -- Hidden workspaces (no windows)
                        , ppTitle = xmobarColor "#b3afc2" "" . shorten 60     -- Title of active window in xmobar
                        , ppSep =  "<fc=#666666> <fn=2>|</fn> </fc>"                     -- Separators in xmobar
                        , ppUrgent = xmobarColor "#C45500" "" . wrap "!" "!"  -- Urgent workspace
                        , ppExtras  = [windowCount]                           -- # of windows current workspace
                        , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
                        }
        } `additionalKeysP` myKeys

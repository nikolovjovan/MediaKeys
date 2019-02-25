class Windows {
	static _osdHwnd := 0

	SnapActiveWindow(requestH, requestV, ByRef releaseModifier, ByRef releaseLWin) {
		releaseModifier := false
		WinGet windowHandle, ID, A
		if (requestH == "" && requestV == "") {
			WinGet winState, MinMax, ahk_id %windowHandle%
			if (winState == 0)
				WinMaximize ahk_id %windowHandle%
			else
				WinRestore ahk_id %windowHandle%
		} else if (Windows._GetWorkArea(windowHandle, areaX, areaY, areaW, areaH)
			&& Windows._GetWindowLocation(windowHandle, areaX, areaY, areaW, areaH, actualH, actualV, offset)
			&& (requestH != actualH || requestV != actualV)) {
			if (requestH == "") {
				WinGetPos winX, winY, winW, winH, ahk_id %windowHandle%
				if (!(actualH == "" && actualV != "")) {
					; The window was not already snapped Up/Down, manually calculate everything...
					if (offset == "" || actualH == "Maximized") {
						; Offset is not initialized or the window was maximized, fallback to a hacky hack!
						if (!releaseLWin) {
							Send {LWin Down}
							releaseLWin := true
						}
						WinActivate ahk_id %windowHandle%
						SendEvent {Left}
						Sleep 50
						WinGetPos winX, winY, winW, winH, ahk_id %windowHandle%
						offset := areaX - winX
					}
					winX := areaX - offset
					winW := areaW + 2 * offset
					winH := areaH // 2 + offset
				}
				winY := requestV == "Up" ? areaY : areaY + areaH - winH
				WinMove ahk_id %windowHandle%,,%winX%, %winY%, %winW%, %winH%
			} else {
				if (!releaseLWin) {
					Send {LWin Down}
					releaseLWin := true
				}
				WinActivate ahk_id %windowHandle%
				if (actualH == "" && actualV == "" || actualH == "Maximized") {
					SendEvent {%requestH%}
					if (requestV != "")
						SendEvent {%requestV%}
				} else {
					if (actualH == "")
						SendEvent {%requestH%}
					else if (requestH != actualH)
						SendEvent {%actualH%}
					if (requestV != actualV) {
						if (requestV == "") {
							if (actualV == "Up")
								SendEvent {Down}
							else
								SendEvent {Up}
						} else {
							if (actualV == "")
								SendEvent {%requestV%}
							else if (actualV == "Up")
								SendEvent {Down 2}
							else
								SendEvent {Up 2}
						}
					}
				}
			}
		}
		KeyWait %A_ThisHotkey%
	}

	_GetWindowLocation(windowHandle, areaX, areaY, areaW, areaH, ByRef horizontal, ByRef vertical, ByRef offset) {
		horizontal         := "",
		vertical           := "",
		offset             := ""

		WinGet winState, MinMax, ahk_id %windowHandle%

		if (winState == "")
			return false ; Invalid window handle, should not happen...
		if (winState == 1)
			horizontal := "Maximized"
		else if (winState == -1)
			horizontal := "Minimized"
		else {
			WinGetPos winX, winY, winW, winH, ahk_id %windowHandle%

			deltaLeft  := areaX - winX,
			deltaUp    := areaY - winY,
			deltaRight := winX + winW - (areaX + areaW),
			deltaDown  := winY + winH - (areaY + areaH),

			touchLeft  := deltaLeft >= 0 && deltaLeft <= 10,
			touchUp    := deltaUp == 0,
			touchRight := deltaRight >= 0 && deltaRight <= 10,
			touchDown  := deltaDown >= 0 && deltaDown <= 10

			if (touchLeft && deltaRight == deltaLeft) {
				if (touchUp && touchDown && deltaDown == deltaLeft)
					horizontal := "Maximized" ; May not be actually maximized but fills the screen...
				else if (touchUp && deltaDown < 0)
					vertical := "Up"
				else if (deltaUp < 0 && deltaDown == deltaLeft)
					vertical := "Down"
			} else if (touchUp && touchDown) {
				if (deltaLeft == deltaDown && deltaRight < deltaDown)
					horizontal := "Left"
				else if (deltaRight == deltaDown && deltaLeft < deltaDown)
					horizontal := "Right"
			} else {
				if (touchUp && deltaDown < 0) {
					if (touchLeft && deltaRight < deltaLeft)
						horizontal := "Left", vertical := "Up"
					else if (deltaLeft < deltaRight && touchRight)
						horizontal := "Right", vertical := "Up"
				} else if (deltaUp < 0 && touchDown) {
					if (deltaLeft == deltaDown && deltaRight < deltaDown)
						horizontal := "Left", vertical := "Down"
					else if (deltaLeft < deltaDown && deltaRight == deltaDown)
						horizontal := "Right", vertical := "Down"
				}
			}

			if (horizontal == "" && vertical != "" || horizontal == "Left")
				offset := deltaLeft
			else if (horizontal == "Right")
				offset := deltaRight
		}

		return true
	}

	; Based on shinywong's function @ http://www.autohotkey.com/board/topic/69464-how-to-determine-a-window-is-in-which-monitor/?p=440355
	_GetWorkArea(windowHandle, ByRef x, ByRef y, ByRef w, ByRef h) {
		VarSetCapacity(monitorInfo, 40)
		NumPut(40, monitorInfo)
		if (monitorHandle := DllCall("MonitorFromWindow", "uint", windowHandle, "uint", 0x2))
			&& DllCall("GetMonitorInfo", "uint", monitorHandle, "uint", &monitorInfo) {
			x := NumGet(monitorInfo, 20, "Int")
			y := NumGet(monitorInfo, 24, "Int")
			r := NumGet(monitorInfo, 28, "Int")
			b := NumGet(monitorInfo, 32, "Int")
			w := r - x
			h := b - y
			return true
		}
		return false
	}

	_ShowOSD(wParam, lParam) {
		static PostMessagePtr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "PostMessageW" : "PostMessageA", "Ptr"),
		       WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
		if A_OSVersion in WIN_VISTA,WIN_7
			return
		Windows._RealiseOSDWindowIfNeeded()
		if (Windows._osdHwnd) {
			DllCall(PostMessagePtr, "Ptr", Windows._osdHwnd, "UInt", WM_SHELLHOOK, "Ptr", wParam, "Ptr", lParam)
		}
	}

	_RealiseOSDWindowIfNeeded() {
		static IsWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", "IsWindow", "Ptr")
		if (!DllCall(IsWindow, "Ptr", Windows._osdHwnd) && !Windows._FindAndSetOSDWindow()) {
			Windows._osdHwnd := 0
			try if ((shellProvider := ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}"))) {
				try if ((flyoutDisp := ComObjQuery(shellProvider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}"))) {
					DllCall(NumGet(NumGet(flyoutDisp+0)+3*A_PtrSize), "Ptr", flyoutDisp, "Int", 0, "UInt", 0),
					ObjRelease(flyoutDisp)
				}
				ObjRelease(shellProvider)
				if (Windows._FindAndSetOSDWindow()) {
					return
				}
			}
			; Who knows if the SID & IID above will work for future versions of Windows 10 (or Windows 8). Fall back to this if necessary...
			Loop 2 {
				SendEvent {Volume_Mute 2}
				if (Windows._FindAndSetOSDWindow()) {
					return
				}
				Sleep 100
			}
		}
	}
	
	_FindAndSetOSDWindow() {
		static FindWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "FindWindowW" : "FindWindowA", "Ptr")
		return !!((Windows._osdHwnd := DllCall(FindWindow, "Str", "NativeHWNDHost", "Str", "", "Ptr")))
	}
}
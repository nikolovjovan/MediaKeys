class OSD {
	; Based on https://github.com/qwerty12/AutoHotkeyScripts/tree/master/LaptopBrightnessSetter
	static _osdHwnd := 0

	ShowBrightnessOSD() {
		; Thanks to YashMaster @ https://github.com/YashMaster/Tweaky/blob/master/Tweaky/BrightnessHandler.h for realising this could be done:
		OSD._ShowOSD(0x37, 0)
	}

	ShowVolumeOSD() {
		; Thanks to YashMaster @ https://github.com/YashMaster/Tweaky/blob/master/Tweaky/VolumeHandler.h for realising this could be done:
		OSD._ShowOSD(0xC, 0xA0000)
	}

	_ShowOSD(wParam, lParam) {
		static PostMessagePtr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "PostMessageW" : "PostMessageA", "Ptr"),
		       WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
		if A_OSVersion in WIN_VISTA,WIN_7
			return
		OSD._RealiseOSDWindowIfNeeded()
		if (OSD._osdHwnd) {
			DllCall(PostMessagePtr, "Ptr", OSD._osdHwnd, "UInt", WM_SHELLHOOK, "Ptr", wParam, "Ptr", lParam)
		}
	}

	_RealiseOSDWindowIfNeeded() {
		static IsWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", "IsWindow", "Ptr")
		if (!DllCall(IsWindow, "Ptr", OSD._osdHwnd) && !OSD._FindAndSetOSDWindow()) {
			OSD._osdHwnd := 0
			try if ((shellProvider := ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}"))) {
				try if ((flyoutDisp := ComObjQuery(shellProvider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}"))) {
					DllCall(NumGet(NumGet(flyoutDisp+0)+3*A_PtrSize), "Ptr", flyoutDisp, "Int", 0, "UInt", 0),
					ObjRelease(flyoutDisp)
				}
				ObjRelease(shellProvider)
				if (OSD._FindAndSetOSDWindow()) {
					return
				}
			}
			; who knows if the SID & IID above will work for future versions of Windows 10 (or Windows 8). Fall back to this if needs must
			Loop 2 {
				SendEvent {Volume_Mute 2}
				if (OSD._FindAndSetOSDWindow()) {
					return
				}
				Sleep 100
			}
		}
	}
	
	_FindAndSetOSDWindow() {
		static FindWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "FindWindowW" : "FindWindowA", "Ptr")
		return !!((OSD._osdHwnd := DllCall(FindWindow, "Str", "NativeHWNDHost", "Str", "", "Ptr")))
	}
}
class AutoHotVolume {
	static _osdHwnd := 0, _minVolume := 0, _maxVolume := 100, _volume := 0

	GetVolume() {
		SoundGet, volume
		if (ErrorLevel)
			volume := -1 ; Something went wrong...
		return volume
	}

	SetVolume(volume, showOSD := true) {
		currVolume := AutoHotVolume.GetVolume()
		if (volume != currVolume) {
			SoundSet, %volume%
			SoundGet, volume
			SoundGet, isMuted, , MUTE
			shouldMute := volume == 0
			if (shouldMute != isMuted)
				SoundSet, %shouldMute%, , MUTE
		}
		if (showOSD) {
			AutoHotVolume._ShowVolumeOSD()
		}
	}

	IncreaseVolume(showOSD := true) {
		volume := AutoHotVolume.GetVolume() + 1
		AutoHotVolume.SetVolume(volume, showOSD)
	}

	DecreaseVolume(showOSD := true) {
		volume := AutoHotVolume.GetVolume() - 1
		AutoHotVolume.SetVolume(volume, showOSD)
	}

	Mute() {
		AutoHotVolume._volume := AutoHotVolume.GetVolume() ; Save volume before muting
		AutoHotVolume.SetVolume(0)
	}

	Unmute() {
		AutoHotVolume.SetVolume(AutoHotVolume._volume)
	}

	ToggleMute() {
		SoundGet, mute, , MUTE
		if (!mute)
			AutoHotVolume.Mute()
		else
			AutoHotVolume.Unmute()
	}

	_ShowVolumeOSD() {
		static PostMessagePtr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "PostMessageW" : "PostMessageA", "Ptr"),
		       WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
		if A_OSVersion in WIN_VISTA,WIN_7
			return
		AutoHotVolume._RealiseOSDWindowIfNeeded()
		; Thanks to YashMaster @ https://github.com/YashMaster/Tweaky/blob/master/Tweaky/VolumeHandler.h for realising this could be done:
		if (AutoHotVolume._osdHwnd) {
			DllCall(PostMessagePtr, "Ptr", AutoHotVolume._osdHwnd, "UInt", WM_SHELLHOOK, "Ptr", 0xC, "Ptr", 0xA0000)
		}
	}

	_RealiseOSDWindowIfNeeded() {
		static IsWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", "IsWindow", "Ptr")
		if (!DllCall(IsWindow, "Ptr", AutoHotVolume._osdHwnd) && !AutoHotVolume._FindAndSetOSDWindow()) {
			AutoHotVolume._osdHwnd := 0
			try if ((shellProvider := ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}"))) {
				try if ((flyoutDisp := ComObjQuery(shellProvider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}"))) {
					DllCall(NumGet(NumGet(flyoutDisp+0)+3*A_PtrSize), "Ptr", flyoutDisp, "Int", 0, "UInt", 0),
					ObjRelease(flyoutDisp)
				}
				ObjRelease(shellProvider)
				if (AutoHotVolume._FindAndSetOSDWindow()) {
					return
				}
			}
			; who knows if the SID & IID above will work for future versions of Windows 10 (or Windows 8). Fall back to this if needs must
			Loop 2 {
				SendEvent {Volume_Mute 2}
				if (AutoHotVolume._FindAndSetOSDWindow()) {
					return
				}
				Sleep 100
			}
		}
	}
	
	_FindAndSetOSDWindow() {
		static FindWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "FindWindowW" : "FindWindowA", "Ptr")
		return !!((AutoHotVolume._osdHwnd := DllCall(FindWindow, "Str", "NativeHWNDHost", "Str", "", "Ptr")))
	}
}
#include %A_LineFile%\..\OSD.ahk

class AutoHotVolume {
	; Based on https://github.com/qwerty12/AutoHotkeyScripts/tree/master/LaptopBrightnessSetter
	static _osdHwnd := 0, _volume := 0, _stepSize := 2

	GetVolumeLevel() {
		SoundGet, volume
		if (ErrorLevel)
			volume := -1 ; Something went wrong so return -1
		volume := Format("{1:.0f}", volume)
		return volume
	}

	SetVolumeLevel(value, jump := false, showOSD := true) {
		static minVolume := 0, maxVolume := 100

		if (value == 0 && !jump) {
			if (showOSD)
				OSD.ShowVolumeOSD()
			return
		}

		SoundGet, currVolume
		if (jump || !((currVolume == maxVolume && value > 0) || (currVolume == minVolume && value < 0))) {
			if (currVolume + value > maxVolume)
				value := maxVolume
			else if (currVolume + value < minVolume)
				value := minVolume
			else
				value += currVolume

			SoundSet, %value% ; Sets volume to value and automatically fixes any range issues
			SoundGet, volume ; Gets the actual set volume between 0 and 100 (valid range)
			SoundGet, isMuted, , MUTE
			shouldMute := volume == 0
			if (shouldMute != isMuted)
				SoundSet, %shouldMute%, , MUTE

			if (showOSD)
				OSD.ShowVolumeOSD()
		}
	}

	GetStepSize() {
		return AutoHotVolume._stepSize
	}

	SetStepSize(value) {
		if (value > 0)
			AutoHotVolume._stepSize := value
	}

	StepUp(showOSD := true) {
		AutoHotVolume.SetVolumeLevel(+AutoHotVolume._stepSize, false, showOSD)
	}

	StepDown(showOSD := true) {
		AutoHotVolume.SetVolumeLevel(-AutoHotVolume._stepSize, false, showOSD)
	}

	GetMute() {
		SoundGet, mute, , MUTE
		if (ErrorLevel)
			return -1 ; Something went wrong so return -1
		return mute
	}

	SetMute(value) {
		if (value)
			AutoHotVolume.Mute()
		else
			AutoHotVolume.Unmute()
	}

	ToggleMute() {
		SoundGet, mute, , MUTE
		AutoHotVolume.SetMute(!mute)
	}

	Mute() {
		AutoHotVolume._volume := AutoHotVolume.GetVolumeLevel() ; Save volume before muting
		AutoHotVolume.SetVolumeLevel(0)
	}

	Unmute() {
		AutoHotVolume.SetVolumeLevel(AutoHotVolume._volume)
	}
}
#include %A_LineFile%\..\WinOSD.ahk

class VolumeController {
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

		if (!jump) {
			currVolume := VolumeController.GetVolumeLevel()
			if (showOSD && (value == 0 || currVolume == maxVolume && value > 0 || currVolume == minVolume && value < 0)) {
				WinOSD.ShowVolumeOSD()
				return
			}
			value += currVolume
		}

		if (value > maxVolume)
			value := maxVolume
		else if (value < minVolume)
			value := minVolume

		SoundSet, %value%

		shouldMute := value == 0
		if (shouldMute != VolumeController.IsMuted())
			SoundSet, %shouldMute%, , MUTE

		if (showOSD)
			WinOSD.ShowVolumeOSD()
	}

	GetStepSize() {
		return VolumeController._stepSize
	}

	SetStepSize(value) {
		if (value > 0)
			VolumeController._stepSize := value
	}

	StepUp(showOSD := true) {
		VolumeController.SetVolumeLevel(+VolumeController._stepSize, false, showOSD)
	}

	StepDown(showOSD := true) {
		VolumeController.SetVolumeLevel(-VolumeController._stepSize, false, showOSD)
	}

	IsMuted() {
		SoundGet, mute, , MUTE
		if (mute == "On")
			return true
		return false
	}

	Mute() {
		VolumeController._volume := VolumeController.GetVolumeLevel() ; Save volume before muting
		VolumeController.SetVolumeLevel(0, true)
	}

	Unmute() {
		VolumeController.SetVolumeLevel(VolumeController._volume, true)
	}

	ToggleMute() {
		if (VolumeController.IsMuted())
			VolumeController.Unmute()
		else
			VolumeController.Mute()
	}
}
#include %A_ScriptDir%\lib\Windows.ahk

class Sound {
	static _volume := 0, _increment := 2

	GetVolume() {
		SoundGet, volume
		if (ErrorLevel)
			volume := -1 ; Something went wrong so return -1
		volume := Format("{1:.0f}", volume)
		return volume
	}

	SetVolume(value, jump := false) {
		static minVolume := Sound.GetMinVolume(), maxVolume := Sound.GetMaxVolume()

		if (!jump) {
			currVolume := Sound.GetVolume()
			if (value == 0 || currVolume == maxVolume && value > 0 || currVolume == minVolume && value < 0)
				return
			value += currVolume
		}

		if (value > maxVolume)
			value := maxVolume
		else if (value < minVolume)
			value := minVolume

		SoundSet, %value%

		shouldMute := value == 0
		if (shouldMute != Sound.IsMuted())
			SoundSet, %shouldMute%, , MUTE
	}

	GetMinVolume() {
		return 0
	}

	GetMaxVolume() {
		return 100
	}

	GetIncrement() {
		return Sound._increment
	}

	SetIncrement(value) {
		if (value > 0)
			Sound._increment := value
	}

	VolumeStepUp() {
		Sound.SetVolume(+Sound._increment, false)
	}

	VolumeStepDown() {
		Sound.SetVolume(-Sound._increment, false)
	}

	IsMuted() {
		SoundGet, mute, , MUTE
		if (mute == "On")
			return true
		return false
	}

	Mute() {
		Sound._volume := Sound.GetVolume() ; Save volume before muting
		Sound.SetVolume(0, true)
	}

	Unmute() {
		Sound.SetVolume(Sound._volume, true)
	}

	ToggleMute() {
		if (Sound.IsMuted())
			Sound.Unmute()
		else
			Sound.Mute()
	}
	
	ShowVolumeOSD() {
		; Thanks to YashMaster @ https://github.com/YashMaster/Tweaky/blob/master/Tweaky/VolumeHandler.h for realising this could be done:
		Windows._ShowOSD(0xC, 0xA0000)
	}
}
#NoEnv                                   ; Recommended for performance and compatibility with future AutoHotkey releases
#NoTrayIcon                              ; Disable the tray icon (we don't need it anyways)
; #Warn                                    ; Enable warnings to assist with detecting common errors
#SingleInstance force                    ; Allow only one instance to be run at one time
#Persistent                              ; Keep the script running until it is explicitly closed
#MaxHotkeysPerInterval 200               ; Limit the number of hotkeys per interval

Process, Priority, , H                   ; Launch the script with High CPU priority
SendMode Input                           ; Recommended for new scripts due to its superior speed and reliability
SetWorkingDir %A_ScriptDir%              ; Ensures a consistent starting directory

; ---- Includes ----

#include lib\AutoHotInterception.ahk     ; Library used to provide access to the Interception driver
#include lib\Display.ahk                 ; Library used to provide brightness control
#include lib\SnippingTool.ahk            ; Library used to provide screenshots using Snipping Tool with various options
#include lib\Sound.ahk                   ; Library used to provide volume control
#include lib\Windows.ahk                 ; Library used to provide various functions for Windows

; ---- Constants ----

; -- Mutable Constants --

global BrightnessIncrement     := 2      ; Brightness increment (Lenovo Y700 only has 50 brightness levels so by default this is 2)
global VolumeIncrement         := 1      ; Volume increment (bypass the default increment of 2 for finer grained control)

global WheelScrollLines        := 3      ; Vertical scroll speed which will be used for mouse wheel scrolling
global WheelScrollChars        := 3      ; Horizontal scroll speed which will be used for mouse wheel scrolling

global BallScrollLines         := 1      ; Vertical scroll speed which will be used for trackball scrolling
global BallScrollChars         := 1      ; Horizontal scroll speed which will be used for trackball scrolling

global BallScrollDeadzone      := 10     ; Distance needed to move the trackball in order to send one mouse scroll event

global ShowOSD                 := true   ; Specifies whether to show Windows OSD for brightness and volume control (available only on Windows 8+)
global ShowBrightnessLevel     := true   ; Specifies whether to show brightness level underneath the Windows 10 OSD (visible only if ShowOSD is true)

; -- Unmutable Constants --

global WM_DEVICECHANGE         := 0x0219 ; Windows Message device change
global DBT_DEVNODES_CHANGED    := 0x0007 ; Windows Event device nodes changed
global SPI_GETWHEELSCROLLLINES := 0x0068 ; SystemParametersInfo uiAction Input Parameter
global SPI_SETWHEELSCROLLLINES := 0x0069 ; SystemParametersInfo uiAction Input Parameter
global SPI_GETWHEELSCROLLCHARS := 0x006C ; SystemParametersInfo uiAction Input Parameter
global SPI_SETWHEELSCROLLCHARS := 0x006D ; SystemParametersInfo uiAction Input Parameter
global SPIF_SENDCHANGE         := 0x0002 ; SystemParametersInfo fWinIni Parameter

; ---- Variables ----

global Interception            := new AutoHotInterception().GetInstance()
global MouseHandle             := "HID\VID_046D&PID_C52B&REV_2407&MI_02&Qid_1028&WI_01&Class_00000004" ; Logitech M570
global MouseId                 := 0 ; Interception Mouse Id

global XButton1Down            := false
global XButton1Enabled         := true

global XButton2Down            := false
global XButton2Enabled         := true

global AppsKeyEnabled          := true
global ReleaseLWin             := false

; ---- Functions ----

DeviceChange(wParam, lParam, msg, hwnd) {
	if (wParam == DBT_DEVNODES_CHANGED)
		TryInitializeInterception()
}

TryInitializeInterception() {
	MouseId := Interception.GetMouseIdFromHandle(MouseHandle)
	if (MouseId < 11 || MouseId > 20)
		return
	Interception.SubscribeMouseButton(MouseId, 3, true, Func("XButton1EventHandler"))
	Interception.SubscribeMouseButton(MouseId, 4, true, Func("XButton2EventHandler"))
	Interception.SubscribeMouseButton(MouseId, 5, true, Func("WheelVerticalEventHandler"))
}

TryUnsubscribeInterception() {
	if (MouseId < 11 || MouseId > 20)
		return
	Interception.UnsubscribeMouseButton(MouseId, 3)
	Interception.UnsubscribeMouseButton(MouseId, 4)
	Interception.UnsubscribeMouseButton(MouseId, 5)
	Interception.UnsubscribeMouseMove(MouseId)
}

XButton1EventHandler(state) {
	if (WinActive("ahk_class VMUIFrame") || WinActive("ahk_exe vmware.exe"))
		Interception.SendMouseButtonEvent(MouseId, 3, state)
	else if (!XButton1Down := state) {
		if (MouseId > 10 || MouseId <= 20)
			Interception.UnsubscribeMouseMove(MouseId)
		if (XButton1Enabled)
			Send {Browser_Back}
		else
			XButton1Enabled := true
	} else if (MouseId > 10 || MouseId <= 20)
		Interception.SubscribeMouseMove(MouseId, true, Func("BallScrollHorizontal"))
}

XButton2EventHandler(state) {
	if (WinActive("ahk_class VMUIFrame") || WinActive("ahk_exe vmware.exe"))
		Interception.SendMouseButtonEvent(MouseId, 4, state)
	else if (!XButton2Down := state) {
		if (MouseId > 10 || MouseId <= 20)
			Interception.UnsubscribeMouseMove(MouseId)
		if (XButton2Enabled)
			Send {Browser_Forward}
		else
			XButton2Enabled := true
	} else if (MouseId > 10 || MouseId <= 20)
		Interception.SubscribeMouseMove(MouseId, true, Func("BallScrollVertical"))
}

WheelVerticalEventHandler(state) {
	if (WinActive("ahk_class VMUIFrame") || WinActive("ahk_exe vmware.exe"))
		Interception.SendMouseButtonEvent(MouseId, 5, state)
	else if (XButton1Down) {
		if (XButton1Enabled)
			XButton1Enabled := false
		if (state == 1)
			Display.BrightnessStepUp()
		else
			Display.BrightnessStepDown()
		if (ShowOSD) {
			Display.ShowBrightnessOSD()
			if (ShowBrightnessLevel)
				Display.ShowBrightnessLevel()
		}
	} else if (XButton2Down) {
		if (XButton2Enabled)
			XButton2Enabled := false
		if (state == 1)
			Sound.VolumeStepUp()
		else
			Sound.VolumeStepDown()
		if (ShowOSD) {
			Sound.ShowVolumeOSD()
			if (ShowBrightnessLevel)
				Display.HideBrightnessLevel()
		}
	} else {
		btn := state == 1 ? "WheelUp" : "WheelDown"
		MouseClick %btn%,,, %WheelScrollLines%
	}
}

BallScrollHorizontal(x, y) {
	static distance := 0
	if (XButton1Enabled)
		XButton1Enabled := false
	btn := x > 0 ? "WheelRight" : "WheelLeft"
	distance += x
	cnt := abs(distance) // BallScrollDeadzone
	distance -= (distance > 0 ? 1 : -1) * cnt * BallScrollDeadzone
	MouseClick %btn%,,,%cnt%
}

BallScrollVertical(x, y) {
	static distance := 0
	if (XButton2Enabled)
		XButton2Enabled := false
	btn := y > 0 ? "WheelDown" : "WheelUp"
	distance += y
	cnt := abs(distance) // BallScrollDeadzone
	distance -= (distance > 0 ? 1 : -1) * cnt * BallScrollDeadzone
	MouseClick %btn%,,,%cnt%
}

ChangeBrightness(increase, jump) {
	static previous := ""
	AppsKeyEnabled := false
	if (jump) {
		current := Display.GetBrightness()
		if (increase && current < Display.GetMaxBrightness() || !increase && current > Display.GetMinBrightness()) {
			if (previous != "" && (current == Display.GetMinBrightness() || current == Display.GetMaxBrightness())) {
				Display.SetBrightness(previous, true)
				previous := ""
			} else {
				previous := current
				if (increase)
					Display.SetBrightness(Display.GetMaxBrightness(), true)
				else
					Display.SetBrightness(Display.GetMinBrightness(), true)
			}
		}
	} else if (increase)
		Display.BrightnessStepUp()
	else
		Display.BrightnessStepDown()
	if (ShowOSD) {
		Display.ShowBrightnessOSD()
		if (ShowBrightnessLevel)
			Display.ShowBrightnessLevel()
	}
}

ChangeVolume(increase, jump) {
	static previous := ""
	AppsKeyEnabled := false
	if (jump) {
		current := Sound.GetVolume()
		if (increase && current < Sound.GetMaxVolume() || !increase && current > Sound.GetMinVolume()) {
			if (previous != "" && (current == Sound.GetMinVolume() || current == Sound.GetMaxVolume())) {
				Sound.SetVolume(previous, true)
				previous := ""
			} else {
				previous := current
				if (increase)
					Sound.SetVolume(Sound.GetMaxVolume(), true)
				else
					Sound.SetVolume(Sound.GetMinVolume(), true)
			}
		}
	} else if (increase)
		Sound.VolumeStepUp()
	else
		Sound.VolumeStepDown()
	if (ShowOSD) {
		Sound.ShowVolumeOSD()
		if (ShowBrightnessLevel)
			Display.HideBrightnessLevel()
	}
}

QuickToolTip(text, delay) {
	ToolTip % text
	SetTimer, ToolTipOff, % delay
	return

	ToolTipOff:
	SetTimer, ToolTipOff, Off
	ToolTip
	return
}

; ---- Script body ----

; Register device change notification and initialize interception
OnMessage(WM_DEVICECHANGE, "DeviceChange")
TryInitializeInterception()

; Initialize brightness and volume step sizes
Display.SetIncrement(BrightnessIncrement)
Sound.SetIncrement(VolumeIncrement)

; Set default scroll speed to 1 for precise scrolling
DllCall("SystemParametersInfo", UInt, SPI_SETWHEELSCROLLLINES, UInt, 1, UIntP, 0, UInt, SPIF_SENDCHANGE)
DllCall("SystemParametersInfo", UInt, SPI_SETWHEELSCROLLCHARS, UInt, 1, UIntP, 0, UInt, SPIF_SENDCHANGE)

OnError(Func("TryUnsubscribeInterception"))
OnExit(Func("TryUnsubscribeInterception"))
return

; ---- Hotkeys ----

; AltGr + Arrow Keys -> Media controls
; AppsKey + [RCtrl] + Arrow Keys -> Brightness & Volume controls
; AppsKey + Numpad Keys -> Window snapping
; RCtrl + Arrow Keys -> Windows Explorer navigation
; AltGr / AppsKey / RCtrl / RShift + PrintScreen -> Various Snipping Tool modes

; -- Modifier key --

AppsKey Up::
	if (AppsKeyEnabled)
		Send {AppsKey}
	else if (ReleaseLWin) {
		ReleaseLWin := false
		Send {LWin Up}
	}
	AppsKeyEnabled := true
	return

; -- Media controls --

<^>!Up::
	Send {Media_Play_Pause}
	KeyWait, Up
	return
<^>!Down::
	Send {Media_Stop}
	KeyWait, Down
	return
<^>!Left::
	Send {Media_Prev}
	KeyWait, Left
	return
<^>!Right::
	Send {Media_Next}
	KeyWait, Right
	return

; -- Window snapping --

#if GetKeyState("AppsKey", "p")
NumpadClear::
Numpad5::Windows.SnapActiveWindow("", "", AppsKeyEnabled, ReleaseLWin)
NumpadUp::
Numpad8::Windows.SnapActiveWindow("", "Up", AppsKeyEnabled, ReleaseLWin)
NumpadDown::
Numpad2::Windows.SnapActiveWindow("", "Down", AppsKeyEnabled, ReleaseLWin)
NumpadLeft::
Numpad4::Windows.SnapActiveWindow("Left", "", AppsKeyEnabled, ReleaseLWin)
NumpadRight::
Numpad6::Windows.SnapActiveWindow("Right", "", AppsKeyEnabled, ReleaseLWin)
NumpadHome::
Numpad7::Windows.SnapActiveWindow("Left", "Up", AppsKeyEnabled, ReleaseLWin)
NumpadEnd::
Numpad1::Windows.SnapActiveWindow("Left", "Down", AppsKeyEnabled, ReleaseLWin)
NumpadPgup::
Numpad9::Windows.SnapActiveWindow("Right", "Up", AppsKeyEnabled, ReleaseLWin)
NumpadPgdn::
Numpad3::Windows.SnapActiveWindow("Right", "Down", AppsKeyEnabled, ReleaseLWin)
#if

; -- Brightness & Volume controls --

#if GetKeyState("AppsKey", "p")
>^Up::
	ChangeBrightness(true, true)
	KeyWait Up
	return
>^Down::
	ChangeBrightness(false, true)
	KeyWait Down
	return
>^Left::
	ChangeVolume(false, true)
	KeyWait Left
	return
>^Right::
	ChangeVolume(true, true)
	KeyWait Right
	return
Up::ChangeBrightness(true, false)
Down::ChangeBrightness(false, false)
Left::ChangeVolume(false, false)
Right::ChangeVolume(true, false)
#if

; -- Windows Explorer navigation --

#if WinActive("ahk_class CabinetWClass") || WinActive("ahk_class #32770")
; Go up to parent folder when in WindowsExplorer
; For some reason SendEvent works whereas Send doesn't
; Send opens a new window with parent location instead of
; changing location in the current window
>^Up::SendEvent {Alt Down}{Up Down}{Up Up}{Alt Up}
<!Down:: ; Add LAlt & Down to go back aswell
>^Down::
>^Left::Send {Browser_Back}
>^Right::Send {Browser_Forward}
#if

; -- Screenshot controls --

<^>!PrintScreen::SnippingTool.NewCapture() ; AltGr & PrintScreen -> New Capture (Previously used mode)
>^PrintScreen::SnippingTool.FreeForm()     ; RCtrl & PrintScreen -> Capture FreeForm
>+PrintScreen::SnippingTool.Rectangular()  ; RShift & PrintScreen -> Capture Rectangular
$PrintScreen::
	if (GetKeyState("AppsKey", "p")) {
		AppsKeyEnabled := false
		SnippingTool.Window()              ; AppsKey & PrintScreen -> Capture Window
	} else
		SnippingTool.FullScreen()          ; PrintScreen by itself -> Capture FullScreen
	return
>^>+PrintScreen::Send {PrintScreen}        ; RCtrl & RShift & PrintScreen -> Send PrintScreen
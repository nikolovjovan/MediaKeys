#NoEnv                                   ; Recommended for performance and compatibility with future AutoHotkey releases
;#NoTrayIcon                             ; Disable the tray icon (we don't need it anyways)
#Warn                                    ; Enable warnings to assist with detecting common errors
#SingleInstance force                    ; Allow only one instance to be run at one time
#Persistent                              ; Keep the script running until it is explicitly closed
#MaxHotkeysPerInterval 100               ; Limit the number of hotkeys per interval

Process, Priority, , H                   ; Launch the script with High CPU priority
SendMode Input                           ; Recommended for new scripts due to its superior speed and reliability
SetWorkingDir %A_ScriptDir%              ; Ensures a consistent starting directory

; ---- Includes ----

#include lib\AutoHotInterception.ahk     ; Library used to provide access to Interception driver
#include lib\BrightnessController.ahk    ; Library used to provide brightness control
#include lib\InertialScroller.ahk        ; Library used to provide kinetic strolling
#include lib\SnippingTool.ahk            ; Library used to provide screenshots using Snipping Tool with various options
#include lib\VolumeController.ahk        ; Library used to provide volume control

; ---- Constants ----

; -- Mutable Constants --

global DoubleTapTimeout        := 100    ; Specifies the double tap timeout (used for brightness and volume control)
global ScrollSpeed             := 1      ; Specifies default scroll speed which will be applied at script startup
global ShowBrightnessTooltip   := true   ; Specifies whether to show brightness percentage underneath the Windows 10 OSD
global ShowVolumeTooltip       := false  ; Specifies whether to show volume percentage underneath the Windows 10 OSD
global ShowWinOSD              := true   ; Specifies whether to show Windows 10 OSD for brightness and volume control

; -- Unmutable Constants --

global WM_DEVICECHANGE         := 0x0219 ; Windows Message device change
global DBT_DEVNODES_CHANGED    := 0x0007 ; Windows Event device nodes changed
global SPI_SETWHEELSCROLLCHARS := 0x006D ; SystemParametersInfo uiAction Input Parameter
global SPI_SETWHEELSCROLLLINES := 0x0069 ; SystemParametersInfo uiAction Input Parameter
global SPIF_SENDCHANGE         := 0x0002 ; SystemParametersInfo fWinIni Parameter

; ---- Variables ----

; -- Interception Variables --

global Interception            := new AutoHotInterception().GetInstance()
global MouseHandle             := "HID\VID_046D&PID_C52B&REV_2407&MI_02&Qid_1028&WI_01&Class_00000004" ; Logitech M570
global MouseId                 := 0 ; Interception Mouse Id

; -- Modifier Keys Variables --

global RButtonDown             := false
global RButtonEnabled          := true

global XButton1Down            := false
global XButton1Enabled         := true

global XButton2Down            := false
global XButton2Enabled         := true

global AppsKeyEnabled          := true
global ReleaseLWin             := false

; -- Other Variables --

global BrightnessBeforeJump    := -1 ; Stores current brightness before jump
global VolumeBeforeJump        := -1 ; Stores current volume before jump

; ---- Functions ----

DeviceChange(wParam, lParam, msg, hwnd) {
	if (wParam == DBT_DEVNODES_CHANGED)
		TryInitializeInterception()
}

TryInitializeInterception() {
	MouseId := Interception.GetMouseIdFromHandle(MouseHandle)
	if (MouseId > 0) {
		Interception.SubscribeMouseButton(MouseId, 1, true, Func("RButtonEventHandler"))
		Interception.SubscribeMouseButton(MouseId, 3, true, Func("XButton1EventHandler"))
		Interception.SubscribeMouseButton(MouseId, 4, true, Func("XButton2EventHandler"))
		Interception.SubscribeMouseButton(MouseId, 5, true, Func("WheelVerticalEventHandler"))
	}
}

RButtonEventHandler(state) {
	if (!RButtonDown := state) {
		if (RButtonEnabled)
			Send {RButton}
		else
			RButtonEnabled := true
	}
}

XButton1EventHandler(state) {
	if (!XButton1Down := state) {
		if (XButton1Enabled)
			Send {Browser_Back}
		else
			XButton1Enabled := true
	}
}

XButton2EventHandler(state) {
	if (!XButton2Down := state) {
		if (XButton2Enabled)
			Send {Browser_Forward}
		else
			XButton2Enabled := true
	}
}

WheelVerticalEventHandler(state) {
	if (XButton1Down) {
		XButton1Enabled := false
		if (state == 1)
			BrightnessController.StepUp(ShowWinOSD)
		else
			BrightnessController.StepDown(ShowWinOSD)
		BrightnessTooltip()
	} else if (XButton2Down) {
		XButton2Enabled := false
		if (state == 1)
			VolumeController.StepUp(ShowWinOSD)
		else
			VolumeController.StepDown(ShowWinOSD)
		VolumeTooltip()
	} else if (RButtonDown) {
		RButtonEnabled := false
		if (state == 1)
			Interception.SendMouseButtonEvent(MouseId, 6, -1)
			; AutoHotScroller.Scroll("WheelLeft")
		else
			Interception.SendMouseButtonEvent(MouseId, 6, 1)
			; AutoHotScroller.Scroll("WheelRight")
	} else {
		if (state == 1)
			Interception.SendMouseButtonEvent(MouseId, 5, 1)
			; AutoHotScroller.Scroll("WheelUp")
		else
			Interception.SendMouseButtonEvent(MouseId, 5, -1)
			; AutoHotScroller.Scroll("WheelDown")
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

ShowPercentage(value) {
	static shown := false
	if (value == -1) {
		SetTimer, PercentageOff, Off
		Progress, Off
		shown := false
		return
	}
	if (!shown)
		Progress, B W65 H28 X62 Y250 ZH0 ZX5 ZY5 FM9 WM500 CTWhite CWBlack, %value%
	else
		Progress, , %value%
	SetTimer PercentageOff, 2000
	shown := true
	return

	PercentageOff:
	SetTimer, PercentageOff, Off
	Progress, Off
	shown := false
	return
}

BrightnessTooltip() {
	if (ShowBrightnessTooltip)
		ShowPercentage(BrightnessController.GetBrightnessLevel())
	else
		ShowPercentage(-1)
}

VolumeTooltip() {
	if (ShowVolumeTooltip)
		ShowPercentage(VolumeController.GetVolumeLevel())
	else
		ShowPercentage(-1)
}

; ---- Script body ----

; Set mouse scroll speed
DllCall("SystemParametersInfo", UInt, SPI_SETWHEELSCROLLCHARS, UInt, ScrollSpeed, UInt, 0, UInt, SPIF_SENDCHANGE)
DllCall("SystemParametersInfo", UInt, SPI_SETWHEELSCROLLLINES, UInt, ScrollSpeed, UInt, 0, UInt, SPIF_SENDCHANGE)

; Register device change notification and initialize interception
OnMessage(WM_DEVICECHANGE, "DeviceChange")
TryInitializeInterception()

; Initialize brightness and volume step sizes
BrightnessController.SetStepSize(2)
VolumeController.SetStepSize(1)
return

; ---- Hotkeys ----

; AltGr + Arrow Keys -> Media controls
; AppsKey + Arrow Keys -> Window snapping
; RCtrl + Arrow Keys -> Windows Explorer navigation
; RShift + Arrow Keys -> Brightness & Volume controls
; AltGr / AppsKey / RCtrl / RShift + PrintScreen -> Various Snipping Tool modes

; -- Media controls --

<^>!Up::
	Send {Media_Play_Pause Down}
	KeyWait, Up
	return

<^>!Up Up::Send {Media_Play_Pause Up}

<^>!Down::
	Send {Media_Stop Down}
	KeyWait, Down
	return

<^>!Down Up::Send {Media_Stop Up}

<^>!Left::
	Send {Media_Prev Down}
	KeyWait, Left
	return

<^>!Left Up::Send {Media_Prev Up}

<^>!Right::
	Send {Media_Next Down}
	KeyWait, Right
	return

<^>!Right Up::Send {Media_Next Up}

#If

; -- Window snapping --

#If GetKeyState("AppsKey", "p")
Up::
Down::
Left::
Right::
	AppsKeyEnabled := false
	ReleaseLWin := true
	Send {LWin Down}{%A_ThisHotkey%}
	return
#If

; AppsKey Up hotkey to allow normal AppsKey usage

AppsKey Up::
	if (AppsKeyEnabled)
		Send {AppsKey}
	else {
		AppsKeyEnabled := true
		if (ReleaseLWin) {
			ReleaseLWin := false
			Send {LWin Up}
		}
	}
	return

; -- Windows Explorer navigation --

#If WinActive("ahk_class CabinetWClass") or WinActive("ahk_class #32770")
; Go up to parent folder when in WindowsExplorer
; For some reason SendEvent works whereas Send doesn't
; Send opens a new window with parent location instead of
; changing location in the current window
>^Up::SendEvent {Alt Down}{Up Down}{Up Up}{Alt Up}
<!Down:: ; Add LAlt & Down to go back aswell
>^Down::
>^Left::Send {Browser_Back}
>^Right::Send {Browser_Forward}
#If

; -- Brightness & Volume controls --

>+Up::
	if (A_PriorHotkey == A_ThisHotkey . " Up" && A_TimeSincePriorHotkey <= DoubleTapTimeout) {
		if (BrightnessController.GetBrightnessLevel() == BrightnessController.GetStepSize()) {
			if (BrightnessBeforeJump != -1)
				BrightnessController.SetBrightnessLevel(BrightnessBeforeJump, true)
			else
				BrightnessController.SetBrightnessLevel(100, true)
		} else {
			BrightnessBeforeJump := BrightnessController.GetBrightnessLevel() - BrightnessController.GetStepSize()
			BrightnessController.SetBrightnessLevel(100, true)
		}
	} else
		BrightnessController.StepUp(ShowWinOSD)
	BrightnessTooltip()
	return

>+Up Up::return    ; Create a blank hotkey to generate A_PriorHotkey

>+Down::
	if (A_PriorHotkey == A_ThisHotkey . " Up" && A_TimeSincePriorHotkey <= DoubleTapTimeout) {
		if (BrightnessController.GetBrightnessLevel() == 100 - BrightnessController.GetStepSize()) {
			if (BrightnessBeforeJump != -1)
				BrightnessController.SetBrightnessLevel(BrightnessBeforeJump, true)
			else
				BrightnessController.SetBrightnessLevel(0, true)
		} else {
			BrightnessBeforeJump := BrightnessController.GetBrightnessLevel() + BrightnessController.GetStepSize()
			BrightnessController.SetBrightnessLevel(0, true)
		}
	} else
		BrightnessController.StepDown(ShowWinOSD)
	BrightnessTooltip()
	return

>+Down Up::return  ; Create a blank hotkey to generate A_PriorHotkey

>+Right::
	if (A_PriorHotkey == A_ThisHotkey . " Up" && A_TimeSincePriorHotkey <= DoubleTapTimeout) {
		if (VolumeController.GetVolumeLevel() == VolumeController.GetStepSize()) {
			if (VolumeBeforeJump != -1)
				VolumeController.SetVolumeLevel(VolumeBeforeJump, true)
			else
				VolumeController.SetVolumeLevel(100, true)
		} else {
			VolumeBeforeJump := VolumeController.GetVolumeLevel() - VolumeController.GetStepSize()
			VolumeController.SetVolumeLevel(100, true)
		}
	} else
		VolumeController.StepUp(ShowWinOSD)
	VolumeTooltip()
	return

>+Right Up::return ; Create a blank hotkey to generate A_PriorHotkey

>+Left::
	if (A_PriorHotkey == A_ThisHotkey . " Up" && A_TimeSincePriorHotkey <= DoubleTapTimeout) {
		if (VolumeController.GetVolumeLevel() == 100 - VolumeController.GetStepSize()) {
			if (VolumeBeforeJump != -1)
				VolumeController.SetVolumeLevel(VolumeBeforeJump, true)
			else
				VolumeController.SetVolumeLevel(0, true)
		} else {
			VolumeBeforeJump := VolumeController.GetVolumeLevel() + VolumeController.GetStepSize()
			VolumeController.SetVolumeLevel(0, true)
		}
	} else
		VolumeController.StepDown(ShowWinOSD)
	VolumeTooltip()
	return

>+Left Up::return  ; Create a blank hotkey to generate A_PriorHotkey

; -- Screenshot controls --

<^>!PrintScreen::SnippingTool.NewCapture() ; AltGr & PrintScreen -> New Capture (Previously used mode)
>^PrintScreen::SnippingTool.FreeForm()     ; RCtrl & PrintScreen -> Capture FreeForm
>+PrintScreen::SnippingTool.Rectangular()  ; RShift & PrintScreen -> Capture Rectangular
$PrintScreen::
	if (!GetKeyState("AppsKey", "p")) {
		AppsKeyEnabled := false
		SnippingTool.Window()              ; AppsKey & PrintScreen -> Capture Window
	} else
		SnippingTool.FullScreen()          ; PrintScreen by itself -> Capture FullScreen
	return
>^>+PrintScreen::Send {PrintScreen}        ; RCtrl & RShift & PrintScreen -> Send PrintScreen
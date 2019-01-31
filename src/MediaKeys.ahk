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

#include lib\AutoHotBrightness.ahk       ; Library used to provide brightness control
#include lib\AutoHotInterception.ahk     ; Library used to provide access to Interception driver
#include lib\AutoHotScreenshot.ahk       ; Library used to provide screenshots using Snipping Tool with various options
#include lib\AutoHotScroller.ahk         ; Library used to provide kinetic strolling
#include lib\AutoHotVolume.ahk           ; Library used to provide volume control

; -- Modifiable Constants --
global ScrollSpeed             := 1      ; Specifies default scroll speed which will be applied at script startup
global ShowTooltip             := true   ; Specifies whether to show tooltips for brightness and volume control
global ShowOSD                 := true   ; Specifies whether to show Windows 10 OSD for brightness and volume control

; -- Unmodifiable Constants --
global WM_DEVICECHANGE         := 0x0219 ; Windows Message device change
global DBT_DEVNODES_CHANGED    := 0x0007 ; Windows Event device nodes changed
global SPI_SETWHEELSCROLLCHARS := 0x006D ; SystemParametersInfo uiAction Input Parameter
global SPI_SETWHEELSCROLLLINES := 0x0069 ; SystemParametersInfo uiAction Input Parameter
global SPIF_SENDCHANGE         := 0x0002 ; SystemParametersInfo fWinIni Parameter

; -- Script Variables --
global Interception            := new AutoHotInterception().GetInstance()
global MouseHandle             := "HID\VID_046D&PID_C52B&REV_2407&MI_02&Qid_1028&WI_01&Class_00000004"

global RButtonDown             := false
global XButton1Down            := false
global XButton2Down            := false

global RButtonEnabled          := true
global XButton1Enabled         := true
global XButton2Enabled         := true

; ---- Functions ----

DeviceChange(wParam, lParam, msg, hwnd) {
	if (wParam == DBT_DEVNODES_CHANGED) {
		TryInitializeInterception()
	}
}

TryInitializeInterception() {
	mouseID := Interception.GetMouseIdFromHandle(MouseHandle)
	if (mouseID > 0) {
		Interception.SubscribeMouseButton(mouseID, 1, true, Func("RButtonEventHandler"))
		Interception.SubscribeMouseButton(mouseID, 3, true, Func("XButton1EventHandler"))
		Interception.SubscribeMouseButton(mouseID, 4, true, Func("XButton2EventHandler"))
		Interception.SubscribeMouseButton(mouseID, 5, true, Func("WheelVerticalEventHandler"))
	}
}

RButtonEventHandler(state) {
	if (!RButtonDown := state) {
		if (RButtonEnabled) {
			Send {RButton}
		} else {
			RButtonEnabled := true
		}
	}
}

XButton1EventHandler(state) {
	if (!XButton1Down := state) {
		if (XButton1Enabled) {
			Send {Browser_Back}
		} else {
			XButton1Enabled := true
		}
	}
}

XButton2EventHandler(state) {
	if (!XButton2Down := state) {
		if (XButton2Enabled) {
			Send {Browser_Forward}
		} else {
			XButton2Enabled := true
		}
	}
}

WheelVerticalEventHandler(state) {
	if (XButton1Down) {
		XButton1Enabled := false
		if (state == 1)
			AutoHotBrightness.StepUp(ShowOSD)
		else
			AutoHotBrightness.StepDown(ShowOSD)
		if (ShowTooltip) {
			brightness := AutoHotBrightness.GetBrightnessLevel()
			QuickToolTip("Brightness: " . brightness . "%", 2000)
		}
	} else if (XButton2Down) {
		XButton2Enabled := false
		if (state == 1)
			AutoHotVolume.StepUp(ShowOSD)
		else
			AutoHotVolume.StepDown(ShowOSD)
		if (ShowTooltip) {
			volume := AutoHotVolume.GetVolumeLevel()
			QuickToolTip("Volume: " . volume . "%", 2000)
		}
	} else if (RButtonDown) {
		RButtonEnabled := false
		if (state == 1) {
			AutoHotScroller.Scroll("WheelLeft")
		} else {
			AutoHotScroller.Scroll("WheelRight")
		}
	} else {
		if (state == 1) {
			AutoHotScroller.Scroll("WheelUp")
		} else {
			AutoHotScroller.Scroll("WheelDown")
		}
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

; ---- Script initialization ----

; Set mouse scroll speed
DllCall("SystemParametersInfo", UInt, SPI_SETWHEELSCROLLCHARS, UInt, ScrollSpeed, UInt, 0, UInt, SPIF_SENDCHANGE)
DllCall("SystemParametersInfo", UInt, SPI_SETWHEELSCROLLLINES, UInt, ScrollSpeed, UInt, 0, UInt, SPIF_SENDCHANGE)

; Register device change notification and initialize interception
OnMessage(WM_DEVICECHANGE, "DeviceChange")
TryInitializeInterception()

; Initialize brightness and volume step sizes
AutoHotBrightness.SetStepSize(2)
AutoHotVolume.SetStepSize(1)
return
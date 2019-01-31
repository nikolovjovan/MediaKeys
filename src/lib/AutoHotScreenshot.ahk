class AutoHotScreenshot {

	Launch() {
		Run SnippingTool
		WinWait Snipping Tool
		WinActivate Snipping Tool
	}

	NewCapture() {
		AutoHotScreenshot.Launch()
		Send ^n
	}

	FreeForm() {
		AutoHotScreenshot.Launch()
		Send !m
		Send f
	}

	Rectangular() {
		AutoHotScreenshot.Launch()
		Send !m
		Send r
	}

	Window() {
		AutoHotScreenshot.Launch()
		Send !m
		Send w
	}

	FullScreen() {
		AutoHotScreenshot.Launch()
		Send !m
		Send s
	}
}
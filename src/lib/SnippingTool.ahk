class SnippingTool {

	Launch() {
		Run SnippingTool
		WinWait Snipping Tool
		WinActivate Snipping Tool
	}

	NewCapture() {
		SnippingTool.Launch()
		Send ^n
	}

	FreeForm() {
		SnippingTool.Launch()
		Send !m
		Send f
	}

	Rectangular() {
		SnippingTool.Launch()
		Send !m
		Send r
	}

	Window() {
		SnippingTool.Launch()
		Send !m
		Send w
	}

	FullScreen() {
		SnippingTool.Launch()
		Send !m
		Send s
	}
}
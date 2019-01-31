class AutoHotScroller {
	minElapsed      := 10  ; Min elapsed time that will be parsed (because there were cases when the time was 0)
	maxElapsed      := 100 ; Max elapsed time that will be parsed
	notchDistance   := 100 ; Virtual distance one scroll notch represents
	flingPeriod     := 20  ; Fling timer default period
	maxSpeed        := 100 ; Max scroll events this script will send

	prevWheel       := ""
	prevTickCount   := 0
	speed           := 0

	Scroll(wheel) {
		; if (wheel == this.prevWheel) {
		; 	elapsed := A_TickCount - this.prevTickCount
		; 	if (elapsed >= this.minElapsed && elapsed <= this.maxElapsed) {
		; 		currentSpeed := this.notchDistance / elapsed
		; 		; if (currentSpeed > this.speed) {
		; 		;     this.speed := currentSpeed ; only increase the speed, never decrease it
		; 		; }
		; 		this.speed += currentSpeed
		; 	} else if (this.speed < 1) {
		; 		this.speed := 1
		; 		SetTimer, Fling, Off
		; 	}
		; 	if (this.speed > 1) {
		; 		flingPeriod := this.flingPeriod
		; 		SetTimer, Fling, %flingPeriod%
		; 	}
		; } else {
		; 	this.prevWheel := wheel
		; 	this.speed := 1
		; 	SetTimer, Fling, Off
		; }
		; this.prevTickCount := A_TickCount
		; ; QuickToolTip("Speed: " . this.speed, 100)
		; intSpeed := ceil(this.speed)
		; Click %wheel%, %intSpeed%
		Click %wheel%
		return

	Fling:
		if (this.speed > 0) {
			intSpeed := ceil(this.speed)
			if (intSpeed > this.maxSpeed) {
				intSpeed := this.maxSpeed
			}
			direction := this.prevWheel
			Click %direction%, %intSpeed%
			this.speed--
			QuickToolTip("Speed: " . this.speed, 100)
		} else {
			this.speed := 0
			SetTimer, Fling, Off
		}
		return
	}

		; Fling:
		; if (this.speed > 0) {
		;     scrollCount := ceil(this.speed)
		;     if (scrollCount > 100)
		;         scrollCount := 100
		;     QuickToolTip("scrollCount: " . scrollCount, 500)
		;     Click %wheel%, %scrollCount%
		;     this.speed--
		; } else {
		;     this.speed := 0
		;     SetTimer, Fling, Off
		; }
		; return
		; if (wheel == prevWheel && (A_TickCount - prevTickCount <= timeout || speed >= startNotchCount))
		; {
		;     counter++
		;     speed++
		;     flingPeriod := flingTimerPeriod
		;     if (speed < slowdownSpeed)
		;         flingPeriod += slowdownSpeed - Speed
		;     SetTimer, Fling, % flingPeriod
		; }
		; else
		; {
		;     counter := 1
		;     speed := 1
		;     prevTickCount := A_TickCount
		;     SetTimer, Fling, Off
		; }
		; if (speed > maxScrollSpeed)
		;     Click % wheel, maxScrollSpeed
		; else
		;     Click % wheel, speed
		; QuickToolTip("prevWheel:"prevWheel, 100)
		; prevWheel := wheel
		; return

		; Fling:
		; if (speed > 0)
		; {
		;     if (speed > maxScrollSpeed)
		;         Click % wheel, maxScrollSpeed
		;     else
		;         Click % wheel, Speed
		;     speed--
		;     if (speed <= slowdownSpeed)
		;     {
		;         flingPeriod++
		;         SetTimer Fling, % flingPeriod
		;     }
		;     QuickToolTip("Speed:"speed, 100)
		; }
		; else
		; {
		;     Counter := 0
		;     Speed := 0
		;     SetTimer, Fling, Off
		; }
		; return
	; }
}
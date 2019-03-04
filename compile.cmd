@echo off
if not exist bin mkdir bin > nul 2>&1
if not exist bin\x64\interception.dll xcopy /s /y /i src\lib\x64 bin\x64\ > nul 2>&1
if not exist bin\x86\interception.dll xcopy /s /y /i src\lib\x86 bin\x86\ > nul 2>&1
copy /y src\lib\AutoHotInterception.dll bin\ > nul 2>&1
copy /y icon\icon.ico bin\MediaKeys.ico > nul 2>&1
"C:\Program Files\AutoHotkey\Compiler\ahk2exe.exe" /in src\MediaKeys.ahk /out bin\MediaKeys.x64.exe /icon bin\MediaKeys.ico /bin "C:\Program Files\AutoHotkey\Compiler\Unicode 64-bit.bin" > nul 2>&1
"C:\Program Files\AutoHotkey\Compiler\ahk2exe.exe" /in src\MediaKeys.ahk /out bin\MediaKeys.x86.exe /icon bin\MediaKeys.ico /bin "C:\Program Files\AutoHotkey\Compiler\Unicode 32-bit.bin" > nul 2>&1
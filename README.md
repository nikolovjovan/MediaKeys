# MediaKeys
An AutoHotkey script I use every day on my Lenovo Y700 and Logitech M570...

## Features

Combines several scripts I found online over the years with some of my own. Makes life way easier and nicer by adding brightness, volume and other shortcuts to some easily accessible keys and my mouse. Also adds inertial scrolling to my M570.

ToDo: List script features here...

## Getting Started

This script uses Interception driver by Francisco Lopez and because it is a driver it can mess up keyboard and/or mouse by blocking their events. This should not happen but be prepared to restart your PC if it ever happens. If it does happen report an issue here since it is most likely a problem with the script or any modification you may have made to it.

To access the Interception API this script uses [AutoHotInterception](https://github.com/evilC/AutoHotInterception) library, specifically my modified fork found [here](https://github.com/crumbl3d/AutoHotInterception). The changes made to this library have not yet been merged so you need to build it manually. **Take a look at that repo for more details.**

### Setup:

1. Download and install the [Interception Driver](http://www.oblita.com/interception).
2. Clone or Download the [latest AHI fork](https://github.com/crumbl3d/AutoHotInterception) and build the AutoHotInterception C# library.
3. Clone or Download the latest version of this script.
4. Copy the freshly built AutoHotInterception.dll and interception.dlls (both x86 and x64) to src\lib folder of MediaKeys.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Credits:

1. Francisco Lopez - [Interception](https://github.com/oblitum/Interception)
2. Clive Galway - [AutoHotInterception](https://github.com/evilC/AutoHotInterception)
3. Faheem Pervez - [BrightnessSetter script](https://github.com/qwerty12/AutoHotkeyScripts/tree/master/LaptopBrightnessSetter)
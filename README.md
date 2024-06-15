<h1>Kali-Armbian userpatches </h1>

<h3>This is an attempt at creating an SBC-oriented "stealth" armbian-based kali headless machine</h3>

- Support for OragenPIZero3, OrangePIZero2w (AllWinner BRANCH=current,edge)
- Support for OrangePI5-Plus (rk3588 BRANCH=vendor,legacy,current)
- Support for nanopi-r5c (rockchip64 BRANCH=current only at the moment)
- Kali injection patches from official [GitLab](https://gitlab.com/kalilinux/packages/linux/-/blob/kali/master/debian/patches/series?ref_type=heads) (reworked to apply to kernel 6.6/6.7/6.8)
- HID input disabled
- Armbian Extension to add Kali repos and pin Kali packages to Armbian
- Customizations providing a bunch of stuff (udev-based auto monitor mode creation and mac randomization | disabling of serial UARTS | disabling of video output | ...)
- Auto installation of latest release of AngryOxide [gh:Ragnt/AngryOxide.git](https://github.com/Ragnt/AngryOxide)
- Auto installation of dnsleaktest from [gh:macvk/dnsleaktest.git](https://github.com/macvk/dnsleaktest)

<h3>Assumptions: </h3>

- Serial GPS support preconfigured (oPIZero02w/oPIZero3) | Bluetooth GPS supported OOB
- Bluetooth GPS support preconfigured (oPI5-Plus/nanopi-r5c)
- oPIZero02w/oPIZero3: onboard wifi configured as sta0 - station mode only | Ethernet mac randomization by default
- oPI5-Plus: PCIE-Realtek 8852be + Bluetooth - rtw88 monitor mode virtual interface and mac randomization by default | Ethernet mac randomization by default
- nanopi5plus: PCIE MT7922 + Bluetooth - mainline monitor mode virtual interface and mac randomization by default | Ethernet mac randomization by default
- Infrared support enabled by default on supported boards
- All: morrownr/88x2bu-20210702, morrownr/8821au-20210708 installable via shell alias 'morrownr', update via 'update_rtl_improved.sh (to be improved)

<p> Original ideas and code from: Armbian https://github.com/armbian/os especially @igorpecovnik https://github.com/igorpecovnik</p>
<p>More info on Armbian's forum thread https://forum.armbian.com/topic/37503-kali-linux-as-supported-distro/</p>

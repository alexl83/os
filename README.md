<h1> orangepi-related configs/patches for Armbian </h1>

<p>This is an attempt at creating an SBC-oriented "stealth" armian-based kali headless machine</p>

- Config build files for OragenPI Zero3 and Zero2w and 5 Plus --> userpatches/config-{opi02w,opi03,opi5plus}.conf
- Kali injection patches from official gitlab (reworked to apply to kernel 6.7/6.8) --> userpatches/kernel/archive/sunxi-6.{6,7} && userpatches/kernel/rockchip-rk3588-edge
- Armbian Extension to add Kali repos and pin (prioritize) Kali packages to Armbian in a safe (I hope) step of the build process --> userpatches/extensions/kali-ale.sh **(WIP but works)**
- Customization script that does a bunch of stuff (udev-based auto monitor mode creation and mac randomization | disabling of serial UARTS | disabling of video output | etc) --> userpatches/customize.sh **(WIP but works)**
- Auto installation of latest compiled release of AngryOxide gh:Ragnt/AngryOxide.git

<p> Original ideas and code from: Armbian https://github.com/armbian/os especially @igorpecovnik https://github.com/igorpecovnik </p>
<p>More info on Armbian's forum thread https://forum.armbian.com/topic/37503-kali-linux-as-supported-distro/</p>

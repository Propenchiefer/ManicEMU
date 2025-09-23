# Manic-EMU [![AGPLv3 License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

Manic EMU is an all-in-one retro game emulator for iOS. It packs powerful features while keeping a clean, sleek UI and delivering buttery-smooth gameplay.

<p float="center">
  <img src="images_manicemu_ver4_a01.jpg" width="13%">
  <img src="images_manicemu_ver4_a02.jpg" width="13%">
  <img src="images_manicemu_ver4_a03.jpg" width="13%">
  <img src="images_manicemu_ver4_a04.jpg" width="13%">
  <img src="images_manicemu_ver4_a05.jpg" width="13%">
  <img src="images_manicemu_ver4_a06.jpg" width="13%">
  <img src="images_manicemu_ver4_a07.jpg" width="13%">
</p>

</br>

[<img src="appstore-badge.png" height="50">](https://itunes.apple.com/us/app/id6743335790)
</br>
Manic EMU is now available on the AppStore

</br>

[<img src="kofi-badge.png" height="50">](https://ko-fi.com/maftymanicemu)
</br>
Your support keeps this app going

</br>

## Features

### [Supported Platforms]

#### Nintendo
- Nintendo 3DS (3DS)
- Nintendo 64 (N64)
- Nintendo DS (NDS)
- Game Boy Advance (GBA)
- Game Boy Color (GBC)
- Game Boy (GB)
- Nintendo Entertainment System (NES)
- Super Nintendo Entertainment System (SNES)
- Virtual Boy (VB)
- Pokémon Mini (PM)

#### SONY
- PlayStation (PS1)
- PlayStation Portable (PSP)

#### SEGA
- Sega Dreamcast (DC)
- Sega Saturn (SS)
- Sega Master System (MS)
- Sega Game Gear (GG)
- Sega SG-1000 (SG)
- Sega Genesis 32X/Super 32X (32X)
- Sega CD/Mega-CD (MCD)
- Sega Genesis/MegaDrive (MD)

More platforms coming soon!

### [Key Features]
- Unlimited Saves: Manual & 50 auto-save slots
- 5x Speed: Control the game’s pace
- Cheat Codes: Unlimited library for perfect playthroughs
- Retro Filters: Immersive visual effects
- Custom Skins: Authentic feel, third-party compatible
- Screenshot Tool: Share your epic moments
- Landscape Mode: Enhanced gameplay experience
- Custom Shortcuts: Redefine your controls


### [RetroAchievements Integration • Challenge Yourself]
- Hardcore Mode Verified by RetroAchievements
- Track and Share your Achievments with ease
- RetroAchievments Account required


### [iCloud Sync • Your Gaming Universe]
- Cross-device sync for games, saves, and settings
- Encrypted storage • Cloud backups • No progress loss
- Switch between phone and tablet seamlessly
- Play anywhere—your journey never pauses!


### [Cloud Integration • One-Click Import]
- Google Drive, Dropbox, OneDrive, Baidu Cloud, Aliyun
- WebDAV/SMB protocol support—access the entire web!


### [Controller Freedom • Play Your Way]
- Native Joy-Con/DUALSHOCK/Xbox support
- Bluetooth controllers/keyboards • Mac compatible
- Multi-controller connectivity
- Switch between solo play and multiplayer battles


### [Cross-Screen Play • Conquer the Big Screen]
- AirPlay mirroring for lag-free streaming
- Phone-to-TV switching for parties or couch gaming
- Big screen + controller = Ultimate immersion

## Development Notes
 **Build Environment**: Requires Xcode 16+, iOS SDK 15+, and Swift 5.9+

 **Build Step**
1. Install VulkanSDK  
2. Install C++ Boost
3. cd Manic-EMU/ManicEmu
4. pod install
5. Open Manic-EMU/ManicEmu/ManicEmu.xcworkspace
6. Change the developer team info and Bundle Identifier in ManicEmu Target - Signing & Capabilities
7. Wait for SPM to finish loading. Press CMD+R to run Manic EMU

  **PS.**
- Some Apple services require a Developer Program account to work properly—like App Groups, In-App Purchases, and iCloud. You’ll need to set these up yourself. If you don’t have a Developer Program account, you can remove these services before compiling.
- Some third-party services also need your own API keys to function correctly. You can configure these in the `Cipher` section of `Constant.swift`.   


## Acknowledgements
This project is made possible by the contributions of many outstanding open-source projects:
- Open source emulator cores
- Architectural design of DeltaCore
- Toolchain support from the Libretro community
- Additional dependencies (see `SPM` and `Podfile` listings)

## Links
[<img src="manicemu-badge.png" height="80">](https://manicemu.site) [<img src="discord-badge.png" height="80">](https://discord.gg/qsaTHzknAZ)





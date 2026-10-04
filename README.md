# NexVora CyberRun

**Advanced 3D Cyberpunk Parkour Game for Android**

- **Developer:** Prince AR Abdur Rahman  
- **Publisher:** NexVora Lab’s Ofc  
- **Version:** 1.0.0  
- **Engine:** Godot 4.3+  
- **Platform:** Android (optimized), also runs on desktop for development  

## Overview

NexVora CyberRun is a high-quality 3D parkour game set in a futuristic cyberpunk city. Race across neon-lit rooftops, perform advanced parkour moves (wall-run, slide, grapple, climb), evade AI security drones, complete time trials and missions, and customize your runner.

### Core Features

- Smooth third-person parkour movement
- Wall-running, sliding, climbing, grappling hook
- AI drones and robot enemies
- Mission system + free roam
- Character customization & progression
- Mobile-optimized touch controls
- Cyberpunk visual style (neon cyan / purple)
- Save system, settings, achievements

## Project Structure

```
NexVoraCyberRun/
├── .github/workflows/android.yml   # Automated APK build
├── assets/                         # Models, textures, audio, UI, fonts
├── scenes/
│   ├── player/                     # Player character & camera
│   ├── enemies/                    # Drones, robots
│   ├── levels/                     # City levels / test arenas
│   ├── ui/                         # Menus, HUD, pause
│   └── managers/                   # Autoload scenes if needed
├── scripts/
│   ├── player/                     # Movement, parkour, camera
│   ├── enemies/                    # AI behavior
│   ├── managers/                   # Game, Audio, Save, Input
│   ├── ui/                         # Menu controllers
│   └── utils/                      # Helpers
├── resources/                      # Materials, themes, resources
├── project.godot
├── export_presets.cfg
├── LICENSE
└── README.md
```

## Requirements

- **Godot 4.3** or newer (Mobile renderer recommended)
- Android SDK + NDK (for local export)
- Java JDK 17+
- Git

## Quick Start (Development)

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/NexVoraCyberRun.git
   cd NexVoraCyberRun
   ```

2. Open the project in Godot 4.3+.

3. Press **F5** or the Play button. The main menu will load.

4. For desktop testing use keyboard:
   - WASD – Move
   - Space – Jump
   - Shift – Sprint
   - C – Slide
   - E – Grapple
   - Esc – Pause

5. Touch controls appear automatically on mobile / when emulating touch.

## Exporting to Android (Local)

1. Install Android SDK, NDK, and set up Godot Android export templates.
2. Open **Project → Export**.
3. Select the **Android** preset (or create one).
4. Configure package name: `com.nexvora.cyberrun`
5. Set keystore if you have one (debug works for testing).
6. Click **Export Project** → choose APK.

Recommended export settings:
- Renderer: Mobile
- Architecture: arm64-v8a (primary), armeabi-v7a optional
- Texture compression: ETC2 / ASTC

## Automated Build with GitHub Actions

The repository includes a ready-to-use workflow:

`.github/workflows/android.yml`

### How it works

- Triggers on push to `main` / `master` or manual dispatch.
- Downloads Godot 4.3 headless + Android export templates.
- Sets up Android SDK.
- Exports a release APK.
- Uploads the APK as a GitHub Actions artifact.

### Steps to use

1. Push this project to a GitHub repository.
2. Go to the **Actions** tab.
3. Run the **Build Android APK** workflow (or wait for automatic trigger).
4. Download the APK from the workflow run artifacts.

No secrets are required for a debug-signed APK. For release signing, add your keystore as a GitHub secret and update the workflow.

## Performance Tips (Android)

- Use the **Mobile** renderer.
- Keep draw calls low (combine meshes where possible).
- Use LOD and occlusion culling in larger city levels.
- Limit real-time lights / shadows on low-end devices (Settings menu has quality presets).
- Target 30–60 FPS on mid-range devices.

## Controls (Touch)

Customizable virtual joystick + action buttons appear on screen.  
Layout can be adjusted in Settings → Controls.

## Save System

Progress, settings, unlocked outfits and achievements are saved automatically via `SaveManager` (JSON in `user://`).

## License

See [LICENSE](LICENSE) file.

## Credits

- Developer: Prince AR Abdur Rahman
- Publisher: NexVora Lab’s Ofc
- Engine: Godot Engine (MIT)

---

**NexVora Lab’s Ofc** — Building the future of mobile cyberpunk experiences.

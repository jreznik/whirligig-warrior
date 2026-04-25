# Gemini Project Context: Whirligig Warrior

This project is a high-altitude rotor combat game for the **Playdate** handheld console. It leverages a custom physics engine and procedural audio system specifically designed for the console's unique hardware.

## 🏗 Architectural Overview

*   **Language:** Lua (Playdate SDK).
*   **Rendering:** Sprite-based system with a dedicated `BackgroundSprite` layer (`zIndex: -100`) to ensure 100% visual separation between the environment and active game objects.
*   **Physics:** A semi-realistic vertical flight model where `Lift - Gravity = Vertical Velocity`. Horizontal movement uses momentum and friction.
*   **Audio:** Real-time procedural synthesis for the drone's motor and combat SFX (Kill, Die, Land, Thrust).

## 🎮 Game Rules & Mechanics

### Flight & Control
*   **Rotor Engine (Crank):** The physical crank dictates rotor RPM. High RPM generates lift and turns the blades into a lethal weapon.
*   **Steering (D-Pad):** Horizontal movement is only possible while airborne. 
*   **Thruster (Down):** Applies a strong downward force for rapid diving.
*   **Safe Landing:** Descending onto the ground (`y=211`) with a vertical velocity (`vy`) < 2.0 is a successful landing. Exceeding this speed results in a crash.

### Combat Logic
*   **Lethality:** The drone's blades only destroy enemies if `RPM > 10`.
*   **Vulnerability:** The drone's central pod is always vulnerable to UFO collisions unless a **Shield** is active.
*   **Enemies:**
    *   **Normal UFOs:** Simple descending enemies.
    *   **UFO Waves:** Groups moving in synchronized sine-waves (spawns after 150 points).
    *   **Carrier Ships:** Large ships that deploy standard UFOs (spawns after 300 points).

### The Dreadnought (Boss)
*   **Trigger:** Every 500 points.
*   **Multi-Part:** Consists of a central Hull and 5 destructible Core Modules.
*   **Lethal Hull:** Collision with the ship's hull is fatal. Only hitting the flashing cores with blades is safe.
*   **Progression:** 1st encounter requires 1 core (middle); 2nd requires 3 cores; 3rd+ requires all 5.

### Power-Ups
*   **Shield (S):** 10s invincibility + ground immunity. Flashes in final 2s.
*   **Antigravity (A):** 10s weightless flight + full 8-way D-pad movement.

## 📈 Scoring System

*   **Kill:** +10 points (+50 for Carriers).
*   **Flight:** +10 points for every 10 cumulative seconds in the air.
*   **Landing:** +20 points for every successful soft landing.
*   **Boss:** +100 per core, +500 for total victory.

## 🛠 Development Standards

### Automated Versioning
*   The `buildNumber` in `pdxinfo` is **dynamic**.
*   **Source of Truth:** Total Git commit count (`git rev-list --count HEAD`).
*   **Usage:** Never edit `buildNumber` manually in `pdxinfo`. Use `./build.sh` or the GitHub CI to inject the correct number.

### Asset Management
*   **Procedural Generation:** All sprites (Drone, UFOs, Icons) are generated at runtime in `initAssets()`. 
*   **Visual Style:** 1-bit "Outline" aesthetic. Use `gfx.clear(gfx.kColorClear)` when creating new images to prevent corner artifacts.

### CI/CD Pipeline
*   **.github/workflows/build.yml:** Automatically compiles the project on every push to `main` and creates GitHub Releases for version tags (`v*`).

## 🚀 Swift Start
1.  **Check-out:** `git clone git@github.com:jreznik/whirligig-warrior.git`
2.  **Build:** `./build.sh`
3.  **Run:** `PlaydateSimulator WhirligigWarrior.pdx`

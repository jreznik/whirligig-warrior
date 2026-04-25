# WHIRLIGIG WARRIOR

A tactile action game for the **Playdate** handheld console.

## Overview

In **Whirligig Warrior**, you take control of a clockwork drone in a high-stakes struggle against falling interdimensional monsters. The game centers on a unique, physics-based flight mechanic where your physical interaction with the Playdate's crank is your only engine.

## Gameplay & Mechanics

*   **The Crank is Your Engine:** Your rotor RPM is directly dictated by how fast you spin the crank.
*   **Vertical Strategy:** Gain altitude by cranking forward. Juggle your lift to hover in the "kill zone" or drop quickly to avoid threats.
*   **Blades as a Weapon:** Reach high RPM to turn your rotor into a lethal shredder. Intercept enemies with your spinning blades to destroy them, but protect the vulnerable body of your drone!
*   **Safe Landings:** Gravity is always pulling. Descend slowly to land safely on the ground; free-falling without power will lead to a crash.
*   **Procedural Action:** Enemies spawn with increasing density and speed as your score rises. As you progress, you will encounter:
    *   **UFO Waves:** Synchronized formations moving in complex sine-wave patterns.
    *   **Carrier Ships:** Massive, slow-moving vessels that deploy swarms of standard UFOs. Destroying them grants a large bonus.

### The Dreadnought Boss

Every **500 points**, a massive Mothership known as the **Dreadnought** will descend. 

*   **Weak Points:** The ship is protected by lethal hull plating. You must precisely hit its glowing energy cores with your blades.
*   **Progressive Difficulty:** The Dreadnought learns from your tactics:
    *   **1st Encounter:** Only the central core must be destroyed.
    *   **2nd Encounter:** Three cores must be neutralized.
    *   **3rd+ Encounter:** All five cores must be shredded to claim victory.
*   **Victory:** Defeating the Dreadnought awards a massive score bonus and triggers a victorious fanfare.

### Power-Ups

Once in a while, tactical power-ups will fall from the sky. Watch for the blinking indicators at the top of the screen!

*   **Shield (S):** Grants **10 seconds of invincibility**. Protects against enemy collisions and high-speed ground crashes. The bubble will flash when the shield is about to expire.
*   **Antigravity (A):** Disables gravity for **10 seconds**, allowing for weightless 8-way movement via the D-pad. Use this rare mode to dominate the screen without worrying about lift!

## Controls

| Input | Action |
| :--- | :--- |
| **Crank Forward** | Build RPM / Increase Lift |
| **D-Pad Left/Right** | Steer horizontally (while flying) |
| **D-Pad Down** | Activate Descent Thrusters (while flying) |
| **(A) Button** | Start/Restart Game |

## Development

**Whirligig Warrior** was created in a single design session as a collaboration between human and artificial intelligence.

*   **Designed by:** Jaroslav "Rezza" Reznik
*   **Coded by:** Gemini (via Gemini CLI)

The project focused on exploring the tactile feedback of the Playdate hardware, resulting in a custom physics engine and procedural audio system that reacts in real-time to the player's physical input.

## Technical Details

The game is built using the **Playdate SDK** and Lua. It features:
*   Real-time procedural audio synthesis for motor and combat sounds.
*   Layered 1-bit graphics with a dedicated background sprite system.
*   Persistent high-score tracking.

### Versioning System

Whirligig Warrior uses an automated versioning system based on the Git commit history:
*   **buildNumber:** This value in `pdxinfo` is dynamically set during the build process using the total Git commit count (`git rev-list --count HEAD`).
*   **Continuous Integration:** The project includes a GitHub Action that automatically compiles the game and generates versioned artifacts.
*   **Build Script:** Use `./build.sh` to compile locally. The script will automatically handle the versioning injection without the need for manual file edits.

## License

This project is open-source under the **MIT License**. See the `LICENSE` file for details.

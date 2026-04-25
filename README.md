# WHIRLIGIG WARRIOR

A tactile action game for the **Playdate** handheld console.

## Overview

In **Whirligig Warrior**, you take control of a clockwork drone in a high-stakes struggle against falling interdimensional monsters. The game centers on a unique, physics-based flight mechanic where your physical interaction with the Playdate's crank is your only engine.

## Gameplay & Mechanics

*   **The Crank is Your Engine:** Your rotor RPM is directly dictated by how fast you spin the crank.
*   **Vertical Strategy:** Gain altitude by cranking forward. Juggle your lift to hover in the "kill zone" or drop quickly to avoid threats.
*   **Blades as a Weapon:** Reach high RPM to turn your rotor into a lethal shredder. Intercept enemies with your spinning blades to destroy them, but protect the vulnerable body of your drone!
*   **Safe Landings:** Gravity is always pulling. Descend slowly to land safely on the ground; free-falling without power will lead to a crash.
*   **Procedural Action:** Enemies spawn with increasing density and speed as your score rises, ensuring every run is unique.

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

## License

This project is open-source under the **MIT License**. See the `LICENSE` file for details.

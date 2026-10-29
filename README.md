# Skape: Sky Game

Flying game inspired by Sky: Children of the Light. Played with an ESP32, joystick, potentiometer, and a button. 

![Gameplay demonstration](/readme%20files/b4kx7u.gif) 

## Design Goals

This game takes inspiration from Sky: COTL, but with a different level of interaction. Sky is in a 3d space, but for this project, Skape, I decided to design it as 2D. My goal was to experiment and align my animations with how long the player pushed the joystick, and in which direction. The potentiometer and button are here to add a new level of immersion, and to help capture the vibes of Sky: COTL. 

In Sky, players explore the realms to capture light children, but in my game there will be light stars instead that are part of the game's scoring system.

## Controls

Joystick left/right: Moves horizontally. A stronger sideways push will increase steering speed
Joystick forward: The cape will complete it's full animation if pushed at the maximum, and will only partially ripple if the player is not pushing as hard.
Joystick centered: Player will hover slowly rather than stop.
Potentiometer: Blend between Day, Sunset, and Night.
Red button: Restart the round at any time.

Capturing a light will add a point to the score. 

## Required Components

- ESP32 TTGO T-display
- Joystick
- Potentiometer
- Pushbutton
- Breadboard and jumper wires
- USB data cable and laptop

![alt text](</readme%20files/Screenshot 2026-10-29 at 3.25.10 AM.png>)

## Tutorial for Skape: Sky Game
1. Make sure you have Arduino IDE (with ESP32 board plugin installed) and Processing
2. Assemble your circuits and components using the fritzing diagram above, plugging in your ESP to your machine.
3. Upload controller code by opening SkyGame.ino in Arduino IDE and uploading it to your ESP32.
4. Open SkyGame.pde in Processing
5. Upload all png files in the processing folder: sprite1-6, ref sheet, light, Day, Sunset, Night.
6. Update the port index in the code to match your ESP32 on your machine
7. Run and play!
# Embersand

A real-time strategy game made in GameMaker, and a tribute to the desert strategy games of
the early 90s, *Dune II* above all, in its own world: harvest glowing lumen crystals from
the dunes, build a base on the rock (power, refinery, barracks, motor works, radar,
turrets, walls), train infantry and tanks from three build queues, and beat a computer
opponent that rebuilds its base and attacks in waves. Three missions with briefings from
K-7, a survey drone; two sides to play; three difficulties.

It uses GameMaker's `mp_grid` path finding, runtime tilemaps (a dual-grid tileset so rock
edges are rounded), a shader that paints each side's colours, particle systems for
explosions and smoke, a soft shroud drawn from a one-pixel-per-cell surface, and sound
effects made in code.

Started as v7 of [snake_hangman](https://github.com/spyrostrimis/snake_hangman); continued
here.

## Credits
All names, art and characters are original. Art is drawn in code
(`art_src/make_art.js`: terrain tiles pixel by pixel, everything else as SVG rendered with
sharp; `import_art.js` brings it into the project). Text uses Bahnschrift, a font already
on Windows; nothing is bundled.

This is an unofficial fan tribute; *Dune II* was made by Westwood Studios and now belongs
to Electronic Arts.

## Self-test
Setting `EMBERSAND_TEST=1` (or 2, 3) before starting the game makes it play that mission by
itself at high speed and save screenshots and a log in `%LOCALAPPDATA%\snake_hangman7`.

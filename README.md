# Balance

A real-time strategy game made in GameMaker, and a tribute to the desert strategy games of
the early 90s, *Dune II* above all, in its own world. Ten years after a coup killed the
king called the Peacebringer, his exiled son leads Blue against Red, the coup leader's
regime. Green opportunists sell their help to whoever pays, and a covert order, the
Palatinate, works in the shadows. See [docs/LORE.md](docs/LORE.md).

In the current build you harvest glowing lumen crystals and build a base (power, refinery,
barracks, motor works, radar, turrets, walls). You train infantry and tanks from three
build queues and fight a computer opponent that rebuilds its base and attacks in waves.
There are three missions with briefings from K-7, a survey drone, two playable sides and
three difficulties.

It uses GameMaker's `mp_grid` path finding and runtime tilemaps, including a dual-grid
tileset that rounds the rock edges. A shader paints each side's colours, particle systems
make explosions and smoke, the soft shroud is drawn from a one-pixel-per-cell surface, and
the sound effects are made in code.

## Credits
All names, art and characters are original. Art is drawn in code:
`art_src/make_art.js` draws terrain tiles pixel by pixel and everything else as SVG
rendered with sharp, and `import_art.js` brings it into the project. Text uses Bahnschrift,
a font already on Windows; nothing is bundled.

This is an unofficial fan tribute; *Dune II* was made by Westwood Studios and now belongs
to Electronic Arts.

## Self-test
Set `BALANCE_TEST=1` (or 2, 3) before starting the game, and it plays that mission by
itself at high speed. It saves screenshots and a log in `%LOCALAPPDATA%\Balance`.

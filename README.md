# ASCII Rain

A small, zero-dependency screensaver for the browser: a field of ASCII characters falling across a dark screen. It is meant to feel like a tiny terminal daydream, not a terminal emulator or a data visualizer.

## What it does

- Draws animated character streams on a full-screen HTML canvas.
- Lets you pause or resume the rain and adjust its speed and density.
- Supports keyboard shortcuts: **Space** pauses/resumes, and **R** reshuffles the streams.
- Honors the operating system's reduced-motion preference by starting paused.
- Runs entirely in the browser. It has no backend, analytics, external libraries, or network calls; it does not read local files.

## Run locally

No package installation or build step is needed. Open `index.html` in a modern browser, or serve the folder locally:

```powershell
python -m http.server 8000
```

Then open [http://localhost:8000](http://localhost:8000).

## Deploy with GitHub Pages

1. Open **Settings → Pages**.
2. Under **Build and deployment**, choose **Deploy from a branch**.
3. Select the `main` branch and the `/ (root)` folder, then save.
4. Wait for the Pages build and open the URL GitHub displays in the Pages settings.

The site is static, so the repository root can be served directly; no workflow or build command is required.

## Project structure

```text
index.html   Page structure, styles, controls, and canvas animation
README.md    Project overview, controls, local run, and Pages deployment
```

## Implementation notes

The animation uses the Canvas 2D API and `requestAnimationFrame`. Each column keeps only its current row, fall rate, and density threshold. The canvas scales for high-density displays with a device-pixel-ratio cap of 2; resizing recalculates the columns. A light translucent fill leaves short character trails without storing a frame history. The speed control changes both the frame interval and fall rate; density controls which columns are active.

## Manual checks

- Open the page at desktop and mobile widths; the controls should remain usable.
- Change speed and density and confirm the readouts update.
- Pause/resume with the button and Space; press R to reshuffle.
- Enable reduced motion in the operating system and reload; the animation should start paused.

There is no automated test suite because this is a dependency-free single-page visual experiment.


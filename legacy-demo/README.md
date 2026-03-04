# Legacy Demo

`legacy-demo/` is the legacy Vue + Vite demo kept for side-by-side comparison while the Rails + Inertia app remains the primary application at the repository root.

## Usage

- Install dependencies: `npm ci --prefix legacy-demo`
- Start the demo: `npm run dev --prefix legacy-demo`
- Build the demo: `npm run build --prefix legacy-demo`

## Purpose

- Compare the old demo screens against the Rails + Inertia implementation
- Preserve the pre-integration UI and interaction flow during follow-up fixes
- Avoid using this folder as the source of truth for new feature work

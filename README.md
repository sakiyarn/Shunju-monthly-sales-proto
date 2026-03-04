# S Proto Monthly Sales v1

The repository root now hosts the primary Rails + Inertia application for the monthly sales prototype.

## Primary App

- Install Ruby gems: `bundle install`
- Install frontend dependencies: `npm ci`
- Prepare the database: `bin/rails db:prepare`
- Start the development stack: `bin/dev`

## Checks

- Type check frontend code: `npm run check`
- Build frontend assets: `npm run build`
- Run Ruby style checks: `bin/rubocop`
- Run Rails security scan: `bin/brakeman`
- Run tests: `RAILS_ENV=test bin/rails db:test:prepare test test:system`

## Legacy Demo

The previous standalone Vue + Vite demo is preserved in `legacy-demo/` for side-by-side comparison with the Rails + Inertia implementation.

- Install demo dependencies: `npm ci --prefix legacy-demo`
- Start the demo: `npm run legacy:dev`
- Build the demo: `npm run legacy:build`

## Comparison Workflow

1. Start the primary app with `bin/dev`.
2. Start the legacy demo with `npm run legacy:dev`.
3. Compare the Rails app routes such as `/master` and `/master-data` against the equivalent demo screens.

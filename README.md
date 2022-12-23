# civicly

An SMS-based [civic conversations](http://civicly.us) app.

## Getting started

1. Install Elixir (>= 1.6)
    - On MacOS with Homebrew: `brew update && brew install elixir`
1. Install PostgreSQL (>= 10.2)
    - On MacOS with Homebrew: `brew install postgres`
1. Install the project dependencies: `mix deps.get`
1. Create the project database role: `psql -d postgres -c "CREATE USER civically WITH SUPERUSER CREATEDB PASSWORD 'civically';"`
1. Set up the test database: `mix rebuild_test`
1. Run the tests: `mix test`

# Civically

A marketplace of ideas.

## Getting started

1. Clone the repo: `https://accesstocivically@bitbucket.org/bspatafora/civically.git`
2. Install Elixir (>= 1.6)
    - On MacOS with Homebrew: `brew update && brew install elixir`
3. Install PostgreSQL (>= 10.2)
    - On MacOS with Homebrew: `brew install postgres`
4. Install the project dependencies: `mix deps.get`
5. Create the project database role: `psql -d postgres -c "CREATE USER civically WITH SUPERUSER CREATEDB PASSWORD 'civically';"`
6. Set up the test database: `mix rebuild_test`
7. Run the tests: `mix test`

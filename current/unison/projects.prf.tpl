# Sync ~/projects between machines
root = {{HOME}}/projects
root = ssh://{{PC_USER}}@{{PC_HOST}}/{{REMOTE_HOME}}/projects

auto = true
confirmbigdel = true
terse = false

# Ignore heavy/generated dirs
ignore = Name node_modules
ignore = Name .git
ignore = Name target
ignore = Name dist
ignore = Name build
ignore = Name __pycache__
ignore = Name .cache
ignore = Name .next
ignore = Name .nuxt
ignore = Name .venv
ignore = Name venv

# Ignore env files by default (use pc copy for these)
ignore = Name .env
ignore = Name .env.*

prefer = newer

# Gogh themes cache management

ensure_cache() {
  if [[ ! -f "$GOGH_CACHE" ]]; then
    echo -e "${DIM}Downloading Gogh themes...${RESET}"
    mkdir -p "$(dirname "$GOGH_CACHE")"
    curl -sL "$GOGH_URL" -o "$GOGH_CACHE" || { echo -e "${RED}Download failed${RESET}"; exit 1; }
    local count
    count=$(python3 -c "import json; print(len(json.load(open('$GOGH_CACHE'))))" 2>/dev/null)
    echo -e "${GREEN}Cached $count themes${RESET}"
  fi
}

cmd_update() {
  echo "Updating Gogh themes cache..."
  rm -f "$GOGH_CACHE"
  ensure_cache
}

# Qt6 / KDE Frameworks 6 theme sync.
# Pipeline: env QT_QPA_PLATFORMTHEME=qt6ct → libqt6ct.so (qt6ct-kde fork)
#   - reads ~/.config/qt6ct/qt6ct.conf for non-KDE Qt apps
#   - reads ~/.config/kdeglobals + ~/.local/share/color-schemes/Aurora.colors
#     for KDE Frameworks 6 apps (Dolphin, Kate, Ark, Okular)

mkdir -p "$HOME/.config/qt6ct" "$HOME/.local/share/color-schemes"

# --- qt6ct.conf (generic Qt6 widget palette) ---
cat > "$HOME/.config/qt6ct/qt6ct.conf" << EOF
[Appearance]
custom_palette=true
standard_dialogs=default
style=kvantum

[Palette]
active_colors=#${C[fg]}, #${C[bg_light]}, #${C[bg_highlight]}, #${C[bg_light]}, #${C[fg_muted]}, #${C[fg_dim]}, #${C[fg]}, #${C[fg]}, #${C[fg]}, #${C[bg]}, #${C[bg]}, #${C[border]}, #${C[accent]:-${C[blue]}}, #${C[bg]}, #${C[accent]:-${C[blue]}}, #${C[red]}, #${C[bg_highlight]}, #${C[fg]}, #${C[bg]}, #${C[fg]}, 0.65098
inactive_colors=#${C[fg_dim]}, #${C[bg_light]}, #${C[bg_highlight]}, #${C[bg_light]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_dim]}, #${C[fg_dim]}, #${C[fg_dim]}, #${C[bg]}, #${C[bg]}, #${C[border]}, #${C[accent]:-${C[blue]}}, #${C[bg]}, #${C[accent]:-${C[blue]}}, #${C[red]}, #${C[bg_highlight]}, #${C[fg]}, #${C[bg]}, #${C[fg_dim]}, 0.65098
disabled_colors=#${C[fg_muted]}, #${C[bg]}, #${C[bg_highlight]}, #${C[bg_light]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[fg_muted]}, #${C[bg]}, #${C[bg]}, #${C[border]}, #${C[accent]:-${C[blue]}}, #${C[fg_muted]}, #${C[accent]:-${C[blue]}}, #${C[red]}, #${C[bg_highlight]}, #${C[fg]}, #${C[bg]}, #${C[fg_muted]}, 0.65098

[Fonts]
fixed="${FONT},11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="${FONT},11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
EOF

# --- KColorScheme file (Aurora.colors) — KF6 apps look this up by name ---
# Hex → "R,G,B" decimal helper
hex2rgb() { printf '%d,%d,%d' $((16#${1:0:2})) $((16#${1:2:2})) $((16#${1:4:2})); }

bg_rgb=$(hex2rgb "${C[bg]}")
bg_light_rgb=$(hex2rgb "${C[bg_light]}")
bg_hl_rgb=$(hex2rgb "${C[bg_highlight]}")
fg_rgb=$(hex2rgb "${C[fg]}")
fg_dim_rgb=$(hex2rgb "${C[fg_dim]}")
fg_muted_rgb=$(hex2rgb "${C[fg_muted]}")
border_rgb=$(hex2rgb "${C[border]}")
accent_rgb=$(hex2rgb "${C[accent]:-${C[blue]}}")
red_rgb=$(hex2rgb "${C[red]}")
green_rgb=$(hex2rgb "${C[green]}")
yellow_rgb=$(hex2rgb "${C[yellow]}")

cat > "$HOME/.local/share/color-schemes/Aurora.colors" << EOF
[ColorEffects:Disabled]
Color=${bg_rgb}
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=${bg_light_rgb}
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=${bg_light_rgb}
BackgroundNormal=${bg_light_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${accent_rgb}
ForegroundInactive=${fg_dim_rgb}
ForegroundLink=${accent_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${fg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${accent_rgb}

[Colors:Selection]
BackgroundAlternate=${accent_rgb}
BackgroundNormal=${accent_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${bg_rgb}
ForegroundInactive=${bg_rgb}
ForegroundLink=${bg_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${bg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${bg_rgb}

[Colors:Tooltip]
BackgroundAlternate=${bg_light_rgb}
BackgroundNormal=${bg_light_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${accent_rgb}
ForegroundInactive=${fg_dim_rgb}
ForegroundLink=${accent_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${fg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${accent_rgb}

[Colors:View]
BackgroundAlternate=${bg_light_rgb}
BackgroundNormal=${bg_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${accent_rgb}
ForegroundInactive=${fg_dim_rgb}
ForegroundLink=${accent_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${fg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${accent_rgb}

[Colors:Window]
BackgroundAlternate=${bg_light_rgb}
BackgroundNormal=${bg_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${accent_rgb}
ForegroundInactive=${fg_dim_rgb}
ForegroundLink=${accent_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${fg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${accent_rgb}

[General]
ColorScheme=Aurora
Name=Aurora
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=${bg_rgb}
activeBlend=${bg_light_rgb}
activeForeground=${fg_rgb}
inactiveBackground=${bg_rgb}
inactiveBlend=${bg_light_rgb}
inactiveForeground=${fg_dim_rgb}
EOF

# --- kdeglobals (KF6 entry point — points to Aurora scheme + duplicates colors) ---
cat > "$HOME/.config/kdeglobals" << EOF
[General]
ColorScheme=Aurora
Name=Aurora
shadeSortColumn=true

[Colors:Button]
BackgroundNormal=${bg_light_rgb}
BackgroundAlternate=${bg_light_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${accent_rgb}
ForegroundInactive=${fg_dim_rgb}
ForegroundLink=${accent_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${fg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${accent_rgb}

[Colors:Selection]
BackgroundNormal=${accent_rgb}
BackgroundAlternate=${accent_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundNormal=${bg_rgb}
ForegroundActive=${bg_rgb}
ForegroundInactive=${bg_rgb}
ForegroundLink=${bg_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${bg_rgb}

[Colors:View]
BackgroundNormal=${bg_rgb}
BackgroundAlternate=${bg_light_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${accent_rgb}
ForegroundInactive=${fg_dim_rgb}
ForegroundLink=${accent_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${fg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${accent_rgb}

[Colors:Window]
BackgroundNormal=${bg_rgb}
BackgroundAlternate=${bg_light_rgb}
DecorationFocus=${accent_rgb}
DecorationHover=${accent_rgb}
ForegroundActive=${accent_rgb}
ForegroundInactive=${fg_dim_rgb}
ForegroundLink=${accent_rgb}
ForegroundNegative=${red_rgb}
ForegroundNeutral=${yellow_rgb}
ForegroundNormal=${fg_rgb}
ForegroundPositive=${green_rgb}
ForegroundVisited=${accent_rgb}

[KDE]
contrast=4
EOF

# --- Live-reload running KF6 apps (changeType=0 → Palette) ---
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null

echo -e "    ${GREEN}qt6ct + kdeglobals (Aurora)${RESET}"

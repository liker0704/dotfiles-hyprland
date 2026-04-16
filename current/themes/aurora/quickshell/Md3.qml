pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Material Design 3 tonal palette from matugen.
// Fed by ~/.local/state/quickshell/generated/colors.json (regenerated per wallpaper).
//
// Use alongside Colors: Colors.* = wallust 16 ANSI + our blend-derived base.
//                       Md3.md3.* = MD3 semantic roles (primary, surface_container, ...).
//                       Md3.palette.* = tonal shades (primary10..primary100) for fine states.
//                       Md3.base16.* = matugen's base16 re-map (fallback if wallust absent).

Singleton {
    id: root

    property alias md3: _adapter.md3
    property alias palette: _adapter.palette
    property alias base16: _adapter.base16

    FileView {
        id: _fv
        path: Quickshell.env("HOME") + "/.local/state/quickshell/generated/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadedChanged: if (loaded) reload()

        JsonAdapter {
            id: _adapter

            readonly property Md3 md3: Md3 {}
            readonly property Palette palette: Palette {}
            readonly property Base16 base16: Base16 {}
        }
    }

    // inotifywait on the parent directory — matugen writes via truncate,
    // FileView.watchChanges should pick it up, but belt-and-suspenders
    // in case the compositor misses inotify events on state dirs.
    Process {
        running: true
        command: [
            "inotifywait", "-m", "-q",
            "-e", "close_write,moved_to", "--format", "%f",
            Quickshell.env("HOME") + "/.local/state/quickshell/generated"
        ]
        stdout: SplitParser {
            onRead: data => { if (data.trim() === "colors.json") _fv.reload() }
        }
        onRunningChanged: { if (!running) running = true }
    }

    component Md3: JsonObject {
        property string background: "transparent"
        property string error: "transparent"
        property string error_container: "transparent"
        property string inverse_on_surface: "transparent"
        property string inverse_primary: "transparent"
        property string inverse_surface: "transparent"
        property string on_background: "transparent"
        property string on_error: "transparent"
        property string on_error_container: "transparent"
        property string on_primary: "transparent"
        property string on_primary_container: "transparent"
        property string on_primary_fixed: "transparent"
        property string on_primary_fixed_variant: "transparent"
        property string on_secondary: "transparent"
        property string on_secondary_container: "transparent"
        property string on_secondary_fixed: "transparent"
        property string on_secondary_fixed_variant: "transparent"
        property string on_surface: "transparent"
        property string on_surface_variant: "transparent"
        property string on_tertiary: "transparent"
        property string on_tertiary_container: "transparent"
        property string on_tertiary_fixed: "transparent"
        property string on_tertiary_fixed_variant: "transparent"
        property string outline: "transparent"
        property string outline_variant: "transparent"
        property string primary: "transparent"
        property string primary_container: "transparent"
        property string primary_fixed: "transparent"
        property string primary_fixed_dim: "transparent"
        property string scrim: "transparent"
        property string secondary: "transparent"
        property string secondary_container: "transparent"
        property string secondary_fixed: "transparent"
        property string secondary_fixed_dim: "transparent"
        property string shadow: "transparent"
        property string surface: "transparent"
        property string surface_bright: "transparent"
        property string surface_container: "transparent"
        property string surface_container_high: "transparent"
        property string surface_container_highest: "transparent"
        property string surface_container_low: "transparent"
        property string surface_container_lowest: "transparent"
        property string surface_dim: "transparent"
        property string surface_tint: "transparent"
        property string surface_variant: "transparent"
        property string tertiary: "transparent"
        property string tertiary_container: "transparent"
        property string tertiary_fixed: "transparent"
        property string tertiary_fixed_dim: "transparent"
    }

    component Palette: JsonObject {
        property string primary0: "transparent";   property string primary10: "transparent"
        property string primary20: "transparent";  property string primary30: "transparent"
        property string primary40: "transparent";  property string primary50: "transparent"
        property string primary60: "transparent";  property string primary70: "transparent"
        property string primary80: "transparent";  property string primary90: "transparent"
        property string primary95: "transparent";  property string primary99: "transparent"
        property string primary100: "transparent"

        property string secondary0: "transparent";  property string secondary10: "transparent"
        property string secondary20: "transparent"; property string secondary30: "transparent"
        property string secondary40: "transparent"; property string secondary50: "transparent"
        property string secondary60: "transparent"; property string secondary70: "transparent"
        property string secondary80: "transparent"; property string secondary90: "transparent"
        property string secondary95: "transparent"; property string secondary99: "transparent"
        property string secondary100: "transparent"

        property string tertiary0: "transparent";   property string tertiary10: "transparent"
        property string tertiary20: "transparent";  property string tertiary30: "transparent"
        property string tertiary40: "transparent";  property string tertiary50: "transparent"
        property string tertiary60: "transparent";  property string tertiary70: "transparent"
        property string tertiary80: "transparent";  property string tertiary90: "transparent"
        property string tertiary95: "transparent";  property string tertiary99: "transparent"
        property string tertiary100: "transparent"

        property string neutral0: "transparent";    property string neutral10: "transparent"
        property string neutral20: "transparent";   property string neutral30: "transparent"
        property string neutral40: "transparent";   property string neutral50: "transparent"
        property string neutral60: "transparent";   property string neutral70: "transparent"
        property string neutral80: "transparent";   property string neutral90: "transparent"
        property string neutral95: "transparent";   property string neutral99: "transparent"
        property string neutral100: "transparent"

        property string neutral_variant0: "transparent";  property string neutral_variant10: "transparent"
        property string neutral_variant20: "transparent"; property string neutral_variant30: "transparent"
        property string neutral_variant40: "transparent"; property string neutral_variant50: "transparent"
        property string neutral_variant60: "transparent"; property string neutral_variant70: "transparent"
        property string neutral_variant80: "transparent"; property string neutral_variant90: "transparent"
        property string neutral_variant95: "transparent"; property string neutral_variant99: "transparent"
        property string neutral_variant100: "transparent"

        property string error0: "transparent";   property string error10: "transparent"
        property string error20: "transparent";  property string error30: "transparent"
        property string error40: "transparent";  property string error50: "transparent"
        property string error60: "transparent";  property string error70: "transparent"
        property string error80: "transparent";  property string error90: "transparent"
        property string error95: "transparent";  property string error99: "transparent"
        property string error100: "transparent"
    }

    component Base16: JsonObject {
        property string color0: "transparent"; property string color1: "transparent"
        property string color2: "transparent"; property string color3: "transparent"
        property string color4: "transparent"; property string color5: "transparent"
        property string color6: "transparent"; property string color7: "transparent"
        property string color8: "transparent"; property string color9: "transparent"
        property string color10: "transparent"; property string color11: "transparent"
        property string color12: "transparent"; property string color13: "transparent"
        property string color14: "transparent"; property string color15: "transparent"
    }
}

# System-privileged scripts

These files need to be installed to root-owned locations:

```bash
sudo install -m 0755 focus-mode-helper /usr/local/bin/
sudo install -m 0440 focus-mode.sudoers /etc/sudoers.d/focus-mode
sudo visudo -c  # verify
```

`focus-mode-helper` is invoked by `~/.config/hypr/UserScripts/FocusMode.sh`
via passwordless sudo to modify `/etc/hosts` and Chrome managed policies.
The sudoers drop-in allows only the exact binary path — nothing else gets
passwordless privilege escalation.

## tmux-user.tmpfiles

Install:
```bash
sudo install -m 0644 tmux-user.tmpfiles /etc/tmpfiles.d/tmux-user.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/tmux-user.conf
```

Ensures `/tmp/tmux-1000` is owned by `liker:liker` with `0700` perms on
every boot. Without it, systemd-tmpfiles occasionally created the dir
root-owned and tmux refused to attach with "unsafe permissions" —
breaking every persistent tmux session. The `d` + `Z` combo creates if
missing and re-asserts ownership recursively each tmpfiles run.

Note: hardcoded UID 1000 / user `liker` — adjust if deploying on a system
with a different UID or username.

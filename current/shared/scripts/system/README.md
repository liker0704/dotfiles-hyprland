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

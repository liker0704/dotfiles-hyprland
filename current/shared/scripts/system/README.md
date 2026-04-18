# System-privileged scripts

## focus-mode-helper

```bash
sudo install -m 0755 focus-mode-helper /usr/local/bin/
```

Invoked by `~/.config/hypr/UserScripts/FocusMode.sh` via `sudo` to modify
`/etc/hosts` and Chrome managed policies. The helper validates input —
rejects /etc/hosts lines without the FOCUS-MODE-BLOCK marker and rejects
Chrome policy that isn't valid JSON.

**No NOPASSWD sudoers drop-in is shipped** — every FocusMode toggle
prompts for password. The previous `focus-mode.sudoers` drop-in was
removed for security: any process running as your user could trigger
arbitrary /etc/hosts writes through the helper without authentication.

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

## docker-daemon.json

Install:
```bash
sudo mkdir -p /etc/docker
sudo install -m 0644 docker-daemon.json /etc/docker/daemon.json
sudo systemctl restart docker
```

Disables the **containerd-snapshotter** storage driver (default in Docker
28+/29+), reverts to `overlay2`. On idle systems with the snapshotter
enabled, dockerd constantly scans OCI image layers and burns 20-40% CPU
with no containers running. Switching back to `overlay2` drops idle CPU
to <2%.

Also adds `log-opts` to cap container logs at 10 MB × 3 files — prevents
JSON-file logs from filling disk on long-running containers (e.g.
`assistant` emits 30-sec tmux polling DEBUG that piles up).

Verify after restart:
```bash
docker info | grep -E 'Storage Driver|snapshotter'
# → Storage Driver: overlay2   (NOT io.containerd.snapshotter.v1)
```

## krb5-minimal.conf

Install:
```bash
sudo cp /etc/krb5.conf /etc/krb5.conf.bak
sudo install -m 0644 krb5-minimal.conf /etc/krb5.conf
```

Replaces Arch's default `/etc/krb5.conf` (shipped with MIT example
`default_realm = ATHENA.MIT.EDU`). FreeRDP 3.x's NLA/SPNEGO queries that
non-existent KDC before trying NTLM — connections to non-AD Windows
hosts fail with `Client <user>@ATHENA.MIT.EDU not found in Kerberos
database → SPNEGO failed → ERRCONNECT_AUTHENTICATION_FAILED`.

Empty libdefaults (no default_realm, no realms block) makes Kerberos
fail-fast, SPNEGO falls through to NTLM in milliseconds.
See FreeRDP#10138 + arch krb5 package bug.

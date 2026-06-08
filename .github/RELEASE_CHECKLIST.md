# RELEASE CHECKLIST

## 1. Build the ZIP

Check out the commit you're shipping with a clean working tree, then:

```sh
./scripts/release.sh --release
```

Builds the zip from tracked files, strips the `~DEV` tag, points config at the production server, and names it `BalatroMultiplayer.zip` — produced in `dist/`, ready to upload.

## 2. Upload the ZIP

1. Attach `BalatroMultiplayer.zip` to the GitHub release.
2. Upload it to [balatromp.com's releases page](https://balatromp.com/admin/releases):
   - Steamodded version = the version ranked requires
   - Lovely version = the version ranked requires
   - Branch = `main`
   - Version = the version from `Multiplayer.json`, without the `~DEV` tag

## 3. Upload the server files

Ship a copy for each OS so players don't have to go digging.

- **Server unchanged:** re-upload `server-win.exe`, `server-macos`, and
  `server-linux` from the previous release.
- **Server changed:** build it locally and upload the three files from `build/`.

## 4. After release

- On `main`, bump `Multiplayer.json` by one patch, keeping `~DEV`
  (`0.2.18~DEV` → `0.2.19~DEV`).
- If the required Steamodded or Lovely version changed, update `README.md` and
  `CONTRIBUTING.md` to match.

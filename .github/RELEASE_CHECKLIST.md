# RELEASE CHECKLIST

## Creating the main ZIP
*(This ensures we keep the DEV tag on the source code and ensures BMM and balatromp.com don't break, since they rely on the "BalatroMultiplayer.zip" file existing for each release)*
1. Download the source code.
2. Uncompress the source code and open `Multiplayer.json` to remove "~DEV" from the version tag.
3. Recompress the source code, ensuring to recomopress from the files instead of the outer folder, and name it exactly "BalatroMultiplayer.zip".
4. Upload `BalatroMultiplayer.zip` with the release.

## Uploading the server files
*(We upload the server files for each OS with every release so that people don't have to go digging for these files)*
- If the server **has not** changed since last update then simply download the `server-win.exe`, `server-macos`, and `server-linux` files from the previous releasee and upload them with the new release.
- If the server **has** changed since last update then run the build script for the server files locally, and upload the `server-win.exe`, `server-macos`, and `server-linux` files created in the `build` folder.

## After release
- Increase the version in the `Multiplayer.json` of main branch to be one patch version above the previous release, and ensure the "~DEV" tag still exists.
  - Eg. "0.2.18~DEV" -> "0.2.19~DEV", Or if a higher version like 1.0 was released then it should become "1.0.1~DEV"
- If the recommended Steamodded or Lovely was updated then be sure to update `README.md` and `CONTRIBUTING.md` with the correct versions.

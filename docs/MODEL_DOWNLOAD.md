# 3D Model Download

The application expects the licensed model at:

`assets/models/anime_bikini_girl.glb`

## Source and attribution

- Asset: Anime Bikini Girl 3D Model
- Author: ZeroVert
- License: CC BY (as supplied with the project asset)
- Original source: https://downloadforfree.gumroad.com/l/free-anime-bikini-girl-3d-model
- Project release asset: `v1.0-models/anime_bikini_girl.glb`

The project workflow intentionally does **not** scrape or automate the Gumroad landing page. It downloads only the GitHub Release asset.

## Release setup

Create or open the GitHub Release tagged `v1.0-models` and upload the legitimately obtained file with this exact name:

`anime_bikini_girl.glb`

The workflow downloads it with:

`gh release download v1.0-models --pattern "anime_bikini_girl.glb" --dir assets/models/`

GitHub CLI supports selecting release assets by tag and glob pattern. citeturn0search0

## Manual contributor workflow

1. Obtain the model from its original source under its stated license.
2. Confirm that the downloaded file is actually GLB, not an HTML landing page.
3. Create/update the `v1.0-models` GitHub Release.
4. Upload the file as `anime_bikini_girl.glb`.
5. Run **Actions → Download 3D Model → Run workflow**.
6. The workflow verifies:
   - file size is greater than 1 MB;
   - first four bytes are `676c5446` (glTF binary magic);
   - the system `file` command reports a binary/GLB-compatible type.
7. The verified file is uploaded as an Actions artifact and committed to `assets/models/`.

## If the release does not exist

The workflow stops deliberately and prints the exact release URL and manual upload instructions. It does not substitute a fake file, a Gumroad HTML page, or an unverified third-party asset.

## Important

Do not commit an HTML page renamed to `.glb`. Do not change the expected filename without updating the workflow and application asset declaration.

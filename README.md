# BANANA BLAST

A first-person, landscape iPhone arcade prototype built with Swift, SpriteKit, and XcodeGen.

## Current prototype
- First-person-style jungle view with banana and hand visible.
- Monkeys appear directly ahead on the path.
- Tap the scene to start.
- Tap/drag in the play area to aim.
- Tap THROW to launch a banana.
- Tap SPECIAL to launch a larger-scoring banana.
- Score and wave counter; spawn rate and approach speed increase over time.

## Build on GitHub
1. Upload the contents of this folder to a GitHub repository named `BANANA-BLAST`.
2. Open the repository's **Actions** tab.
3. Select **Build BANANA BLAST** and tap **Run workflow** (or push a commit).
4. Open the completed run and download the `BANANA-BLAST-unsigned` artifact.

## Important: signing
The workflow deliberately creates an **unsigned app artifact**, not an installable signed IPA. Your Apple Developer signing certificate and provisioning profile will be configured in a later step. Do not expect the unsigned artifact to install directly on iPhone.

## Notes
This is the first playable foundation, not the finished feature list. Coins, unlockables, additional enemy types, boss fights, saved high scores, music, sound effects, and polished sprite artwork are planned follow-up work.

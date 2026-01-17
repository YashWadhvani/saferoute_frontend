Why this exists

If your Flutter project is on one drive (for example D:) but your Pub cache is on another (for example C:), Gradle can fail on Windows with errors about "this and base files have different roots" when compiling Android plugin sources. That happens because Gradle (or Java's Path.relativize) sometimes expects paths to share the same root drive.

What this helper does

- Creates a project-local `.pub-cache` folder on the same drive as your project (in the project root).
- Sets the `PUB_CACHE` environment variable for the current PowerShell session to point at that project-local cache.
- Removes a stale `build\flutter_plugin_android_lifecycle` folder (a common culprit).
- Runs `flutter pub get` to populate the local cache.

How to use

1. Open PowerShell.
2. From the repository root run:

```powershell
# Run script (no repair); it will set PUB_CACHE for this session and run pub get
.\scripts\fix_pub_cache_on_windows.ps1

# Or, to force a full pub cache repair (slower):
.\scripts\fix_pub_cache_on_windows.ps1 -Repair
```

3. Re-open your IDE (or restart the IDE) so it picks up the new environment variable (or permanently set the environment variable in Windows to the project-local path).

Make PUB_CACHE permanent (optional)

- To make the new pub cache location permanent for your account, set the user environment variable `PUB_CACHE` to the absolute path of the project-local `.pub-cache` directory.
- After changing environment variables you must restart your IDE/terminal.

Why this is safe

This avoids cross-drive path problems by ensuring both the project build output and the pub cache live on the same drive. It does not modify any source code or plugin versions.

If you'd prefer I can instead:

- Move your project to the same drive as the global pub cache,
- Or delete the `build/` plugin copies automatically on each build (I can add a Gradle pre-build task),
- Or remove `profile_scree.dart` permanently rather than re-exporting it.

Tell me which option you prefer and I can implement it.

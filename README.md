# PackageMiscreatedModRepo

Template Repo

Contains GitHub Actions that Package a Repo containing a miscreated Mod to a pak file and attaches it for each new release

NOTE: your mods files must be inside the Source/GameSDK dir
(also contains basic github issue templates, just remove these if you dont need them)

the resulting filenames are based on the repo name, so a for a  repo called: MyCoolMod
everytime you create and publish a new release, it will have: MyCoolMod-editor-build.pak & MyCoolMod-workshop-build.pak automatically
attached to your release after a few moments.

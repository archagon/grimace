# Technical Notes

## Quarantine Flag

Using default project settings, directories modified using the app have the `com.apple.quarantine` flag set.
When examining URL resource values under `quarantinePropertiesKey`, the quarantine type is listed as `LSQuarantineTypeSandboxed`. 
I believe this is due to some sort of app sandboxing + drag & drop interaction.
Setting the `LSFileQuarantineEnabled` flag manually in Info.plist does not fix the issue.
Ultimately, the only solution I could find was to turn off app sandboxing. Oh well.

Resources:
* <https://www.macscripter.net/t/droplet-handling-zip-files-differently-from-other-files/70647>
* <https://eclecticlight.co/2019/04/26/🎗-quarantine-documents/>
* <https://developer.apple.com/forums/thread/725487>
* <https://redcanary.com/blog/threat-detection/gatekeeper/>
* <https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/TP40009250-SW8>
* <https://stackoverflow.com/questions/9544874/how-can-i-stop-my-app-from-setting-the-quarantine-bit>

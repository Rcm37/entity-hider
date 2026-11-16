# Entity Hider

Hide selected players, NPCs, familiars, pets, and Necromancy conjures to reduce visual clutter.

Requires PrettyUI. Use the ribbon panel for hide toggles and right-click options. Open Plugin Hub settings to manage custom lists and presets.

## Hide options

The plugin starts enabled with all hide filters off.

| Option | Effect |
| --- | --- |
| Hide Yourself | Hides your own player model. |
| Hide Other Players | Hides other player models. |
| Hide NPCs | Hides NPCs except fishing spots, familiars, pets, and supported Necromancy conjures. |
| Hide Conjures | Hides supported Necromancy conjures. |
| Hide All Familiars / Pets | Hides familiars and pets, including magic carpet and K'ril Psssutsaroth pets. |
| Hide Drake Familiars | Hides supported drake pets. |
| Hide Spiders | Hides NPCs and familiars with "spider" in their names. |

Any matching filter hides an entity. A custom list can hide something excluded by a general toggle.

## Custom lists and presets

Plugin Hub settings provide separate lists for player names, NPC names, and familiar names. Separate names with commas. Names match in full and ignore capitalization. Use **Hide Yourself** to hide your own character.

Choose from five presets and rename them with **Preset name**. Each preset saves its own name lists and hidden NPC IDs. Changes save automatically.

Enable **Include global toggles in presets** to save hide toggles with each preset too. This is off by default. **Enable Plugin** and right-click keybind preferences always apply across presets.

## Right-click hiding

Right-click a player or NPC and choose **Hide <name> (Entity Hider)** to add its name to the selected preset.

Enable **Require keybind for Hide options** to show Hide entries only while the chosen keys are held. Click the keybind field, hold one or two keys, then release. Modifier combinations such as **Ctrl + Shift** and **Ctrl + Alt** are supported. The default is **Ctrl + Shift**. Right-click the field to reset it.

**Undo Last Hide** removes the latest right-click addition. Other filters may still keep that entity hidden. Undo history clears when switching presets, characters, or settings storage, and when the plugin reloads.

## Advanced ID hiding

Expand **Advanced Settings** to enter comma-separated NPC config IDs. This can hide nameless NPCs and familiars. The list below shows names alongside saved IDs where available. Remove an ID from the field to unhide it.

Cosmetic familiar overrides cannot be targeted separately by their appearance IDs at this time.

## Settings storage

Settings apply to all characters by default and persist between sessions.

For separate character settings, grant **trackingAccess** permission in Plugin Hub, log in, and enable **Use player-specific settings**. Turning it off restores shared settings.

Character settings are unavailable while logged out or without permission. They become available again after login and permission are restored.

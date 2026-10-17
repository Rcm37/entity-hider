# Entity Hider

A RuneScape plugin for reducing visual clutter by hiding selected players, NPCs, familiars, pets, and Necromancy conjures.

## Setup

Requires **PrettyUI** (dependency ID `6398181`). Load the `entity-hider` directory as a development plugin with PrettyUI available. The plugin requests no additional permissions.

Open its ribbon panel for hide toggles and right-click options. Open its settings through **Plugin Hub** to edit saved name lists. Settings persist between sessions.

## Hide options

The plugin is enabled by default, with all hide filters initially off.

| Option | Effect |
| --- | --- |
| Hide Yourself | Hides your own player model. |
| Hide Other Players | Hides other player models; your own model uses its separate toggle. |
| Hide NPCs | Hides NPCs except fishing spots, familiars/pets, and the conjures handled by the separate filter. |
| Hide Conjures | Hides supported Necromancy conjures. |
| Hide All Familiars / Pets | Hides NPCs marked as familiars by the game. |
| Hide Drake Familiars | Hides the drake pets covered by the plugin's ID list. |

Filters combine: any matching filter hides an NPC. Custom name lists can also hide fishing spots and conjures excluded by the general NPC toggle. Spider coverage is available in the separate **Arachnophobia** plugin.

## Custom names and right-click hiding

Plugin Hub settings provide separate comma-separated lists for **player names**, **NPC names**, and **familiar names**. Matching uses complete names, ignores case, and trims surrounding spaces. An NPC name entry applies to every matching NPC, rather than just one spawn. Your own player model is controlled by **Hide Yourself**.

Right-click a player or NPC and choose **Hide <name> (Entity Hider)** to add its name to the appropriate list. Enable **Require Ctrl + Shift for Hide options** to show these menu entries only while both keys are held.

The ribbon panel shows the most recently hidden name. **Undo Last Hide** removes that latest right-click addition; this undo history lasts for the current plugin session. Other matching filters may still keep the entity hidden. Remove older entries directly from the saved name lists.

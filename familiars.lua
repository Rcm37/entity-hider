local Familiars = {}

-- These cosmetic pets are not marked as familiars by the game.
local overrides = {
    [id.NPC.MENAPHOS_MAGIC_CARPET_IMPERIAL] = true,
    [id.NPC.MENAPHOS_MAGIC_CARPET_IMPERIAL_POH] = true,
    [id.NPC.MENAPHOS_MAGIC_CARPET_MERCHANT] = true,
    [id.NPC.MENAPHOS_MAGIC_CARPET_MERCHANT_POH] = true,
    [id.NPC.MENAPHOS_MAGIC_CARPET_SLAVE] = true,
    [id.NPC.MENAPHOS_MAGIC_CARPET_SLAVE_POH] = true,
    [id.NPC.MENAPHOS_MAGIC_CARPET_PORT] = true,
    [id.NPC.MENAPHOS_MAGIC_CARPET_PORT_POH] = true,
    [id.NPC.MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_BASIC] = true,
    [id.NPC.MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_BASIC_POH] = true,
    [id.NPC.MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_GOLD] = true,
    [id.NPC.MENAPHOS_GOLDEN_PATH_MAGIC_CARPET_GOLD_POH] = true,
}

function Familiars.IsFamiliar(npc)
    return npc.config.isFamiliar or overrides[npc.config.id] == true
end

return Familiars

-- Title-screen art for the PvP logo ("PLAYER vs PLAYER"). The layered title swap itself is
-- driven by MPAPI via the `title` config in register_mod (see core.lua), mirroring how Speed
-- sets up its title. These atlases supply the two layers:
--   base  = the two PLAYER wordmarks (top-left + bottom-right), composited into one image
--   extra = the colourful "VS" accent, drawn behind the base
SMODS.Atlas({ key = 'pvp_title_base', path = 'pvp_title_base.png', px = 333, py = 216 })
SMODS.Atlas({ key = 'pvp_title_extra', path = 'pvp_title_extra.png', px = 333, py = 216 })

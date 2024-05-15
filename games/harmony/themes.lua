------------------------------------------------------------------------
--  HARMONY THEMES
------------------------------------------------------------------------
--
--  Copyright (C) 2006-2017 Andrew Apted
--  Copyright (C)      2008 Sam Trenholme
--  Copyright (C) 2019-2020 MsrSgtShooterPerson
--  --Adapted from MsrSgtShooterPerson's Doom themes.lua file
    --Into a singular theme (Castle) for Heretic
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2,
--  of the License, or (at your option) any later version.
--
------------------------------------------------------------------------

HARMONY.THEMES =
{
  DEFAULTS =
  {
    slump_config = 
    [[
      ;
      ; Sample SLIGE config file. (Semicolon starts a comment to end of line.)
      ;
      ; This is the SLIGE.CFG as shipped with SLIGE itself.  It contains a
      ; description of the default SLIGE configuration, as hardwired into
      ; the program.  So having this file in the current directory under the
      ; name SLIGE.CFG should produce exactly the same effect as not having
      ; any config file at all.  You can use this file as a base to build
      ; your own config files on (but if you do, you should change these
      ; comments; otherwise they'll be WRONG!).
      ;
      ; Dave Chess, dmchess@aol.com, chess@us.ibm.com

      ; The current implementation ignores everything before the
      ; [THEMES] line also, but that will change.

      [THEMES]        ; Anything after a ; is, remember, a comment

      ; We have three themes, one secret.  They should all be declared
      ; before any textures or flats or anything else.  The only valid
      ; modifier is "secret", which says that that theme should only be
      ; used on secret levels.  There should be at least one "secret"
      ; theme.

	  Theme AMZ ; Amazon Base

      ; Flats and textures and constructs and stuff are also in the [THEMES] section

      ; Textures are described by "Texture NAME <attributes>".  Obvious
      ; attributes include "wall", "door", and so on.  Some subtler ones:
      ;
      ; "core <theme>" means that this texture should be common in that theme.
      ; "comp <theme>" means that this texture is compatible with that theme, but
      ;    not to be used all that often.
      ; "switch <texture>" means "the given texture is a good switch to use in
      ;    a room that has walls of the current texture"
      ; "isswitch" means "the current texture is a good switch to use on any
      ;    wall in a room with a compatible theme"
      ; "subtle <texture>" means "the given texture is a subtle variant of the
      ;    current texture, suitable for hinting at secrets"
      ; "yhint N" means "when using a vertical misalignment to hint at
      ;    a secret door in a wall of this texture, use a y-offset of N".  If
      ;    N is zero, it means "this wall is too visually complex to hint via a
      ;    y-misalignment at all; hint some other way".  If no "yhint" is given,
      ;    the value 5 is used.
      ;  "noDoom2" means that the texture does not exist in the usual DOOM II
      ;    IWAD.  "noDoom0" means it doesn't exist in the DOOM 1.2 IWAD, and
      ;    "noDoom1" means it's not in the DOOM 1.666 or 1.89 IWAD.  If none
      ;    of these are specified, the texture is assumed to be in all.
      ;  "size <width> <height>" gives the size of the texture.  You can leave
      ;    this out if the height is 128, and the width is some reasonable
      ;    divisor of 256 (except for doors, where you should give the real
      ;    width so SLIGE can make them look nice).
  
	  ; Amazon Base switches
	  Texture SW1MET2 size 64 128 isswitch comp AMZ
	  
	  ; Amazon Base walls
	  Texture PANCASE2 size 64 128 wall core AMZ

	  ; And the lift texture
	  Texture METAL2 size 64 128 lift comp AMZ

	  ; Doors of all kinds.  "size" gives the width and height of the texture,
	  ; and "locked" means that it's a good texture to use on a door that only
	  ; opens with a switch, not a touch.
	  Texture BIGDOOR2 size 128 128 door comp AMZ
	  Texture 0DOORS1 size 64 128 door comp AMZ

	  ; Amazon Base exit switches
	  Texture SW1MET2 size 64 128 exitswitch comp AMZ

	  ; Lights, suitable for lighting recesses and stuff.
	  Texture PANBORD2 size 16 128 light comp AMZ
	  Texture PANBORD1 size 32 128 light comp AMZ

	  ; "Plaques", suitable for wall consoles and paintings and pillars and stuff.
	  ; "vtiles" means that it's OK to pile one on top of another, as when
	  ;    making the big central pillar in an arena.
	  ; "half_plaque" means that the upper half of this texture can be used
	  ;    by itself, as well as the whole thing.
	  Texture ROCK1 size 64 128 plaque vtiles comp AMZ

	  ; Gratings
	  Texture 1LIF1 size 128 128 grating comp AMZ
	  Texture 0LASER4 size 64 8 grating comp AMZ

	  ; Colors (suitable for marking key-locked things)
	  Texture 2LITER3 size 32 128 red comp AMZ
	  Texture 2LITER2 size 32 128 yellow comp AMZ
	  Texture 2LITER1 size 32 128 blue comp AMZ

	  ; Step kickplates
	  Texture STEPLAD1 size 64 16 step comp AMZ

	  ; "Doorjambs"
	  Texture DOORTRAK size 8 128 jamb comp AMZ

	  ; Support textures, used in various places
	  Texture 2BLOK2 size 64 128 support comp AMZ

	  ; Bunch of things for outside patios (no themes applied here)
	  Texture 0ORANJE size 64 128 outside
	  Texture ZZWOLF5 size 128 128 outside

	  ; Misc
	  Texture 0ROOD02 size 64 128 error

	  ; Now the flats.  Keywords should all be pretty obvious...   *8)

	  ; Teleport-gate floors
	  Flat STEP1 gate comp AMZ

	  ; Amazon Base floors and ceilings
	  Flat SLIME15 floor comp AMZ
	  Flat FLOOR4_8 ceiling comp AMZ

	  ; and nukage
	  Flat SLIME09 nukage comp AMZ
	  Flat SLIME01 nukage red comp AMZ

	  ; Floors for outside areas not yet mentioned
	  Flat RROCK04 outside

	  ; These are the defaults, but we'll list them anyway.
	  Flat FWATER1 water
	  Flat F_SKY1 sky

	  ; Constructs: computers and crates and stuff that stand around in rooms
	  ; This is pretty complex!  Fool with it at your peril.

	  ; Family 1 is crates of various sizes and kinds
	  Construct family 1 height 128 comp AMZ
	  top CEIL4_1
	  Primary TEKBRON1 width 64

	  ; Load the hardwired monster and object and so on data (required in
	  ; this version of SLIGE; don't remove this!)
	  Hardwired1

	  ; Say which lamps we like in which themes, and where barrels are allowed
	  ; Information like which Doom version each object is in, and which ones
	  ; cast light, and which ones explode, is still hardwired.
	  Thing 2028 comp AMZ ; floor lamp

    ; and that's it!
    ]]
  },


  amazon_base =
  {
    slump_config = 
    [[
      ;
      ; Sample SLIGE config file. (Semicolon starts a comment to end of line.)
      ;
      ; This is the SLIGE.CFG as shipped with SLIGE itself.  It contains a
      ; description of the default SLIGE configuration, as hardwired into
      ; the program.  So having this file in the current directory under the
      ; name SLIGE.CFG should produce exactly the same effect as not having
      ; any config file at all.  You can use this file as a base to build
      ; your own config files on (but if you do, you should change these
      ; comments; otherwise they'll be WRONG!).
      ;
      ; Dave Chess, dmchess@aol.com, chess@us.ibm.com

      ; The current implementation ignores everything before the
      ; [THEMES] line also, but that will change.

      [THEMES]        ; Anything after a ; is, remember, a comment

      ; We have three themes, one secret.  They should all be declared
      ; before any textures or flats or anything else.  The only valid
      ; modifier is "secret", which says that that theme should only be
      ; used on secret levels.  There should be at least one "secret"
      ; theme.

	  Theme AMZ ; Amazon Base

      ; Flats and textures and constructs and stuff are also in the [THEMES] section

      ; Textures are described by "Texture NAME <attributes>".  Obvious
      ; attributes include "wall", "door", and so on.  Some subtler ones:
      ;
      ; "core <theme>" means that this texture should be common in that theme.
      ; "comp <theme>" means that this texture is compatible with that theme, but
      ;    not to be used all that often.
      ; "switch <texture>" means "the given texture is a good switch to use in
      ;    a room that has walls of the current texture"
      ; "isswitch" means "the current texture is a good switch to use on any
      ;    wall in a room with a compatible theme"
      ; "subtle <texture>" means "the given texture is a subtle variant of the
      ;    current texture, suitable for hinting at secrets"
      ; "yhint N" means "when using a vertical misalignment to hint at
      ;    a secret door in a wall of this texture, use a y-offset of N".  If
      ;    N is zero, it means "this wall is too visually complex to hint via a
      ;    y-misalignment at all; hint some other way".  If no "yhint" is given,
      ;    the value 5 is used.
      ;  "noDoom2" means that the texture does not exist in the usual DOOM II
      ;    IWAD.  "noDoom0" means it doesn't exist in the DOOM 1.2 IWAD, and
      ;    "noDoom1" means it's not in the DOOM 1.666 or 1.89 IWAD.  If none
      ;    of these are specified, the texture is assumed to be in all.
      ;  "size <width> <height>" gives the size of the texture.  You can leave
      ;    this out if the height is 128, and the width is some reasonable
      ;    divisor of 256 (except for doors, where you should give the real
      ;    width so SLIGE can make them look nice).
  
	  ; Amazon Base switches
	  Texture SW1MET2 size 64 128 isswitch comp AMZ
	  
	  ; Amazon Base walls
	  Texture PANCASE2 size 64 128 wall core AMZ

	  ; And the lift texture
	  Texture METAL2 size 64 128 lift comp AMZ

	  ; Doors of all kinds.  "size" gives the width and height of the texture,
	  ; and "locked" means that it's a good texture to use on a door that only
	  ; opens with a switch, not a touch.
	  Texture BIGDOOR2 size 128 128 door comp AMZ
	  Texture 0DOORS1 size 64 128 door comp AMZ

	  ; Amazon Base exit switches
	  Texture SW1MET2 size 64 128 exitswitch comp AMZ

	  ; Lights, suitable for lighting recesses and stuff.
	  Texture PANBORD2 size 16 128 light comp AMZ
	  Texture PANBORD1 size 32 128 light comp AMZ

	  ; "Plaques", suitable for wall consoles and paintings and pillars and stuff.
	  ; "vtiles" means that it's OK to pile one on top of another, as when
	  ;    making the big central pillar in an arena.
	  ; "half_plaque" means that the upper half of this texture can be used
	  ;    by itself, as well as the whole thing.
	  Texture ROCK1 size 64 128 plaque vtiles comp AMZ

	  ; Gratings
	  Texture 1LIF1 size 128 128 grating comp AMZ
	  Texture 0LASER4 size 64 8 grating comp AMZ

	  ; Colors (suitable for marking key-locked things)
	  Texture 2LITER3 size 32 128 red comp AMZ
	  Texture 2LITER2 size 32 128 yellow comp AMZ
	  Texture 2LITER1 size 32 128 blue comp AMZ

	  ; Step kickplates
	  Texture STEPLAD1 size 64 16 step comp AMZ

	  ; "Doorjambs"
	  Texture DOORTRAK size 8 128 jamb comp AMZ

	  ; Support textures, used in various places
	  Texture 2BLOK2 size 64 128 support comp AMZ

	  ; Bunch of things for outside patios (no themes applied here)
	  Texture 0ORANJE size 64 128 outside
	  Texture ZZWOLF5 size 128 128 outside

	  ; Misc
	  Texture 0ROOD02 size 64 128 error

	  ; Now the flats.  Keywords should all be pretty obvious...   *8)

	  ; Teleport-gate floors
	  Flat STEP1 gate comp AMZ

	  ; Amazon Base floors and ceilings
	  Flat SLIME15 floor comp AMZ
	  Flat FLOOR4_8 ceiling comp AMZ

	  ; and nukage
	  Flat SLIME09 nukage comp AMZ
	  Flat SLIME01 nukage red comp AMZ

	  ; Floors for outside areas not yet mentioned
	  Flat RROCK04 outside

	  ; These are the defaults, but we'll list them anyway.
	  Flat FWATER1 water
	  Flat F_SKY1 sky

	  ; Constructs: computers and crates and stuff that stand around in rooms
	  ; This is pretty complex!  Fool with it at your peril.

	  ; Family 1 is crates of various sizes and kinds
	  Construct family 1 height 128 comp AMZ
	  top CEIL4_1
	  Primary TEKBRON1 width 64

	  ; Load the hardwired monster and object and so on data (required in
	  ; this version of SLIGE; don't remove this!)
	  Hardwired1

	  ; Say which lamps we like in which themes, and where barrels are allowed
	  ; Information like which Doom version each object is in, and which ones
	  ; cast light, and which ones explode, is still hardwired.
	  Thing 2028 comp AMZ ; floor lamp

    ; and that's it!
    ]]
  },

}

function HARMONY.slump_setup()
  if ob_match_game({game = {harmony=1}}) then
    if OB_CONFIG.theme == "default" then
      PARAM.slump_config = HARMONY.THEMES.DEFAULTS.slump_config
    elseif OB_CONFIG.theme == "jumble" then
      local possible_configs = {}
      for _,tab in pairs(HARMONY.THEMES) do
        if tab.slump_config then
          table.insert(possible_configs, tab.slump_config)
        end
      end
      PARAM.slump_config = rand.pick(possible_configs)
    elseif HARMONY.THEMES[OB_CONFIG.theme].slump_config then
      PARAM.slump_config = HARMONY.THEMES[OB_CONFIG.theme].slump_config
    else
      PARAM.slump_config = HARMONY.THEMES.DEFAULTS.slump_config
    end
  end
end

------------------------------------------------------------------------


OB_THEMES["amazon_base"] =
{
  label = _("Amazon Base"),
  game = "harmony",
  name_class = "GOTHIC",
  mixed_prob = 50,
}


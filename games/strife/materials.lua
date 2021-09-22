------------------------------------------------------------------------
--  STRIFE MATERIALS
------------------------------------------------------------------------
--
--  Copyright (C) 2006-2016 Andrew Apted
--  Copyright (C) 2011-2012 Jared Blackburn
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2,
--  of the License, or (at your option) any later version.
--
------------------------------------------------------------------------

STRIFE.LIQUIDS =
{
  water = { mat="F_WATR01", light_add=16, special=0 },
}


STRIFE.MATERIALS =
{
  -- special materials --
  _DEFAULT = { t="CONCRT01", f="F_CONCRP" },
  _ERROR = { t="BIGSTN02", f="P_SPLATR" },
  _SKY   = { t="BIGSTN01", f="F_SKY001" },

 -- materials for generic prefab set --  
 _SBARS = { t="RAIL01", f="XX" }, -- Short bars, i.e. railings
 _SBARS2 = { t="RAIL03", f="XX" },
 _MBARS = { t="GRATE04", f="XX" }, -- Medium bars, i.e. barred windows
 _TBARS = { t="GRATE02", f="XX" }, -- Tall bars, i.e. cage/jail bars
 
 _CRATE   = { t="BOXCOM01",  f="F_MBOXTP" }, -- Crate/box
 _CRATE2  = { t="BOXWOD02", f="F_WBOXTP" },
 _CRATWID = { t="BOXWOD03",  f="F_WBOXTP" }, -- Wide crates
 
 _WATER   = { t="WATR01", f="F_WATR01" }, -- "Standing water", sorta
 _WTRFALL = { t="WATR01", f="F_VWATR2" }, -- "Flowing water", sorta
   
 _DOOR  = { t="DORWL01", f="F_UNDOOR" }, -- Open says me
 _DOOR2 = { t="DORWS02", f="F_UNDOOR"},
 _DORRAIL = { t="DORTRK02", f="F_UNDOOR"}, -- Inner door slider thingys
 
 _NPIC    = { t="BRNSCN02", f="XX"}, -- Narrow (non-tiling) pic box insert, 64 pixels wide
 _NPIC2    = { t="BRNSCN01", f="XX"},
 _NPIC3    = { t="BRNSCN03", f="XX"},
 
 _MPIC    = { t="BANR02", f="XX"}, -- Medium (or tiling) pic box insert, 128 pixels wide
 _MPIC2    = { t="BANR04", f="XX"},
 _MPIC3    = { t="BANR09", f="XX"},
 _MPIC4    = { t="REBFLAG", f="XX"},
 _MPIC5    = { t="BANR05", f="XX"},
 _MPIC6    = { t="GODSCRN1", f="XX"},
 _MPIC7    = { t="GODSCRN2", f="XX"},
 
 _WPIC    = { t="GLASS03", f="XX"}, -- Wide (or tiling) pic box insert, 256 pixels wide
 _WPIC2    = { t="GLASS11", f="XX"},
 _WPIC3    = { t="GLASS17", f="XX"},
 
 _KEYTRM1 = { t="WINDW03", f="XX" }, -- Trim for locked door, Key 1
 _KEYTRM2 = { t="WINDW02", f="XX" }, -- Trim for locked door, Key 2
 _KEYTRM3 = { t="WINDW04", f="XX" }, -- Trim for locked door, Key 3
 
 _EXITDR1 = { t="DORTKS01", f="F_UNDOOR" }, -- Exit door
 _EXITSW1  = { t="SWEXIT01", f="F_CONCRP" }, -- Exit switch
 _EXITRM1  = { t="CONCRT01", f="F_CONCRP" }, -- Exit switch
 
 _STRUCT = {t="CONCRT01", f="F_CONCRP"}, -- "Structural" texture (window trim, beams, other areas where a window/floor flat just isn't always right)

 _SWITCH  = { t="SWPALM01", f="F_CONCRP" }, -- Wall/general purpose swtich
 _SWITCH2  = { t="SWLITE01", f="F_CONCRP" },
 
 _TELE = { t="CONCRT01", f="F_TELE1" }, -- Teleporter

  -- textures --

  BRKGRY01 = { t="BRKGRY01", f="F_BRKTOP" },
  BRKGRY17 = { t="BRKGRY17", f="F_BRKTOP" },
  WALCAV01 = { t="WALCAV01", f="F_CAVE01" },
  DORWS02  = { t="DORWS02", f="F_PLYWOD" },
  DORTRK02 = { t="DORTRK02", f="F_PLYWOD" },
  WOOD08   = { t="WOOD08", f="F_PLYWOD" },

  -- flats --

  F_BRKTOP = { t="BRKGRY01", f="F_BRKTOP" },
  F_CAVE01 = { t="WALCAV01", f="F_CAVE01" },

  -- liquids --
  F_WATR01 = { f="F_WATR01", t="WATR01" },

  -- rails --
  RAIL01 = { t="RAIL01", rail_h=32}, -- Short bars, i.e. railings
  RAIL03 = { t="RAIL03", rail_h=32},
  GRATE04 = { t="GRATE04", rail_h=64}, -- Medium bars, i.e. barred windows
  GRATE02 = { t="GRATE02", rail_h=128 }, 

}


------------------------------------------------------------------------

STRIFE.PREFAB_FIELDS =
{
  -- TODO : compatibility with DOOM prefabs
}


STRIFE.SKIN_DEFAULTS =
{
}


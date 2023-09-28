//------------------------------------------------------------------------
//  ARCHIVE Handling : ZIP files
//------------------------------------------------------------------------
//
//  OBSIDIAN Level Maker
//
//  Copyright (C) 2021-2022 The OBSIDIAN Team
//  Copyright (C) 2009-2017 Andrew Apted
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//------------------------------------------------------------------------

#ifndef LIB_ZIP_H_
#define LIB_ZIP_H_

#include <filesystem>

#include "sys_type.h"

/* ZIP writing */

bool ZIPF_OpenWrite(const std::filesystem::path &filename);
bool ZIPF_AddFile(const std::filesystem::path &filename, std::filesystem::path directory);
bool ZIPF_AddMem(std::string name, byte *data, size_t length);
void ZIPF_CloseWrite();

#endif

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab

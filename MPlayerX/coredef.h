/*
 * MPlayerX - coredef.h
 *
 * Copyright (C) 2009 Zongyao QU
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// 指定两种arch的mplayer路径时所用的key
#define kI386Key		(@"i386")
#define kX86_64Key		(@"x86_64")

typedef enum
{
	kSubFileNameRuleExactMatch = 0,
	kSubFileNameRuleContain = 1,
	kSubFileNameRuleAny = 2
} SUBFILE_NAMERULE;

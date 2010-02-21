/*
 * MPlayerX - coredef_private.h
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

#import "coredef.h"

#define GetRealVolume(x)		(0.01*(x)*(x))

// mplayer通信所用的command的字符串
#define kMPCTogglePauseCmd		(@"pause\n")
#define kMPCFrameStepCmd		(@"frame_step\n")
#define kMPCSubSelectCmd		(@"sub_select\n")
#define kMPCKeyEventCmd			(@"key_down_event")

#define kMPCGetPropertyPreFix	(@"get_property")
#define kMPCSetPropertyPreFix	(@"set_property")
#define kMPCSetPropertyPreFixPauseKeep	(@"pausing_keep_force set_property")

////////////////////////////////////////////////////////////////////
// 没有ID结尾的是 命令字符串 和 属性字符串 有可能是公用的
#define kMPCTimePos				(@"time_pos")
#define kMPCOsdLevel			(@"osdlevel")
#define kMPCSpeed				(@"speed")
#define kMPCChapter				(@"chapter")
#define kMPCPercentPos			(@"percent_pos")
#define kMPCVolume				(@"volume")
#define kMPCAudioBalance		(@"balance")
#define kMPCMute				(@"mute")
#define kMPCAudioDelay			(@"audio_delay")
#define kMPCSwitchAudio			(@"switch_audio")
#define kMPCSub					(@"sub")
#define kMPCSubDelay			(@"sub_delay")
#define kMPCSubPos				(@"sub_pos")
#define kMPCSubScale			(@"sub_scale")
#define kMPCSubLoad				(@"sub_load")

// 有ID结尾的是 只用来做属性字符串的
#define kMPCLengthID			(@"LENGTH")
#define kMPCSeekableID			(@"SEEKABLE")
#define kMPCSubInfosID			(@"MPXSUBNAMES")
#define kMPCSubInfoAppendID		(@"MPXSUBFILEADD")
#define kMPCCachingPercentID	(@"CACHING")
#define kMPCPlayBackStartedID	(@"PBST")

#define kKVOPropertyKeyPathState	(@"state")
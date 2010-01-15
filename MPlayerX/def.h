/*
 * MPlayerX - def.h
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

// UserDefaults定义
#define kUDKeyVolume				(@"volume")
#define kUDKeyOnTopMode				(@"OnTopMode")
#define kUDKeyCtrlUIAutoHideTime	(@"CtrlUIAutoHideTime")
#define kUDKeySpeedStep				(@"SpeedStepIncre")
#define kUDKeySeekStepLR			(@"SeekStepTimeLR")
#define kUDKeySeekStepUB			(@"SeekStepTimeUB")
#define kUDKeyVolumeStep			(@"VolumeStep")
#define kUDKeyAutoPlayNext			(@"AutoPlayNext")
#define kUDKeySubFontPath			(@"SubFontPath")
#define kUDKeySnapshotSavePath		(@"SnapshotSavePath")
#define kUDKeyStartByFullScreen		(@"StartByFullScreen")
#define kUDKeySubDelayStepTime		(@"SubDelayStepTime")
#define kUDKeyAudioDelayStepTime	(@"AudioDelayStepTime")
#define kUDKeyPrefer64bitMPlayer	(@"Prefer64bitMPlayer")
#define kUDKeyEnableMultiThread		(@"EnableMultiThread")
#define kUDKeySubScale				(@"SubScale")
#define kUDKeySubScaleStepValue		(@"SubScaleStepValue")
#define kUDKeySwitchTimeHintPressOnAbusolute	(@"TimeHintPrsOnAbs")
#define kUDKeyQuitOnClose			(@"QuitOnClose")
#define kUDKeySwitchTimeTextPressOnRemain		(@"TimeTextPrsOnRemain")
#define kUDKeySubFontColor			(@"SubFontColor")
#define kUDKeySubFontBorderColor	(@"SubFontBorderColor")
#define kUDKeyCtrlUIBackGroundAlpha	(@"CtrlUIBackGroundAlpha")
#define kUDKeyForceIndex			(@"ForceIndex")
#define kUDKeySubFileNameRule		(@"SubFileNameRule")
#define kUDKeyDTSPassThrough		(@"DTSPassThrough")
#define kUDKeyAC3PassThrough		(@"AC3PassThrough")

#define kUDKeyDebugEnableOpenURL	(@"DebugEnableOpenURL")
#define kUDKeySelectedPrefView		(@"SelectedPrefView")
#define kUDKeyHelpURL				(@"HelpURL")

#define kSCMSwitchTimeHintKeyModifierMask	(NSFunctionKeyMask)

#define kSCMVolumeUpKeyEquivalent		(@"=")
#define kSCMVolumeDownKeyEquivalent		(@"-")
#define kSCMSwitchAudioKeyEquivalent	(@"a")
#define kSCMSwitchSubKeyEquivalent		(@"s")
#define kSCMSnapShotKeyEquivalent		(@"S")
#define kSCMMuteKeyEquivalent			(@"m")
#define kSCMPlayPauseKeyEquivalent		(@" ")
#define kSCMFullScrnKeyEquivalent		(@"f")
#define kSCMFillScrnKeyEquivalent		(@"F")
#define kSCMAcceControlKeyEquivalent	(@"c")

#define kSCMSubScaleIncreaseKeyEquivalent					(@"=")
#define kSCMSubScaleIncreaseKeyEquivalentModifierFlagMask	(NSCommandKeyMask)
#define kSCMSubScaleDecreaseKeyEquivalent					(@"-")
#define kSCMSubScaleDecreaseKeyEquivalentModifierFlagMask	(NSCommandKeyMask)

#define kSCMPlayFromLastStoppedKeyEquivalent					(@"c")
#define kSCMPlayFromLastStoppedKeyEquivalentModifierFlagMask	(NSShiftKeyMask)

#define kSCMDragSubPosModifierFlagMask			(NSCommandKeyMask)
#define kSCMDragAudioBalanceModifierFlagMask	(NSAlternateKeyMask)
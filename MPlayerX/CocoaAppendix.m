/*
 * MPlayerX - CocoaAppendix.m
 *
 * Copyright (C) 2009 Zongyao QU
 * 
 * MPlayerX is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * MPlayerX is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with MPlayerX; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "CocoaAppendix.h"

@implementation NSColor (MPXAdditional)
-(uint32) convertToHex
{
	NSColor *col = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	return ((((uint32)(255 * [col redComponent]))  <<24) + 
			(((uint32)(255 * [col greenComponent]))<<16) + 
			(((uint32)(255 * [col blueComponent])) <<8)  +
			((uint32)(255 * (1-[col alphaComponent]))));
}
@end

@implementation NSMenu (CharsetListAppend)

-(void) appendCharsetList
{
	NSMenuItem *mItem;
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Unicode (UTF-8)"];
	[mItem setTag:kCFStringEncodingUTF8];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Unicode (UTF-16BE)"];
	[mItem setTag:kCFStringEncodingUTF16BE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Unicode (UTF-16LE)"];
	[mItem setTag:kCFStringEncodingUTF16LE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Unicode (UTF-32BE)"];
	[mItem setTag:kCFStringEncodingUTF32BE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Unicode (UTF-32LE)"];
	[mItem setTag:kCFStringEncodingUTF32LE];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Arabic (ISO 8859-6)"];
	[mItem setTag:kCFStringEncodingISOLatinArabic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Arabic (Windows-1256)"];
	[mItem setTag:kCFStringEncodingWindowsArabic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Arabic (Mac)"];
	[mItem setTag:kCFStringEncodingMacArabic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Baltic (ISO 8859-4)"];
	[mItem setTag:kCFStringEncodingISOLatin4];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Baltic (ISO 8859-13)"];
	[mItem setTag:kCFStringEncodingISOLatin7];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Baltic (Windows-1257)"];
	[mItem setTag:kCFStringEncodingWindowsBalticRim];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Celtic (ISO 8859-14)"];
	[mItem setTag:kCFStringEncodingISOLatin8];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Celtic (Mac)"];
	[mItem setTag:kCFStringEncodingMacCeltic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Central Europe (ISO 8859-2)"];
	[mItem setTag:kCFStringEncodingISOLatin2];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Central Europe (ISO 8859-16)"];
	[mItem setTag:kCFStringEncodingISOLatin10];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Central Europe (Windows-1250)"];
	[mItem setTag:kCFStringEncodingWindowsLatin2];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Central Europe (Mac)"];
	[mItem setTag:kCFStringEncodingMacCentralEurRoman];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Simplified (GB18030)"];
	[mItem setTag:kCFStringEncodingGB_18030_2000];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Simplified (ISO 2022)"];
	[mItem setTag:kCFStringEncodingISO_2022_CN];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Simplified (EUC)"];
	[mItem setTag:kCFStringEncodingEUC_CN];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Simplified (Windows-936)"];
	[mItem setTag:kCFStringEncodingDOSChineseSimplif];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Simplified (Mac)"];
	[mItem setTag:kCFStringEncodingMacChineseSimp];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Traditional (Big5)"];
	[mItem setTag:kCFStringEncodingBig5];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Traditional (Big5 HKSCS)"];
	[mItem setTag:kCFStringEncodingBig5_HKSCS_1999];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Traditional (EUC)"];
	[mItem setTag:kCFStringEncodingEUC_TW];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Traditional (Windows-950)"];
	[mItem setTag:kCFStringEncodingDOSChineseTrad];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Chinese Traditional (Mac)"];
	[mItem setTag:kCFStringEncodingMacChineseTrad];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Cyrillic (ISO 8859-5)"];
	[mItem setTag:kCFStringEncodingISOLatinCyrillic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Cyrillic (Windows-1251)"];
	[mItem setTag:kCFStringEncodingISOLatinCyrillic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Cyrillic (Mac)"];
	[mItem setTag:kCFStringEncodingMacCyrillic];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Cyrillic (KOI8-R)"];
	[mItem setTag:kCFStringEncodingKOI8_R];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Cyrillic (KOI8-U)"];
	[mItem setTag:kCFStringEncodingKOI8_U];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Greek (ISO 8859-7)"];
	[mItem setTag:kCFStringEncodingISOLatinGreek];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Greek (Windows-1253)"];
	[mItem setTag:kCFStringEncodingWindowsGreek];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Greek (Mac)"];
	[mItem setTag:kCFStringEncodingMacGreek];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Hebrew (ISO 8859-8)"];
	[mItem setTag:kCFStringEncodingISOLatinHebrew];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Hebrew (Windows-1255)"];
	[mItem setTag:kCFStringEncodingWindowsHebrew];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Hebrew (Mac)"];
	[mItem setTag:kCFStringEncodingMacHebrew];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Japanese (Shift-JIS)"];
	[mItem setTag:kCFStringEncodingShiftJIS];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Japanese (ISO 2022)"];
	[mItem setTag:kCFStringEncodingISO_2022_JP];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Japanese (EUC)"];
	[mItem setTag:kCFStringEncodingEUC_JP];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Japanese (Windows-932)"];
	[mItem setTag:kCFStringEncodingDOSJapanese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Japanese (Mac)"];
	[mItem setTag:kCFStringEncodingMacJapanese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Korean (ISO 2022)"];
	[mItem setTag:kCFStringEncodingISO_2022_KR];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Korean (EUC)"];
	[mItem setTag:kCFStringEncodingEUC_KR];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Korean (Windows-949)"];
	[mItem setTag:kCFStringEncodingDOSKorean];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Korean (Mac)"];
	[mItem setTag:kCFStringEncodingMacKorean];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"South Europe (ISO 8859-3)"];
	[mItem setTag:kCFStringEncodingISOLatin3];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Thai (ISO 8859-11)"];
	[mItem setTag:kCFStringEncodingISOLatinThai];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Thai (Windows-874/TIS-620)"];
	[mItem setTag:kCFStringEncodingDOSThai];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Thai (Mac)"];
	[mItem setTag:kCFStringEncodingMacThai];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Turkish (ISO 8859-9)"];
	[mItem setTag:kCFStringEncodingISOLatin5];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Turkish (Windows-1254)"];
	[mItem setTag:kCFStringEncodingWindowsLatin5];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Turkish (Mac)"];
	[mItem setTag:kCFStringEncodingMacTurkish];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Vietnamese (Windows-1258)"];
	[mItem setTag:kCFStringEncodingWindowsVietnamese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Vietnamese (Mac)"];
	[mItem setTag:kCFStringEncodingMacVietnamese];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	[self addItem:[NSMenuItem separatorItem]];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Western Europe (ISO 8859-1)"];
	[mItem setTag:kCFStringEncodingISOLatin1];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Western Europe (ISO 8859-15)"];
	[mItem setTag:kCFStringEncodingISOLatin9];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Western Europe (Windows-1252)"];
	[mItem setTag:kCFStringEncodingWindowsLatin1];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];
	
	mItem = [[NSMenuItem alloc] init];
	[mItem setTitle:@"Western Europe (Mac)"];
	[mItem setTag:kCFStringEncodingMacRoman];
	[mItem setEnabled:YES];
	[self addItem:mItem];
	[mItem release];	
}
@end

/*
 * MPlayerX - VideoTunerController.m
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

#import "def.h"
#import "VideoTunerController.h"
#import <Quartz/Quartz.h>

#define kCIInputNoiseLevelKey	(@"inputNoiseLevel")
#define kCIInputPowerKey		(@"inputPower")

#define kCILayerBrightnessKeyPath		(@"filters.colorFilter.inputBrightness")
#define kCILayerSaturationKeyPath		(@"filters.colorFilter.inputSaturation")
#define kCILayerContrastKeyPath			(@"filters.colorFilter.inputContrast")
#define kCILayerNoiseLevelKeyPath		(@"filters.nrFilter.inputNoiseLevel")
#define kCILayerSharpnesKeyPath			(@"filters.nrFilter.inputSharpness")
#define kCILayerGammaKeyPath			(@"filters.gammaFilter.inputPower")

@implementation VideoTunerController

-(id) init
{
	if (self = [super init]) {
		nibLoaded = NO;
		
		// 设置name是为了能够通过keyPath访问filter
		// 但是残念，因为layer的filters是NSArray，无法实现通过name的binding
		colorFilter = [[CIFilter filterWithName:@"CIColorControls"] retain];
		[colorFilter setName:@"colorFilter"];

		nrFilter = [[CIFilter filterWithName:@"CINoiseReduction"] retain];
		[nrFilter setName:@"nrFilter"];
		
		gammaFilter = [[CIFilter filterWithName:@"CIGammaAdjust"] retain];
		[gammaFilter setName:@"gammaFilter"];
		
		[self resetFilters:self];
		layer = nil;
	}
	return self;
}

-(void) dealloc
{	
	[colorFilter release];
	[nrFilter release];
	[gammaFilter release];
	
	[super dealloc];
}

-(void) awakeFromNib
{
	if (!nibLoaded) {
		[menuVTPanel setKeyEquivalent:kSCMVideoTunerPanelKeyEquivalent];
		[menuVTPanel setKeyEquivalentModifierMask:kSCMVideoTunerPanelKeyEquivalentModifierFlagMask];
	}
}

-(IBAction)showUI:(id)sender
{
	if (!nibLoaded) {
		nibLoaded = YES;
		[NSBundle loadNibNamed:@"VideoTuner" owner:self];
		
		[[sliderBrightness cell] setRepresentedObject:kCILayerBrightnessKeyPath];
		[[sliderSaturation cell] setRepresentedObject:kCILayerSaturationKeyPath];
		[[sliderContrast cell] setRepresentedObject:kCILayerContrastKeyPath];
		[[sliderNR cell] setRepresentedObject:kCILayerNoiseLevelKeyPath];
		[[sliderSharpness cell] setRepresentedObject:kCILayerSharpnesKeyPath];
		[[sliderGamma cell] setRepresentedObject:kCILayerGammaKeyPath];
		
		NSDictionary *dict;

		dict = [[colorFilter attributes] objectForKey:kCIInputBrightnessKey];
		[sliderBrightness setMinValue:[[dict objectForKey:kCIAttributeSliderMin] doubleValue]];
		[sliderBrightness setMaxValue:[[dict objectForKey:kCIAttributeSliderMax] doubleValue]];
		
		dict = [[colorFilter attributes] objectForKey:kCIInputSaturationKey];
		[sliderSaturation setMinValue:[[dict objectForKey:kCIAttributeSliderMin] doubleValue]];
		[sliderSaturation setMaxValue:[[dict objectForKey:kCIAttributeSliderMax] doubleValue]];
		
		dict = [[colorFilter attributes] objectForKey:kCIInputContrastKey];
		[sliderContrast setMinValue:[[dict objectForKey:kCIAttributeSliderMin] doubleValue]];
		[sliderContrast setMaxValue:[[dict objectForKey:kCIAttributeSliderMax] doubleValue]];
		
		dict = [[nrFilter attributes] objectForKey:kCIInputNoiseLevelKey];
		[sliderNR setMinValue:[[dict objectForKey:kCIAttributeSliderMin] doubleValue]];
		[sliderNR setMaxValue:[[dict objectForKey:kCIAttributeSliderMax] doubleValue]];
		
		dict = [[nrFilter attributes] objectForKey:kCIInputSharpnessKey];
		[sliderSharpness setMinValue:[[dict objectForKey:kCIAttributeSliderMin] doubleValue]];
		[sliderSharpness setMaxValue:[[dict objectForKey:kCIAttributeSliderMax] doubleValue]];
		
		dict = [[gammaFilter attributes] objectForKey:kCIInputPowerKey];
		[sliderGamma setMinValue:[[dict objectForKey:kCIAttributeSliderMin] doubleValue]];
		[sliderGamma setMaxValue:[[dict objectForKey:kCIAttributeSliderMax] doubleValue]];
				
		[self resetFilters:nil];
	}

	[VTWin makeKeyAndOrderFront:self];
}

-(void) resetFilters:(id)sender
{
	NSDictionary *attr;
	
	attr = [colorFilter attributes];
	[colorFilter setValue:[[attr objectForKey:kCIInputBrightnessKey] objectForKey:kCIAttributeIdentity]
			   forKeyPath:kCIInputBrightnessKey];
	[colorFilter setValue:[[attr objectForKey:kCIInputSaturationKey] objectForKey:kCIAttributeIdentity]
			   forKeyPath:kCIInputSaturationKey];
	[colorFilter setValue:[[attr objectForKey:kCIInputContrastKey] objectForKey:kCIAttributeIdentity]
			   forKeyPath:kCIInputContrastKey];
	
	attr = [nrFilter attributes];
	[nrFilter setValue:[[attr objectForKey:kCIInputNoiseLevelKey] objectForKey:kCIAttributeIdentity]
			forKeyPath:kCIInputNoiseLevelKey];
	[nrFilter setValue:[[attr objectForKey:kCIInputSharpnessKey] objectForKey:kCIAttributeIdentity]
			forKeyPath:kCIInputSharpnessKey];

	attr = [gammaFilter attributes];
	[gammaFilter setValue:[[attr objectForKey:kCIInputPowerKey] objectForKey:kCIAttributeIdentity]
			   forKeyPath:kCIInputPowerKey];
	
	if (nibLoaded) {
		[sliderBrightness setDoubleValue:[[colorFilter valueForKeyPath:kCIInputBrightnessKey] doubleValue]];
		[sliderSaturation setDoubleValue:[[colorFilter valueForKeyPath:kCIInputSaturationKey] doubleValue]];
		[sliderContrast setDoubleValue:[[colorFilter valueForKeyPath:kCIInputContrastKey] doubleValue]];
		[sliderNR setDoubleValue:[[nrFilter valueForKeyPath:kCIInputNoiseLevelKey] doubleValue]];
		[sliderSharpness setDoubleValue:[[nrFilter valueForKeyPath:kCIInputSharpnessKey] doubleValue]];
		[sliderGamma setDoubleValue:[[gammaFilter valueForKeyPath:kCIInputPowerKey] doubleValue]];
	}
	
	if (layer) {
		[layer setValue:[colorFilter valueForKeyPath:kCIInputBrightnessKey] forKeyPath:kCILayerBrightnessKeyPath];
		[layer setValue:[colorFilter valueForKeyPath:kCIInputSaturationKey] forKeyPath:kCILayerSaturationKeyPath];
		[layer setValue:[colorFilter valueForKeyPath:kCIInputContrastKey] forKeyPath:kCILayerContrastKeyPath];
		[layer setValue:[nrFilter valueForKeyPath:kCIInputNoiseLevelKey] forKeyPath:kCILayerNoiseLevelKeyPath];
		[layer setValue:[nrFilter valueForKeyPath:kCIInputSharpnessKey] forKeyPath:kCILayerSharpnesKeyPath];
		[layer setValue:[gammaFilter valueForKeyPath:kCIInputPowerKey] forKeyPath:kCILayerGammaKeyPath];
	}
}

-(IBAction) setFilterParameters:(id)sender
{
	if (layer) {
		[layer setValue:[NSNumber numberWithDouble:[sender doubleValue]] forKeyPath:[[sender cell] representedObject]];
		//NSLog(@"%@=%f", [[sender cell] representedObject], [sender doubleValue]);
	}
}

-(void) setLayer:(CALayer*)l
{
	if (layer) {
		[layer setFilters:nil];
	}
	layer = l;
	if (layer) {
		[layer setFilters:[NSArray arrayWithObjects:gammaFilter, colorFilter, nrFilter, nil]];
	}
}
@end

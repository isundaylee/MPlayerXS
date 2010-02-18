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

#define kCIStepBase				(100000.0)

#define kCIInputNoiseLevelKey	(@"inputNoiseLevel")
#define kCIInputPowerKey		(@"inputPower")

#define kCILayerBrightnessKeyPath		(@"filters.colorFilter.inputBrightness")
#define kCILayerSaturationKeyPath		(@"filters.colorFilter.inputSaturation")
#define kCILayerContrastKeyPath			(@"filters.colorFilter.inputContrast")
#define kCILayerNoiseLevelKeyPath		(@"filters.nrFilter.inputNoiseLevel")
#define kCILayerSharpnesKeyPath			(@"filters.nrFilter.inputSharpness")
#define kCILayerGammaKeyPath			(@"filters.gammaFilter.inputPower")

#define kCILayerFilterEnabled			(@"enabled")

@implementation VideoTunerController

+(void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:0.02], kUDKeyVideoTunerStepValue,
					   nil]];
}

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
		
		layer = nil;
		[self resetFilters:self];
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

		[[brInc cell] setRepresentedObject:sliderBrightness];
		[[brDec cell] setRepresentedObject:sliderBrightness];
		[[satInc cell] setRepresentedObject:sliderSaturation];
		[[satDec cell] setRepresentedObject:sliderSaturation];
		[[conInc cell] setRepresentedObject:sliderContrast];
		[[conDec cell] setRepresentedObject:sliderContrast];
		[[nrInc cell] setRepresentedObject:sliderNR];
		[[nrDec cell] setRepresentedObject:sliderNR];
		[[shpInc cell] setRepresentedObject:sliderSharpness];
		[[shpDec cell] setRepresentedObject:sliderSharpness];
		[[gmInc cell] setRepresentedObject:sliderGamma];
		[[gmDec cell] setRepresentedObject:sliderGamma];
		
		NSDictionary *dict;
		double step, max, min, stepRatio;
		
		stepRatio = [[NSUserDefaults standardUserDefaults] floatForKey:kUDKeyVideoTunerStepValue];
		
		dict = [[colorFilter attributes] objectForKey:kCIInputBrightnessKey];
		min = [[dict objectForKey:kCIAttributeSliderMin] doubleValue];
		max = [[dict objectForKey:kCIAttributeSliderMax] doubleValue];
		step = (max - min) * stepRatio;
		[sliderBrightness setMinValue:min];
		[sliderBrightness setMaxValue:max];
		[brInc setTag:((NSInteger)( step*kCIStepBase))];
		[brDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		dict = [[colorFilter attributes] objectForKey:kCIInputSaturationKey];
		min = [[dict objectForKey:kCIAttributeSliderMin] doubleValue];
		max = [[dict objectForKey:kCIAttributeSliderMax] doubleValue];
		step = (max - min) * stepRatio;
		[sliderSaturation setMinValue:min];
		[sliderSaturation setMaxValue:max];
		[satInc setTag:((NSInteger)( step*kCIStepBase))];
		[satDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		dict = [[colorFilter attributes] objectForKey:kCIInputContrastKey];
		min = [[dict objectForKey:kCIAttributeSliderMin] doubleValue];
		max = [[dict objectForKey:kCIAttributeSliderMax] doubleValue];
		step = (max - min) * stepRatio;
		[sliderContrast setMinValue:min];
		[sliderContrast setMaxValue:max];
		[conInc setTag:((NSInteger)( step*kCIStepBase))];
		[conDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		dict = [[nrFilter attributes] objectForKey:kCIInputNoiseLevelKey];
		min = [[dict objectForKey:kCIAttributeSliderMin] doubleValue];
		max = [[dict objectForKey:kCIAttributeSliderMax] doubleValue];
		step = (max - min) * stepRatio;
		[sliderNR setMinValue:min];
		[sliderNR setMaxValue:max];
		[nrInc setTag:((NSInteger)( step*kCIStepBase))];
		[nrDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		dict = [[nrFilter attributes] objectForKey:kCIInputSharpnessKey];
		min = [[dict objectForKey:kCIAttributeSliderMin] doubleValue];
		max = [[dict objectForKey:kCIAttributeSliderMax] doubleValue];
		step = (max - min) * stepRatio;
		[sliderSharpness setMinValue:min];
		[sliderSharpness setMaxValue:max];
		[shpInc setTag:((NSInteger)( step*kCIStepBase))];
		[shpDec setTag:((NSInteger)(-step*kCIStepBase))];
		
		dict = [[gammaFilter attributes] objectForKey:kCIInputPowerKey];
		min = [[dict objectForKey:kCIAttributeSliderMin] doubleValue];
		max = [[dict objectForKey:kCIAttributeSliderMax] doubleValue];
		step = (max - min) * stepRatio;
		[sliderGamma setMinValue:min];
		[sliderGamma setMaxValue:max];
		[gmInc setTag:((NSInteger)( step*kCIStepBase))];
		[gmDec setTag:((NSInteger)(-step*kCIStepBase))];
				
		[self resetFilters:nil];
		
		[VTWin setLevel:NSMainMenuWindowLevel];
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
	
	[colorFilter setEnabled:NO];
	[nrFilter setEnabled:NO];
	[gammaFilter setEnabled:NO];

	if (nibLoaded) {
		[sliderBrightness setDoubleValue:[[colorFilter valueForKeyPath:kCIInputBrightnessKey] doubleValue]];
		[sliderSaturation setDoubleValue:[[colorFilter valueForKeyPath:kCIInputSaturationKey] doubleValue]];
		[sliderContrast setDoubleValue:[[colorFilter valueForKeyPath:kCIInputContrastKey] doubleValue]];
		[sliderNR setDoubleValue:[[nrFilter valueForKeyPath:kCIInputNoiseLevelKey] doubleValue]];
		[sliderSharpness setDoubleValue:[[nrFilter valueForKeyPath:kCIInputSharpnessKey] doubleValue]];
		[sliderGamma setDoubleValue:[[gammaFilter valueForKeyPath:kCIInputPowerKey] doubleValue]];
	}
	
	if (layer) {
		// 实现Lazy loading
		layer.filters = nil;
	}
}

-(IBAction) setFilterParameters:(id)sender
{
	if (layer) {
		// Lazy loading
		if (!layer.filters) {
			[layer setFilters:[NSArray arrayWithObjects:gammaFilter, colorFilter, nrFilter, nil]];
		}
		
		NSString *keyPath = [[sender cell] representedObject];
		NSString *enaStr = [[keyPath stringByDeletingPathExtension] stringByAppendingPathExtension:kCILayerFilterEnabled];
		
		if (![[layer valueForKeyPath:enaStr] boolValue]) {
			[layer setValue:[NSNumber numberWithBool:YES] forKeyPath:enaStr];
		}

		[layer setValue:[NSNumber numberWithDouble:[sender doubleValue]] forKeyPath:keyPath];
		//NSLog(@"%@=%f", [[sender cell] representedObject], [sender doubleValue]);
	}
}

-(IBAction) stepFilterParameters:(id)sender
{
	// 得到Slider
	NSSlider *obj = [[sender cell] representedObject];
	
	[obj setFloatValue:[obj floatValue] + (((float)[sender tag])/kCIStepBase)];
	[self setFilterParameters:obj];
}

-(void) setLayer:(CALayer*)l
{
	if (layer) {
		[layer setFilters:nil];
	}
	layer = l;
}
@end

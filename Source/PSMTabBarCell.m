//
//  PSMTabBarCell.m
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "PSMTabStyle.h"
#import "PSMProgressIndicator.h"
#import "PSMTabDragAssistant.h"

@interface PSMTabBarControl (Private)

- (void)update;

@end

@interface PSMTabBarCell (/*Private*/)

- (NSRect)_drawingRectForBounds:(NSRect)theRect;
- (NSRect)_titleRectForBounds:(NSRect)theRect;
- (NSRect)_iconRectForBounds:(NSRect)theRect;
- (NSRect)_largeImageRectForBounds:(NSRect)theRect;
- (NSRect)_indicatorRectForBounds:(NSRect)theRect;
- (NSSize)_objectCounterSize;
- (NSRect)_objectCounterRectForBounds:(NSRect)theRect;
- (NSRect)_closeButtonRectForBounds:(NSRect)theRect;
- (CGFloat)_minimumWidthOfCell;
- (CGFloat)_desiredWidthOfCell;
- (NSImage *)_closeButtonImageOfType:(PSMCloseButtonImageType)type;
- (void)_drawWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawBezelWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawInteriorWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawLargeImageWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawIconWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawTitleWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawObjectCounterWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawIndicatorWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawCloseButtonWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;

@end

@implementation PSMTabBarCell

@synthesize tabState = _tabState;
@synthesize hasCloseButton = _hasCloseButton;
@synthesize hasIcon = _hasIcon;
@synthesize hasLargeImage = _hasLargeImage;
@synthesize count = _count;
@synthesize countColor = _countColor;
@synthesize isPlaceholder = _isPlaceholder;
@synthesize isEdited = _isEdited;
@synthesize closeButtonPressed = _closeButtonPressed;
@synthesize closeButtonTrackingTag = _closeButtonTrackingTag;
@synthesize cellTrackingTag = _cellTrackingTag;

#pragma mark -
#pragma mark Creation/Destruction
- (id)init {
	if((self = [super init])) {
		_closeButtonTrackingTag = 0;
		_cellTrackingTag = 0;
		_closeButtonOver = NO;
		_closeButtonPressed = NO;
		_indicator = [[PSMProgressIndicator alloc] initWithFrame:NSMakeRect(0.0, 0.0, kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth)];
		[_indicator setStyle:NSProgressIndicatorSpinningStyle];
		[_indicator setAutoresizingMask:NSViewMinYMargin];
		[_indicator setControlSize: NSSmallControlSize];
		_hasCloseButton = YES;
		_isCloseButtonSuppressed = NO;
		_count = 0;
		_countColor = nil;
		_isEdited = NO;
		_isPlaceholder = NO;
	}
	return self;
}

- (id)initPlaceholderWithFrame:(NSRect)frame expanded:(BOOL)value inTabBarControl:(PSMTabBarControl *)tabBarControl {
	if((self = [super init])) {
		_isPlaceholder = YES;
		if(!value) {
			if([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
				frame.size.width = 0.0;
			} else {
				frame.size.height = 0.0;
			}
		}
		[self setFrame:frame];
		_closeButtonTrackingTag = 0;
		_cellTrackingTag = 0;
		_closeButtonOver = NO;
		_closeButtonPressed = NO;
		_indicator = nil;
		_hasCloseButton = YES;
		_isCloseButtonSuppressed = NO;
		_count = 0;
		_countColor = nil;
		_isEdited = NO;

		if(value) {
			[self setCurrentStep:(kPSMTabDragAnimationSteps - 1)];
		} else {
			[self setCurrentStep:0];
		}
	}
	return self;
}

- (void)dealloc {
	[_countColor release];

	[_indicator removeFromSuperviewWithoutNeedingDisplay];

	[_indicator release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors
 
- (PSMTabBarControl *)controlView {
    return (PSMTabBarControl *)[super controlView];
}

- (void)setControlView:(PSMTabBarControl *)newControl {
    [super setControlView:newControl];
}

- (CGFloat)width {
	return _frame.size.width;
}

- (NSRect)frame {
	return _frame;
}

- (void)setFrame:(NSRect)rect {
	_frame = rect;

    PSMTabBarControl *tabBarControl = [self controlView];

	//move the status indicator along with the rest of the cell
	if(![[self indicator] isHidden] && ![tabBarControl isTabBarHidden]) {
		[[self indicator] setFrame:[self indicatorRectForBounds:rect]];
	}
}

- (void)setStringValue:(NSString *)aString {
	[super setStringValue:aString];
	_stringSize = [[self attributedStringValue] size];
	// need to redisplay now - binding observation was too quick.
	[[self controlView] update];
}

- (NSSize)stringSize {
	return _stringSize;
}

- (NSAttributedString *)attributedStringValue {
	return [(id < PSMTabStyle >)[[self controlView] style] attributedStringValueForTabCell:self];
}

- (NSProgressIndicator *)indicator {
	return _indicator;
}

- (BOOL)isInOverflowMenu {
	return _isInOverflowMenu;
}

- (void)setIsInOverflowMenu:(BOOL)value {
	if(_isInOverflowMenu != value) {
		_isInOverflowMenu = value;
        
        PSMTabBarControl *tabBarControl = [self controlView];
        
		if([[tabBarControl delegate] respondsToSelector:@selector(tabView:tabViewItem:isInOverflowMenu:)]) {
			[[tabBarControl delegate] tabView:[tabBarControl tabView] tabViewItem:[self representedObject] isInOverflowMenu:_isInOverflowMenu];
		}
	}
}

- (BOOL)closeButtonOver {
	return(_closeButtonOver && ([[self controlView] allowsBackgroundTabClosing] || ([self tabState] & PSMTab_SelectedMask) || [[NSApp currentEvent] modifierFlags] & NSCommandKeyMask));
}

- (void)setCloseButtonOver:(BOOL)value {
	_closeButtonOver = value;
}

- (void)setCloseButtonSuppressed:(BOOL)suppress;
{
	_isCloseButtonSuppressed = suppress;
}

- (BOOL)isCloseButtonSuppressed;
{
	return _isCloseButtonSuppressed;
}

- (NSInteger)currentStep {
	return _currentStep;
}

- (void)setCurrentStep:(NSInteger)value {
	if(value < 0) {
		value = 0;
	}

	if(value > (kPSMTabDragAnimationSteps - 1)) {
		value = (kPSMTabDragAnimationSteps - 1);
	}

	_currentStep = value;
}

#pragma mark -
#pragma mark Bindings

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// the progress indicator, label, icon, or count has changed - redraw the control view
	//[[self controlView] update];
	//I seem to have run into some odd issue with update not being called at the right time. This seems to avoid the problem.
	[[self controlView] performSelector:@selector(update) withObject:nil afterDelay:0.0];
}

#pragma mark -
#pragma mark Providing Images

- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type {

    id <PSMTabStyle> tabStyle = [[self controlView] style];
    
    if ([tabStyle respondsToSelector:@selector(closeButtonImageOfType:forTabCell:)]) {
        return [tabStyle closeButtonImageOfType:type forTabCell:self];
    // use standard image
    } else {
        return [self _closeButtonImageOfType:type];
    }
    
}

#pragma mark -
#pragma mark Determining Cell Size

- (NSRect)drawingRectForBounds:(NSRect)theRect {
    id <PSMTabStyle> tabStyle = [[self controlView] style];
    if ([tabStyle respondsToSelector:@selector(drawingRectForBounds:ofTabCell:)])
        return [tabStyle drawingRectForBounds:theRect ofTabCell:self];
    else
        return [self _drawingRectForBounds:theRect];
}

- (NSRect)titleRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [[self controlView] style];
    if ([tabStyle respondsToSelector:@selector(titleRectForBounds:ofTabCell:)])
        return [tabStyle titleRectForBounds:theRect ofTabCell:self];
    else {
        return [self _titleRectForBounds:theRect];
    }
}

- (NSRect)iconRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [[self controlView] style];
    if ([tabStyle respondsToSelector:@selector(iconRectForBounds:ofTabCell:)]) {
        return [tabStyle iconRectForBounds:theRect ofTabCell:self];
    } else {
        return [self _iconRectForBounds:theRect];
    }
}

- (NSRect)largeImageRectForBounds:(NSRect)theRect {

    // support for large images for horizontal orientation only
    if ([(PSMTabBarControl *)[self controlView] orientation] == PSMTabBarHorizontalOrientation)
        return NSZeroRect;

    id <PSMTabStyle> tabStyle = [[self controlView] style];
    if ([tabStyle respondsToSelector:@selector(largeImageRectForBounds:ofTabCell:)]) {
        return [tabStyle largeImageRectForBounds:theRect ofTabCell:self];
    } else {
        return [self _largeImageRectForBounds:theRect];
    }
}

- (NSRect)indicatorRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [[self controlView] style];
    if ([tabStyle respondsToSelector:@selector(indicatorRectForBounds:ofTabCell:)])
        return [tabStyle indicatorRectForBounds:theRect ofTabCell:self];
    else {
        return [self _indicatorRectForBounds:theRect];
    }
}

- (NSSize)objectCounterSize
{
    PSMTabBarControl *tabBarControl = (PSMTabBarControl *)[self controlView];
    id <PSMTabStyle> tabStyle = [tabBarControl style];

    if ([tabStyle respondsToSelector:@selector(objectCounterSizeForTabCell:)]) {
        return [tabStyle objectCounterSizeOfTabCell:self];
    } else {
        return [self _objectCounterSize];
    }
    
}

- (NSRect)objectCounterRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [[self controlView] style];
    if ([tabStyle respondsToSelector:@selector(objectCounterRectForBounds:ofTabCell:)]) {
        return [tabStyle objectCounterRectForBounds:theRect ofTabCell:self];
    } else {
    	return [self _objectCounterRectForBounds:theRect];
    }
}

- (NSRect)closeButtonRectForBounds:(NSRect)theRect {
    
    id <PSMTabStyle> tabStyle = [[self controlView] style];
    
    // ask style for rect if available
    if ([tabStyle respondsToSelector:@selector(closeButtonRectForBounds:ofTabCell:)]) {
        return [tabStyle closeButtonRectForBounds:theRect ofTabCell:self];
    // default handling
    } else {
        return [self _closeButtonRectForBounds:theRect];
    }
}

- (CGFloat)minimumWidthOfCell {

    id < PSMTabStyle > style = [[self controlView] style];
    if ([style respondsToSelector:@selector(minimumWidthOfTabCell)]) {
        return [style minimumWidthOfTabCell:self];
    } else {
        return [self _minimumWidthOfCell];
    }
}

- (CGFloat)desiredWidthOfCell {

    id < PSMTabStyle > style = [[self controlView] style];
    if ([style respondsToSelector:@selector(desiredWidthOfTabCell)]) {
        return [style desiredWidthOfTabCell:self];
    } else {    
        return [self _desiredWidthOfCell];
    }
}

#pragma mark -
#pragma mark Image Scaling

static inline NSSize scaleProportionally(NSSize imageSize, NSSize canvasSize, BOOL scaleUpOrDown) {

    CGFloat ratio;

    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return NSMakeSize(0, 0);
    }

    // get the smaller ratio and scale the image size with it
    ratio = MIN(canvasSize.width / imageSize.width,
	      canvasSize.height / imageSize.height);
  
    // Only scale down, unless scaleUpOrDown is YES
    if (ratio < 1.0 || scaleUpOrDown)
        {
        imageSize.width *= ratio;
        imageSize.height *= ratio;
        }
    
    return imageSize;
} 

- (NSSize)scaleImageWithSize:(NSSize)imageSize toFitInSize:(NSSize)canvasSize scalingType:(NSImageScaling)scalingType {

    NSSize result;
  
    switch (scalingType)  {
        case NSImageScaleProportionallyDown:
            result = scaleProportionally (imageSize, canvasSize, NO);
            break;
        case NSImageScaleAxesIndependently:
            result = canvasSize;
            break;
        default:
        case NSImageScaleNone:
            result = imageSize;
            break;
        case NSImageScaleProportionallyUpOrDown:
            result = scaleProportionally (imageSize, canvasSize, YES);
            break;
    }
    
    return result;
}

#pragma mark -
#pragma mark Drawing

- (BOOL)shouldDrawCloseButton {
    return [self hasCloseButton] && ![self isCloseButtonSuppressed];
}

- (BOOL)shouldDrawObjectCounter {
    return [self count] != 0;
}

- (void)drawWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> style = [tabBarControl style];
    if ([style respondsToSelector:@selector(drawTabBarCell:withFrame:inTabBarControl:)]) {
        [style drawTabBarCell:self withFrame:cellFrame inTabBarControl:tabBarControl];
    } else {
        [self _drawWithFrame:cellFrame inTabBarControl:tabBarControl];
    }
        
}

- (void)drawBezelWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> style = [tabBarControl style];
        
    // draw bezel
    if ([style respondsToSelector:@selector(drawBezelOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawBezelOfTabCell:self withFrame:cellFrame inTabBarControl:tabBarControl];
    } else {
        [self _drawBezelWithFrame:cellFrame inTabBarControl:tabBarControl];
    }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    id <PSMTabStyle> style = [tabBarControl style];
    
    if ([style respondsToSelector:@selector(drawInteriorOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawInteriorOfTabCell:self withFrame:cellFrame inTabBarControl:tabBarControl];
    } else {
        [self _drawInteriorWithFrame:cellFrame inTabBarControl:tabBarControl];
    }
    
}

- (void)drawLargeImageWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    
    id <PSMTabStyle> style = [tabBarControl style];
    if ([style respondsToSelector:@selector(drawLargeImageOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawLargeImageOfTabCell:self withFrame:frame inTabBarControl:tabBarControl];
    } else {
        [self _drawLargeImageWithFrame:frame inTabBarControl:tabBarControl];
    }
    
}

- (void)drawIconWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> style = [tabBarControl style];
    if ([style respondsToSelector:@selector(drawIconOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawIconOfTabCell:self withFrame:frame inTabBarControl:tabBarControl];
    } else {
        [self _drawIconWithFrame:frame inTabBarControl:tabBarControl];
    }
    
}

- (void)drawTitleWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> style = [tabBarControl style];
    if ([style respondsToSelector:@selector(drawTitleOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawTitleOfTabCell:self withFrame:frame inTabBarControl:tabBarControl];
    } else {
        [self _drawTitleWithFrame:frame inTabBarControl:tabBarControl];
    }
}

- (void)drawObjectCounterWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> style = [tabBarControl style];
    if ([style respondsToSelector:@selector(drawObjectCounterOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawObjectCounterOfTabCell:self withFrame:frame inTabBarControl:tabBarControl];
    } else {
        [self _drawObjectCounterWithFrame:frame inTabBarControl:tabBarControl];
    }
}

- (void)drawIndicatorWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> style = [tabBarControl style];
    if ([style respondsToSelector:@selector(drawIndicatorOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawIndicatorOfTabCell:self withFrame:frame inTabBarControl:tabBarControl];
    } else {
        [self _drawIndicatorWithFrame:frame inTabBarControl:tabBarControl];
    }
}

- (void)drawCloseButtonWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> style = [tabBarControl style];
    if ([style respondsToSelector:@selector(drawCloseButtonOfTabCell:withFrame:inTabBarControl:)]) {
        [style drawCloseButtonOfTabCell:self withFrame:frame inTabBarControl:tabBarControl];
    } else {
        [self _drawCloseButtonWithFrame:frame inTabBarControl:tabBarControl];
    }

}

#pragma mark -
#pragma mark Tracking

- (void)mouseEntered:(NSEvent *)theEvent {
	// check for which tag
	if([theEvent trackingNumber] == _closeButtonTrackingTag) {
		_closeButtonOver = YES;
	}
    
    PSMTabBarControl *tabBarControl = [self controlView];
    
	if([theEvent trackingNumber] == _cellTrackingTag) {
		[self setHighlighted:YES];
		[tabBarControl setNeedsDisplay:NO];
	}

	// scrubtastic
	if([tabBarControl allowsScrubbing] && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
		[tabBarControl performSelector:@selector(tabClick:) withObject:self];
	}

	// tell the control we only need to redraw the affected tab
	[tabBarControl setNeedsDisplayInRect:NSInsetRect([self frame], -2, -2)];
}

- (void)mouseExited:(NSEvent *)theEvent {
	// check for which tag
	if([theEvent trackingNumber] == _closeButtonTrackingTag) {
		_closeButtonOver = NO;
	}

    PSMTabBarControl *tabBarControl = [self controlView];
    
	if([theEvent trackingNumber] == _cellTrackingTag) {
		[self setHighlighted:NO];
		[tabBarControl setNeedsDisplay:NO];
	}

	//tell the control we only need to redraw the affected tab
	[tabBarControl setNeedsDisplayInRect:NSInsetRect([self frame], -2, -2)];
}

#pragma mark -
#pragma mark Drag Support

- (NSImage *)dragImage {
	NSRect cellFrame = [(id < PSMTabStyle >)[[self controlView] style] dragRectForTabCell:self ofTabBarControl:[self controlView]];

    PSMTabBarControl *tabBarControl = [self controlView];

	[tabBarControl lockFocus];
	NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:cellFrame] autorelease];
	[tabBarControl unlockFocus];
	NSImage *image = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
	[image addRepresentation:rep];
	NSImage *returnImage = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
	[returnImage lockFocus];
    [image drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[returnImage unlockFocus];
	if(![[self indicator] isHidden]) {
		NSImage *pi = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"pi"]];
		[returnImage lockFocus];
		NSPoint indicatorPoint = NSMakePoint([self frame].size.width - MARGIN_X - kPSMTabBarIndicatorWidth, MARGIN_Y);
        [pi drawAtPoint:indicatorPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[returnImage unlockFocus];
		[pi release];
	}
	return returnImage;
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding]) {
		[aCoder encodeRect:_frame forKey:@"frame"];
		[aCoder encodeSize:_stringSize forKey:@"stringSize"];
		[aCoder encodeInteger:_currentStep forKey:@"currentStep"];
		[aCoder encodeBool:_isPlaceholder forKey:@"isPlaceholder"];
		[aCoder encodeInteger:_tabState forKey:@"tabState"];
		[aCoder encodeInteger:_closeButtonTrackingTag forKey:@"closeButtonTrackingTag"];
		[aCoder encodeInteger:_cellTrackingTag forKey:@"cellTrackingTag"];
		[aCoder encodeBool:_closeButtonOver forKey:@"closeButtonOver"];
		[aCoder encodeBool:_closeButtonPressed forKey:@"closeButtonPressed"];
		[aCoder encodeObject:_indicator forKey:@"indicator"];
		[aCoder encodeBool:_isInOverflowMenu forKey:@"isInOverflowMenu"];
		[aCoder encodeBool:_hasCloseButton forKey:@"hasCloseButton"];
		[aCoder encodeBool:_isCloseButtonSuppressed forKey:@"isCloseButtonSuppressed"];
		[aCoder encodeBool:_hasIcon forKey:@"hasIcon"];
		[aCoder encodeBool:_hasLargeImage forKey:@"hasLargeImage"];
		[aCoder encodeInteger:_count forKey:@"count"];
		[aCoder encodeBool:_isEdited forKey:@"isEdited"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if(self) {
		if([aDecoder allowsKeyedCoding]) {
			_frame = [aDecoder decodeRectForKey:@"frame"];
			_stringSize = [aDecoder decodeSizeForKey:@"stringSize"];
			_currentStep = [aDecoder decodeIntegerForKey:@"currentStep"];
			_isPlaceholder = [aDecoder decodeBoolForKey:@"isPlaceholder"];
			_tabState = [aDecoder decodeIntegerForKey:@"tabState"];
			_closeButtonTrackingTag = [aDecoder decodeIntegerForKey:@"closeButtonTrackingTag"];
			_cellTrackingTag = [aDecoder decodeIntegerForKey:@"cellTrackingTag"];
			_closeButtonOver = [aDecoder decodeBoolForKey:@"closeButtonOver"];
			_closeButtonPressed = [aDecoder decodeBoolForKey:@"closeButtonPressed"];
			_indicator = [[aDecoder decodeObjectForKey:@"indicator"] retain];
			_isInOverflowMenu = [aDecoder decodeBoolForKey:@"isInOverflowMenu"];
			_hasCloseButton = [aDecoder decodeBoolForKey:@"hasCloseButton"];
			_isCloseButtonSuppressed = [aDecoder decodeBoolForKey:@"isCloseButtonSuppressed"];
			_hasIcon = [aDecoder decodeBoolForKey:@"hasIcon"];
			_hasLargeImage = [aDecoder decodeBoolForKey:@"hasLargeImage"];
			_count = [aDecoder decodeIntegerForKey:@"count"];
			_isEdited = [aDecoder decodeBoolForKey:@"isEdited"];
		}
	}
	return self;
}

#pragma mark -
#pragma mark Accessibility

-(BOOL)accessibilityIsIgnored {
	return NO;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
	id attributeValue = nil;

	if([attribute isEqualToString: NSAccessibilityRoleAttribute]) {
		attributeValue = NSAccessibilityRadioButtonRole;
	} else if([attribute isEqualToString: NSAccessibilityRoleDescriptionAttribute]) {
		attributeValue = NSLocalizedString(@"Tab", nil);
	} else if([attribute isEqualToString: NSAccessibilityTitleAttribute]) {
		attributeValue = [self title];
	} else if([attribute isEqualToString: NSAccessibilityHelpAttribute]) {
		if([[[self controlView] delegate] respondsToSelector:@selector(accessibilityStringForTabView:objectCount:)]) {
			attributeValue = [NSString stringWithFormat:@"%@, %lu %@", [self stringValue],
							  (unsigned long)[self count],
							  [[[self controlView] delegate] accessibilityStringForTabView:[[self controlView] tabView] objectCount:[self count]]];
		} else {
			attributeValue = [self stringValue];
		}
	} else if([attribute isEqualToString: NSAccessibilityFocusedAttribute]) {
		attributeValue = [NSNumber numberWithBool:([self tabState] == 2)];
	} else {
		attributeValue = [super accessibilityAttributeValue:attribute];
	}

	return attributeValue;
}

- (NSArray *)accessibilityActionNames {
	static NSArray *actions;

	if(!actions) {
		actions = [[NSArray alloc] initWithObjects:NSAccessibilityPressAction, nil];
	}
	return actions;
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
	return NSAccessibilityActionDescription(action);
}

- (void)accessibilityPerformAction:(NSString *)action {
	if([action isEqualToString:NSAccessibilityPressAction]) {
		// this tab was selected
		[[self controlView] performSelector:@selector(tabClick:) withObject:self];
	}
}

- (id)accessibilityHitTest:(NSPoint)point {
	return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement:(NSPoint)point {
	return NSAccessibilityUnignoredAncestor(self);
}

#pragma mark -
#pragma Private Methods

- (NSRect)_drawingRectForBounds:(NSRect)theRect {
    return NSInsetRect(theRect, MARGIN_X, MARGIN_Y);
}

- (NSRect)_titleRectForBounds:(NSRect)theRect {
    NSRect drawingRect = [self drawingRectForBounds:theRect];

    NSRect constrainedDrawingRect = drawingRect;

    NSRect closeButtonRect = [self closeButtonRectForBounds:theRect];
    if (!NSEqualRects(closeButtonRect, NSZeroRect)) {
        constrainedDrawingRect.origin.x += NSWidth(closeButtonRect)  + kPSMTabBarCellPadding;
        constrainedDrawingRect.size.width -= NSWidth(closeButtonRect) + kPSMTabBarCellPadding;
    }

    NSRect largeImageRect = [self largeImageRectForBounds:theRect];
    if (!NSEqualRects(largeImageRect, NSZeroRect)) {
        constrainedDrawingRect.origin.x += NSWidth(largeImageRect) + kPSMTabBarCellPadding;
        constrainedDrawingRect.size.width -= NSWidth(largeImageRect) + kPSMTabBarCellPadding;
        }
                
    NSRect iconRect = [self iconRectForBounds:theRect];
    if (!NSEqualRects(iconRect, NSZeroRect)) {
        constrainedDrawingRect.origin.x += NSWidth(iconRect)  + kPSMTabBarCellPadding;
        constrainedDrawingRect.size.width -= NSWidth(iconRect) + kPSMTabBarCellPadding;
    }
        
    NSRect indicatorRect = [self indicatorRectForBounds:theRect];
    if (!NSEqualRects(indicatorRect, NSZeroRect)) {
        constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kPSMTabBarCellPadding;
    }

    NSRect counterBadgeRect = [self objectCounterRectForBounds:theRect];
    if (!NSEqualRects(counterBadgeRect, NSZeroRect)) {
        constrainedDrawingRect.size.width -= NSWidth(counterBadgeRect) + kPSMTabBarCellPadding;
    }
                            
    NSAttributedString *attrString = [self attributedStringValue];
    if ([attrString length] == 0)
        return NSZeroRect;
        
    NSSize stringSize = [attrString size];
    
    NSRect result = NSMakeRect(constrainedDrawingRect.origin.x, drawingRect.origin.y+ceil((drawingRect.size.height-stringSize.height)/2), constrainedDrawingRect.size.width, stringSize.height);
                    
    return NSIntegralRect(result);

}

- (NSRect)_iconRectForBounds:(NSRect)theRect {

    if (![self hasIcon])
        return NSZeroRect;

    NSImage *icon = [[(NSTabViewItem*)[self representedObject] identifier] icon];
    if (!icon)
        return NSZeroRect;

    // calculate rect
    NSRect drawingRect = [self drawingRectForBounds:theRect];

    NSRect constrainedDrawingRect = drawingRect;

    NSRect closeButtonRect = [self closeButtonRectForBounds:theRect];
    if (!NSEqualRects(closeButtonRect, NSZeroRect)) {
        constrainedDrawingRect.origin.x += NSWidth(closeButtonRect)  + kPSMTabBarCellPadding;
        constrainedDrawingRect.size.width -= NSWidth(closeButtonRect) + kPSMTabBarCellPadding;
        }
                
    NSSize iconSize = [icon size];
    
    NSSize scaledIconSize = [self scaleImageWithSize:iconSize toFitInSize:NSMakeSize(iconSize.width, constrainedDrawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

    NSRect result = NSMakeRect(drawingRect.origin.x,
                                         drawingRect.origin.y - ((drawingRect.size.height - scaledIconSize.height) / 2),
                                         scaledIconSize.width, scaledIconSize.height);
                                         
    // center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
    if(scaledIconSize.width < kPSMTabBarIconWidth) {
        result.origin.x += ceil((kPSMTabBarIconWidth - scaledIconSize.width) / 2.0);
    }

    if(scaledIconSize.height < kPSMTabBarIconWidth) {
        result.origin.y -= ceil((kPSMTabBarIconWidth - scaledIconSize.height) / 2.0 - 0.5);
    }

    return NSIntegralRect(result);
}

- (NSRect)_largeImageRectForBounds:(NSRect)theRect {

    if ([self hasLargeImage] == NO) {
        return NSZeroRect;
    }
    
    // calculate rect
    NSRect drawingRect = [self drawingRectForBounds:theRect];
    
    NSImage *image = [[[self representedObject] identifier] largeImage];
    if (!image)
        return NSZeroRect;
    
    NSSize scaledImageSize = [self scaleImageWithSize:[image size] toFitInSize:NSMakeSize(kPSMTabBarLargeImageWidth, drawingRect.size.height) scalingType:NSImageScaleProportionallyUpOrDown];
    
    NSRect result = NSMakeRect(drawingRect.origin.x,
                                         drawingRect.origin.y - ((drawingRect.size.height - scaledImageSize.height) / 2),
                                         scaledImageSize.width, scaledImageSize.height);

    if(scaledImageSize.width < kPSMTabBarIconWidth) {
        result.origin.x += (kPSMTabBarIconWidth - scaledImageSize.width) / 2.0;
    }
    if(scaledImageSize.height < drawingRect.size.height) {
        result.origin.y += (drawingRect.size.height - scaledImageSize.height) / 2.0;
    }
        
    return result;
}

- (NSRect)_indicatorRectForBounds:(NSRect)theRect {

    if([[self indicator] isHidden]) {
        return NSZeroRect;
    }

    // calculate rect
    NSRect drawingRect = [self drawingRectForBounds:theRect];

    NSSize indicatorSize = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
    
    NSRect result = NSMakeRect(NSMaxX(drawingRect)-indicatorSize.width,NSMidY(drawingRect)-ceil(indicatorSize.height/2),indicatorSize.width,indicatorSize.height);
    
    return NSIntegralRect(result);
}

- (NSSize)_objectCounterSize {

    PSMTabBarControl *tabBarControl = (PSMTabBarControl *)[self controlView];
    id <PSMTabStyle> tabStyle = [tabBarControl style];
    
    if([self count] == 0) {
        return NSZeroSize;
    }
    
    // get badge width
    CGFloat countWidth = [[tabStyle attributedObjectCountValueForTabCell:self] size].width;
        countWidth += (2 * kPSMObjectCounterRadius - 6.0);
        if(countWidth < kPSMObjectCounterMinWidth) {
            countWidth = kPSMObjectCounterMinWidth;
        }
    
    return NSMakeSize(countWidth, 2 * kPSMObjectCounterRadius);
}

- (NSRect)_objectCounterRectForBounds:(NSRect)theRect {

    if(![self shouldDrawObjectCounter]) {
        return NSZeroRect;
    }

    NSRect drawingRect = [self drawingRectForBounds:theRect];

    NSRect constrainedDrawingRect = drawingRect;

    NSRect indicatorRect = [self indicatorRectForBounds:theRect];
    if (!NSEqualRects(indicatorRect, NSZeroRect)) {
        constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kPSMTabBarCellPadding;
        }
    
    NSSize counterBadgeSize = [self objectCounterSize];
    
    // calculate rect
    NSRect result;
    result.size = counterBadgeSize; // temp
    result.origin.x = NSMaxX(constrainedDrawingRect)-counterBadgeSize.width;
    result.origin.y = ceil(constrainedDrawingRect.origin.y+(constrainedDrawingRect.size.height-result.size.height)/2);
                
    return NSIntegralRect(result);
}

- (NSRect)_closeButtonRectForBounds:(NSRect)theRect {

    if ([self shouldDrawCloseButton] == NO) {
        return NSZeroRect;
    }
    
    // ask style for image
    NSImage *image = [self closeButtonImageOfType:PSMCloseButtonImageTypeStandard];            
    if (!image)
        return NSZeroRect;
    
    // calculate rect
    NSRect drawingRect = [self drawingRectForBounds:theRect];
    NSSize imageSize = [image size];
    
    NSSize scaledImageSize = [self scaleImageWithSize:imageSize toFitInSize:NSMakeSize(imageSize.width, drawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

    NSRect result = NSMakeRect(drawingRect.origin.x, drawingRect.origin.y, scaledImageSize.width, scaledImageSize.height);

    if(scaledImageSize.height < drawingRect.size.height) {
        result.origin.y += ceil((drawingRect.size.height - scaledImageSize.height) / 2.0);
    }

    return NSIntegralRect(result);
}

- (CGFloat)_minimumWidthOfCell {
    CGFloat resultWidth = 0.0;

    // left margin
    resultWidth = MARGIN_X;

    // close button?
    if ([self shouldDrawCloseButton]) {
        NSImage *image = [self closeButtonImageOfType:PSMCloseButtonImageTypeStandard];
        resultWidth += [image size].width + kPSMTabBarCellPadding;
    }

    // icon?
    if([self hasIcon]) {
        resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
    }

    // the label
    resultWidth += kPSMMinimumTitleWidth;

    // object counter?
    if([self count] > 0) {
        resultWidth += [self objectCounterSize].width + kPSMTabBarCellPadding;
    }

    // indicator?
    if([[self indicator] isHidden] == NO) {
        resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
    }

    // right margin
    resultWidth += MARGIN_X;

    return ceil(resultWidth);
}

- (CGFloat)_desiredWidthOfCell {

    CGFloat resultWidth = 0.0;

    // left margin
    resultWidth = MARGIN_X;

    // close button?
    if ([self shouldDrawCloseButton]) {
        NSImage *image = [self closeButtonImageOfType:PSMCloseButtonImageTypeStandard];
        resultWidth += [image size].width + kPSMTabBarCellPadding;
    }

    // icon?
    if([self hasIcon]) {
        resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
    }

    // the label
    resultWidth += [[self attributedStringValue] size].width;

    // object counter?
    if([self count] > 0) {
        resultWidth += [self objectCounterSize].width + kPSMTabBarCellPadding;
    }

    // indicator?
    if([[self indicator] isHidden] == NO) {
        resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
    }

    // right margin
    resultWidth += MARGIN_X;

    return ceil(resultWidth);
}

- (NSImage *)_closeButtonImageOfType:(PSMCloseButtonImageType)type {

    switch (type) {
        case PSMCloseButtonImageTypeStandard:
            return [NSImage imageNamed:@"TabClose_Front"];
        case PSMCloseButtonImageTypeRollover:
            return [NSImage imageNamed:@"TabClose_Front_Rollover"];
        case PSMCloseButtonImageTypePressed:
            return [NSImage imageNamed:@"TabClose_Front_Pressed"];
            
        case PSMCloseButtonImageTypeDirty:
            return [NSImage imageNamed:@"TabClose_Dirty"];
        case PSMCloseButtonImageTypeDirtyRollover:
            return [NSImage imageNamed:@"TabClose_Dirty_Rollover"];
        case PSMCloseButtonImageTypeDirtyPressed:
            return [NSImage imageNamed:@"TabClose_Dirty_Pressed"];
            
        default:
            break;
    }
    
    return nil;
}

- (void)_drawWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl {

	if(_isPlaceholder) {
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
		NSRectFillUsingOperation(cellFrame, NSCompositeSourceAtop);
		return;
	}
    
    [self drawBezelWithFrame:cellFrame inTabBarControl:tabBarControl];
    [self drawInteriorWithFrame:cellFrame inTabBarControl:tabBarControl];
}

- (void)_drawBezelWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    // default implementation draws nothing yet.
}

- (void)_drawInteriorWithFrame:(NSRect)cellFrame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    NSRect componentRect;
    
    componentRect = [self largeImageRectForBounds:cellFrame];
    if (!NSEqualRects(componentRect, NSZeroRect))
        [self drawLargeImageWithFrame:cellFrame inTabBarControl:tabBarControl];
        
    componentRect = [self iconRectForBounds:cellFrame];
    if (!NSEqualRects(componentRect, NSZeroRect))
        [self drawIconWithFrame:cellFrame inTabBarControl:tabBarControl];
        
    componentRect = [self titleRectForBounds:cellFrame];
    if (!NSEqualRects(componentRect, NSZeroRect))
        [self drawTitleWithFrame:cellFrame inTabBarControl:tabBarControl];
        
    componentRect = [self objectCounterRectForBounds:cellFrame];
    if (!NSEqualRects(componentRect, NSZeroRect))
        [self drawObjectCounterWithFrame:cellFrame inTabBarControl:tabBarControl];
        
    componentRect = [self indicatorRectForBounds:cellFrame];
    if (!NSEqualRects(componentRect, NSZeroRect))
        [self drawIndicatorWithFrame:cellFrame inTabBarControl:tabBarControl];
        
    componentRect = [self closeButtonRectForBounds:cellFrame];
    if (!NSEqualRects(componentRect, NSZeroRect))
        [self drawCloseButtonWithFrame:cellFrame inTabBarControl:tabBarControl];
}

- (void)_drawLargeImageWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    PSMTabBarOrientation orientation = [tabBarControl orientation];
    
    if ((orientation != PSMTabBarVerticalOrientation) || ![self hasLargeImage])
        return;

    NSImage *image = [[[self representedObject] identifier] largeImage];
    if (!image)
        return;
    
    NSRect imageDrawingRect = [self largeImageRectForBounds:frame];
    
    [NSGraphicsContext saveGraphicsState];
            
    //Create Rounding.
    CGFloat userIconRoundingRadius = (kPSMTabBarLargeImageWidth / 4.0);
    if(userIconRoundingRadius > 3.0) {
        userIconRoundingRadius = 3.0;
    }
    
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:imageDrawingRect xRadius:userIconRoundingRadius yRadius:userIconRoundingRadius];
    [clipPath addClip];        

    [image drawInRect:imageDrawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

    [NSGraphicsContext restoreGraphicsState];
}

- (void)_drawIconWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    NSRect iconRect = [self iconRectForBounds:frame];
    
    NSImage *icon = [[(NSTabViewItem*)[self representedObject] identifier] icon];

    [icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
}

- (void)_drawTitleWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    NSRect rect = [self titleRectForBounds:frame];

    // draw title
    [[self attributedStringValue] drawInRect:rect];
}

- (void)_drawObjectCounterWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    id <PSMTabStyle> tabStyle = [tabBarControl style];

    // set color
    [[self countColor] ?: [NSColor colorWithCalibratedWhite:0.3 alpha:0.45] set];
    
    // get rect
    NSRect myRect = [self objectCounterRectForBounds:frame];
    
    // create badge path
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:myRect xRadius:kPSMObjectCounterRadius yRadius:kPSMObjectCounterRadius];
    
    // fill badge
    [path fill];

    // draw attributed string centered in area
    NSRect counterStringRect;
    NSAttributedString *counterString = [tabStyle attributedObjectCountValueForTabCell:self];
    counterStringRect.size = [counterString size];
    counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
    counterStringRect.origin.y = NSMidY(myRect)-counterStringRect.size.height/2;
    [counterString drawInRect:counterStringRect];
}

- (void)_drawIndicatorWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {
    // we draw nothing by default
}

- (void)_drawCloseButtonWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    // get type of close button to draw
    PSMCloseButtonImageType imageType;
    if ([self isEdited]) {
        if ([self closeButtonOver])
            imageType = PSMCloseButtonImageTypeDirtyRollover;
        else if ([self closeButtonPressed])
            imageType = PSMCloseButtonImageTypeDirtyPressed;
        else
            imageType = PSMCloseButtonImageTypeDirty;
    } else {
        if ([self closeButtonOver])
            imageType = PSMCloseButtonImageTypeRollover;
        else if ([self closeButtonPressed])
            imageType = PSMCloseButtonImageTypePressed;
        else
            imageType = PSMCloseButtonImageTypeStandard;
    }
    
    // ask style for image
    NSImage *image = nil;
    image = [self closeButtonImageOfType:imageType];
    if (!image)
        return;
        
    // draw close button
    NSRect closeButtonRect = [self closeButtonRectForBounds:frame];

    [image drawInRect:closeButtonRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}
@end
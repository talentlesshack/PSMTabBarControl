//
//  PSMTabStyle.h
//  PSMTabBarControl
//
//  Created by John Pannell on 2/17/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

/*
   Protocol to be observed by all style delegate objects.  These objects handle the drawing responsibilities for PSMTabBarCell; once the control has been assigned a style, the background and cells draw consistent with that style.  Design pattern and implementation by David Smith, Seth Willits, and Chris Forsythe, all touch up and errors by John P. :-)
 */

#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"

@protocol PSMTabStyle <NSObject>

// identity
- (NSString *)name;

// control specific parameters
- (CGFloat)leftMarginForTabBarControl;
- (CGFloat)rightMarginForTabBarControl;
- (CGFloat)topMarginForTabBarControl;

// add tab button
- (NSImage *)addTabButtonImage;
- (NSImage *)addTabButtonPressedImage;
- (NSImage *)addTabButtonRolloverImage;

// cell specific parameters
- (NSRect)dragRectForTabCell:(PSMTabBarCell *)cell orientation:(PSMTabBarOrientation)orientation;
- (CGFloat)tabCellHeight;

// cell values
- (NSAttributedString *)attributedObjectCountValueForTabCell:(PSMTabBarCell *)cell;
- (NSAttributedString *)attributedStringValueForTabCell:(PSMTabBarCell *)cell;

// drawing
- (void)drawBackgroundInRect:(NSRect)rect;
- (void)drawTabBar:(PSMTabBarControl *)bar inRect:(NSRect)rect;

@optional

// Constraints
- (CGFloat)minimumWidthOfTabCell:(PSMTabBarCell *)cell;
- (CGFloat)desiredWidthOfTabCell:(PSMTabBarCell *)cell;

// Providing Images
- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type forTabCell:(PSMTabBarCell *)cell;

// Determining Cell Size
- (NSRect)drawingRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell;
- (NSRect)titleRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell;
- (NSRect)iconRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell;
- (NSRect)largeImageRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell;
- (NSRect)indicatorRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell;
- (NSSize)objectCounterSizeOfTabCell:(PSMTabBarCell *)cell;
- (NSRect)objectCounterRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell;
- (NSRect)closeButtonRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell;

// Drawing
- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;
- (void)drawInteriorOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;
- (void)drawTitleOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;
- (void)drawIconOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;
- (void)drawLargeImageOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;
- (void)drawIndicatorOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;
- (void)drawObjectCounterOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;
- (void)drawCloseButtonOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:controlView;

// Deprecated Stuff

- (void)drawTabCell:(PSMTabBarCell *)cell DEPRECATED_ATTRIBUTE;
- (NSRect)closeButtonRectForTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)cellFrame DEPRECATED_ATTRIBUTE;
- (NSRect)iconRectForTabCell:(PSMTabBarCell *)cell DEPRECATED_ATTRIBUTE;
- (NSRect)indicatorRectForTabCell:(PSMTabBarCell *)cell DEPRECATED_ATTRIBUTE;
- (NSRect)objectCounterRectForTabCell:(PSMTabBarCell *)cell DEPRECATED_ATTRIBUTE;
- (void)setOrientation:(PSMTabBarOrientation)value DEPRECATED_ATTRIBUTE;
@end

@interface PSMTabBarControl (StyleAccessors)

- (NSMutableArray *)cells;

@end

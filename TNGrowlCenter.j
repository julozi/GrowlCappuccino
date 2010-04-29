/*  
 * TNGrowl.j
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "TNGrowlView.j";

/*! @global
    @group TNGrowl
    the defaultCenter pointer
*/
TNGrowlDefaultCenter                    = nil;

/*! @global
    @group TNGrowlIcon
    icon identitier for Info
*/
TNGrowlIconInfo     = @"TNGrowlIconInfo";

/*! @global
    @group TNGrowlIcon
    icon identitier for Error
*/
TNGrowlIconError    = @"TNGrowlIconError";

/*! @global
    @group TNGrowlIcon
    icon identitier for Warning
*/
TNGrowlIconWarning  = @"TNGrowlIconWarning";

/*! @global
    @group TNGrowlIcon
    icon identitier for custom icon
*/
TNGrowlIconCustom   = @"TNGrowlIconCustom";

/*! @global
    @group TNGrowlPlacement
    the height of TNGrowlView
*/
TNGrowlPlacementWidth           = 250.0

/*! @global
    @group TNGrowlPlacement
    the width of TNGrowlView
*/
TNGrowlPlacementHeight          = 80.0

/*! @global
    @group TNGrowlPlacement
    the margin top value
*/
TNGrowlPlacementMarginTop       = 10.0;

/*! @global
    @group TNGrowlPlacement
    the margin top right
*/
TNGrowlPlacementMarginRight     = 10.0;

/*! @global
    @group TNGrowlAnimation
    Duration of fade in and fade out CPViewAnimation
*/
TNGrowlAnimationDuration    = 0.3;



/*! @ingroup growlcappuccino
    this is the GrowlCappuccino notification center. This is from where you can post Growl notification.
    it provide a class method defaultCenter: that return the default GrowlCappuccino center.
    In the most of the case you should use this default center.
    
    You can find two option to set in Info.plist
     - TNGrowlUseMouseMoveEvents : 1 or 0. Default: 0. If 1, GrowlCappuccino will set acceptsMouseMovedEvents: to the _view's window. this
     will allow to stop life time counting on mouse over, but it can affect the whole application performance
     - TNGrowlDefaultLifeTime : in seconds. Deafult: 5. The lifeTime of notification.
*/
@implementation TNGrowlCenter : CPObject
{
    float       _defaultLifeTime    @accessors(getter=lifeDefaultTime, setter=setDefaultLifeTime:);
    CPColor     _backgroundColor    @accessors(getter=backgroundColor, setter=setBackgroundColor:);
    CPView      _view               @accessors(getter=view, setter=setView:);
    CPImage     _iconCustom         @accessors(getter=customIcon, setter=setCustomIcon:);
    CPArray     _notifications;
    CPRect      _notificationFrame;
    CPImage     _iconInfo;
    CPImage     _iconWarning;
    CPImage     _iconError;
    Boolean     _useWindowMouseMoveEvents;
}

/*! return the defaultCenter
    @return TNGrowlCenter the default center;
*/
+ (id)defaultCenter
{
    if (!TNGrowlDefaultCenter)
        TNGrowlDefaultCenter = [[TNGrowlCenter alloc] init];
    
    return TNGrowlDefaultCenter;
}

/*! initialize the class
    @return the initialized instance of TNGrowlCenter
*/
- (id)init
{
    if (self = [super init])
    {
        var bundle          = [CPBundle bundleForClass:[self class]];
        var backgroundImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"background.png"]];
        
        _notifications              = [CPArray array];
        _notificationFrame          = CGRectMake(10,10, TNGrowlPlacementWidth,TNGrowlPlacementHeight);
        _defaultLifeTime            = [bundle objectForInfoDictionaryKey:@"TNGrowlDefaultLifeTime"];
        _iconInfo                   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-info.png"]];
        _iconError                  = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-error.png"]];
        _iconWarning                = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-warning.png"]];
        _backgroundColor            = [CPColor colorWithPatternImage:backgroundImage];
        _useWindowMouseMoveEvents   = [bundle objectForInfoDictionaryKey:@"TNGrowlUseMouseMoveEvents"];
    }
    
    return self;
}

/*! display a notification with type TNGrowlIconInfo
    @param aTitle the title of the notification
    @param aMessage the mesage of the notification
*/
- (void)pushNotificationWithTitle:(CPString)aTitle message:(CPString)aMessage
{
    [self pushNotificationWithTitle:aTitle message:aMessage icon:TNGrowlIconInfo];
}

/*! display a notification with given type
    anIconType can be:
     - TNGrowlIconInfo
     - TNGrowlIconError
     - TNGrowlIconWarning
     - TNGrowlIconCustom
    
    @param aTitle the title of the notification
    @param aMessage the mesage of the notification
    @param anIconType a type of icon.
*/
- (void)pushNotificationWithTitle:(CPString)aTitle message:(CPString)aMessage icon:(CPString)anIconType
{
    var icon;
    
    switch (anIconType)
    {
        case TNGrowlIconInfo:
            icon = _iconInfo;
            break;
        
        case TNGrowlIconWarning:
            icon = _iconWarning;
            break;
        
        case TNGrowlIconError:
            icon = _iconError;
            break;
        
        case TNGrowlIconCustom:
            icon = _iconCustom;
            break;
    }
    
    [self pushNotificationWithTitle:aTitle message:aMessage customIcon:icon];
}

/*! display a notification with a CPImage as icon.
    @param aTitle the title of the notification
    @param aMessage the mesage of the notification
    @param anIcon a CPImage representing the notification icon
*/
- (void)pushNotificationWithTitle:(CPString)aTitle message:(CPString)aMessage customIcon:(CPImage)anIcon
{
    var center      = [CPNotificationCenter defaultCenter];
    var notifView   = [[TNGrowlView alloc] initWithFrame:_notificationFrame title:aTitle message:aMessage icon:anIcon lifeTime:_defaultLifeTime background:_backgroundColor];
    var frame       = [_view frame];
    var notifFrame  = CPRectCreateCopy(_notificationFrame);
    var animParams  = [CPDictionary dictionaryWithObjectsAndKeys:notifView, CPViewAnimationTargetKey, CPViewAnimationFadeInEffect, CPViewAnimationEffectKey];
    var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animParams]];
    
    if (_useWindowMouseMoveEvents && ![[_view window] acceptsMouseMovedEvents])
        [[_view window] setAcceptsMouseMovedEvents:YES];
    
    [center addObserver:self selector:@selector(didReceivedNotificationEndLifeTime:) name:TNGrowlViewLifeTimeExpirationNotification object:notifView];
    
    notifFrame.origin.x = frame.size.width - _notificationFrame.size.width - TNGrowlPlacementMarginRight;
    notifFrame.origin.y = TNGrowlPlacementMarginTop;
     
    for (var i = 0; i < [_notifications count]; i++)
    {
        var isViewInThisFrame = NO;
        
        for (var j = 0; j < [_notifications count]; j++)
        {
            var tmpFrame = [[_notifications objectAtIndex:j] frame];
            
            if (CPRectEqualToRect(notifFrame, tmpFrame))//((notifFrame.origin.y == tmpFrame.origin.y) && (notifFrame.origin.x == tmpFrame.origin.x))
            {
                isViewInThisFrame = YES;
                break;
            }
        }
        
        if (!isViewInThisFrame)
            break;
        
        notifFrame.origin.y += _notificationFrame.size.height + TNGrowlPlacementMarginTop;    

        if ((notifFrame.origin.y + notifFrame.size.height) >= frame.size.height)
        {
            notifFrame.origin.x -= (notifFrame.size.width + TNGrowlPlacementMarginRight);
            notifFrame.origin.y = TNGrowlPlacementMarginTop;    
        }
    }
    
    [_notifications addObject:notifView];
    
    [notifView setAutoresizingMask:CPViewMinXMargin];
    [notifView setFrame:notifFrame];
    
    [_view addSubview:notifView];
    
    [anim setDuration:0.3];
    [anim startAnimation];
}

/*! Responder of the message TNGrowlViewLifeTimeExpirationNotification
    this will start fade out the TNGrowlView that sent the notification
    @param aNotification the notification
*/
- (void)didReceivedNotificationEndLifeTime:(CPNotification)aNotification
{
    var center      = [CPNotificationCenter defaultCenter];
    var senderView  = [aNotification object];
    var animView    = [CPDictionary dictionaryWithObjectsAndKeys:senderView, CPViewAnimationTargetKey, CPViewAnimationFadeOutEffect, CPViewAnimationEffectKey];
    var anim        = [[CPViewAnimation alloc] initWithViewAnimations:[animView]];

    [center removeObserver:self name:TNGrowlViewLifeTimeExpirationNotification object:senderView];

    [anim setDuration:TNGrowlAnimationDuration];
    [anim setDelegate:self];
    [anim startAnimation];
}

/*! delegate of CPAnimation. Will remove définitly the TNGrowlView
    from the superview
    @param anAnimation the animation that have ended
*/
- (void)animationDidEnd:(CPAnimation)anAnimation
{
    var senderView = [[[anAnimation viewAnimations] objectAtIndex:0] objectForKey:CPViewAnimationTargetKey];
    
    [_notifications removeObject:senderView];
    [senderView removeFromSuperview];
    
    if (_useWindowMouseMoveEvents && [[_view window] acceptsMouseMovedEvents] && [_notifications count] == 0);
        [[_view window] setAcceptsMouseMovedEvents:NO];
    
}

@end
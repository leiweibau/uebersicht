//
//  UBWindowsController.m
//  Uebersicht
//
//  Created by Felix Hageloh on 30/09/2020.
//  Copyright © 2020 tracesOf. All rights reserved.
//

#import "UBWindowsController.h"
#import "UBScreensController.h"
#import "UBWindowGroup.h"
#import "WKInspector.h"
#import "WKView.h"
#import "WKPage.h"
#import "WKWebViewInternal.h"

@import WebKit;

@implementation UBWindowsController {
    NSMutableDictionary* windows;
    UBScreensController* screensController;
    NSHashTable* monitoredDebugWindows;
}

- (id)initWithScreensController:(UBScreensController*)theScreensController
{
    self = [super init];
    if (self) {
        windows = [[NSMutableDictionary alloc] initWithCapacity:42];
        screensController = theScreensController;
        monitoredDebugWindows = [NSHashTable weakObjectsHashTable];
    }
    return self;
}


- (void)updateWindows:(NSDictionary*)screens
              baseUrl:(NSURL*)baseUrl
   interactionEnabled:(Boolean)interactionEnabled
         forceRefresh:(Boolean)forceRefresh
{
    NSMutableArray* obsoleteScreens = [[windows allKeys] mutableCopy];
    UBWindowGroup* windowGroup;
    
    for(NSString* screenId in screens) {
        if (![windows objectForKey:screenId]) {
            windowGroup = [[UBWindowGroup alloc]
                initWithInteractionEnabled: interactionEnabled
            ];
            [windows setObject:windowGroup forKey:screenId];
            [windowGroup loadUrl: [self screenUrl:screenId baseUrl:baseUrl]];
        } else {
            windowGroup = windows[screenId];
            if (forceRefresh) {
                [windowGroup reload];
            }
        }
        
        [windowGroup setFrame:[self screenRect:screenId] display:YES];
        [obsoleteScreens removeObject:screenId];
    }
    
    for (NSString* screenId in obsoleteScreens) {
        [windows[screenId] close];
        [windows removeObjectForKey:screenId];
    }
    
    NSLog(@"using %lu screens", (unsigned long)[windows count]);
}

- (NSRect)screenRect:(NSString*)screenId
{
    NSScreen* screen = [self getNSScreen:screenId];
    
    CGFloat auxiliaryHeight = screen.auxiliaryTopLeftArea.size.height;
    CGFloat windowHeight = screen.visibleFrame.size.height +
        (screen.visibleFrame.origin.y - screen.frame.origin.y);
    
    // If the remaining visible height is exactly the auxiliaryHeight, the menu
    // bar is hidden. There seems to be no other way to dedect this reliably
    if (screen.frame.size.height - windowHeight == auxiliaryHeight) {
        windowHeight = windowHeight + auxiliaryHeight;
    }

    return NSMakeRect(
        screen.frame.origin.x,
        screen.frame.origin.y,
        screen.frame.size.width,
        windowHeight
    );
}

- (NSScreen*)getNSScreen:(NSString*)screenId
{
    return [screensController screenForId:screenId];
}

- (void)reloadAll
{
    for (NSString* screenId in windows) {
        UBWindowGroup* window = windows[screenId];
        [window reload];
    }
}

- (void)closeAll
{
    for (UBWindowGroup* window in [windows allValues]) {
        [window close];
    }
    [monitoredDebugWindows removeAllObjects];
    [windows removeAllObjects];
}


- (void)showDebugConsolesForScreen:(NSString*)screenId
{
    NSWindow* window;
    window = [(UBWindowGroup*)windows[screenId] foreground];
    if (window) [self showDebugConsoleForWindow: window];
    
    window = [(UBWindowGroup*)windows[screenId] background];
    if (window) [self showDebugConsoleForWindow: window];
}

- (void)showDebugConsoleForWindow:(NSWindow*)window
{
    WKPageRef page = [self pageForWindow:window];
    
    if (page) {
        WKInspectorRef inspector = WKPageGetInspector(page);

        [NSApp activateIgnoringOtherApps:YES];
        
        WKInspectorShowConsole(inspector);
        [self
            performSelector: @selector(detachInspector:)
            withObject: (__bridge id)(inspector)
            afterDelay: 0
        ];

        if (![monitoredDebugWindows containsObject:window]) {
            [monitoredDebugWindows addObject:window];
            [self
                performSelector:@selector(closeHiddenDebugConsoleForWindow:)
                withObject:window
                afterDelay:2.0
            ];
        }
    }
}

- (void)detachInspector:(WKInspectorRef)inspector
{
     WKInspectorDetach(inspector);
}

- (WKPageRef)pageForWindow:(NSWindow*)window
{
    if (!window || !window.contentView) {
        return NULL;
    }

    SEL pageForTesting = @selector(_pageForTesting);

    if (window.contentView.subviews.count > 0) {
        NSView* firstSubview = window.contentView.subviews[0];
        if ([firstSubview isKindOfClass:[WKView class]]) {
            return ((WKView*)firstSubview).pageRef;
        }
    }

    if ([window.contentView respondsToSelector:pageForTesting]) {
        return (__bridge WKPageRef)([window.contentView performSelector:pageForTesting]);
    }

    return NULL;
}

- (void)closeHiddenDebugConsoleForWindow:(NSWindow*)window
{
    if (!window) {
        return;
    }

    WKPageRef page = [self pageForWindow:window];
    if (!page) {
        [monitoredDebugWindows removeObject:window];
        return;
    }

    WKInspectorRef inspector = WKPageGetInspector(page);
    if (!inspector) {
        [monitoredDebugWindows removeObject:window];
        return;
    }

    if (WKInspectorIsVisible(inspector)) {
        [self
            performSelector:@selector(closeHiddenDebugConsoleForWindow:)
            withObject:window
            afterDelay:1.0
        ];
        return;
    }

    if (WKInspectorIsConnected(inspector)) {
        WKInspectorClose(inspector);
    }
    [monitoredDebugWindows removeObject:window];
}

- (void)workspaceChanged
{
    for (NSString* screenId in windows) {
        [windows[screenId] workspaceChanged];
    }
}

- (void)wallpaperChanged
{
    for (NSString* screenId in windows) {
        [windows[screenId] wallpaperChanged];
    }
}

- (NSURL*)screenUrl:(NSString*)screenId baseUrl:(NSURL*)baseUrl
{
    return [baseUrl
        URLByAppendingPathComponent:[NSString
            stringWithFormat:@"%@",
            screenId
        ]
    ];
}

@end

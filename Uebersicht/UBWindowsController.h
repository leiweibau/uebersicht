//
//  UBWindowsController.h
//  Uebersicht
//
//  Created by Felix Hageloh on 30/09/2020.
//  Copyright © 2020 tracesOf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class UBScreensController;

NS_ASSUME_NONNULL_BEGIN

@interface UBWindowsController : NSObject

- (id)initWithScreensController:(UBScreensController*)screensController;

- (void)updateWindows:(NSDictionary*)screens
              baseUrl:(NSURL*)baseUrl
   interactionEnabled:(Boolean)interactionEnabled
         forceRefresh:(Boolean)forceRefresh;

- (void)reloadAll;
- (void)closeAll;
- (void)workspaceChanged;
- (void)wallpaperChanged;
- (void)showDebugConsolesForScreen:(NSString*)screenId;
- (NSScreen*)getNSScreen:(NSString*)screenId;

@end

NS_ASSUME_NONNULL_END

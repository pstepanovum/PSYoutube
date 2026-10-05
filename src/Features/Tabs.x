#import "../Utils.h"
#import "../../modules/YouTubeHeader/YTIPivotBarRenderer.h"
#import "../../modules/YouTubeHeader/YTIPivotBarSupportedRenderers.h"
#import "../../modules/YouTubeHeader/YTIPivotBarItemRenderer.h"
#import "../../modules/YouTubeHeader/YTIPivotBarIconOnlyItemRenderer.h"

// Bottom tabs (Shorts, Home, Create), and the Shorts player limited to a single Short.
// (Shorts shelves in feeds are removed in Feed.x.)

// Bottom tab IDs -> setting that hides them
static NSDictionary<NSString *, NSString *> *PSIHideableTabs(void) {
    return @{
        @"FEshorts": @"hide_shorts",
        @"FEwhat_to_watch": @"hide_home_tab",
        @"FEuploads": @"hide_create_tab"
    };
}

@interface YTPivotBarView : UIView
@end

%hook YTPivotBarView
- (void)setRenderer:(YTIPivotBarRenderer *)renderer {
    if ([renderer respondsToSelector:@selector(itemsArray)]) {
        NSIndexSet *hidden = [renderer.itemsArray indexesOfObjectsPassingTest:^BOOL(YTIPivotBarSupportedRenderers *item, NSUInteger index, BOOL *stop) {
            // Unset protobuf fields return empty values rather than nil, so take whichever identifier is filled in
            NSString *identifier = item.pivotBarItemRenderer.pivotIdentifier;
            if (!identifier.length) identifier = item.pivotBarIconOnlyItemRenderer.pivotIdentifier;

            // The create (+) button is the item without a tab identifier
            NSString *setting = identifier.length ? PSIHideableTabs()[identifier] : @"hide_create_tab";

            return setting && [PSIUtils getBoolPref:setting];
        }];

        // Never remove every tab
        if (hidden.count < renderer.itemsArray.count) [renderer.itemsArray removeObjectsAtIndexes:hidden];
    }

    %orig;
}
%end

// With the Home tab hidden, YouTube still starts on Home. Once the tab bar is up, press the Subscriptions
// button the way a tap would; selecting it in code only highlights the button and keeps Home's page.
@interface YTPivotBarViewController : UIViewController
- (NSString *)selectedPivotIdentifier;
@end

static UIControl *PSIFindControl(UIView *view, NSString *accessibilityIdentifier) {
    if ([view isKindOfClass:[UIControl class]] && [view.accessibilityIdentifier isEqualToString:accessibilityIdentifier]) return (UIControl *)view;

    for (UIView *subview in view.subviews) {
        UIControl *found = PSIFindControl(subview, accessibilityIdentifier);
        if (found) return found;
    }

    return nil;
}

static void PSIOpenSubscriptionsIfOnHome(YTPivotBarViewController *controller) {
    if (![PSIUtils getBoolPref:@"hide_home_tab"] || ![[controller selectedPivotIdentifier] isEqualToString:@"FEwhat_to_watch"]) return;

    UIControl *subscriptions = PSIFindControl(controller.view, @"id.ui.pivotbar.FEsubscriptions.button");
    PSILog(@"Opening Subscriptions instead of Home (button found: %d)", subscriptions != nil);

    [subscriptions sendActionsForControlEvents:UIControlEventTouchUpInside];
}

%hook YTPivotBarViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        PSIOpenSubscriptionsIfOnHome(self);
    });
}

// Signing in or switching accounts reloads the tab bar, which lands on Home again
- (void)loadPivotBarWithOffline:(BOOL)offline triggeredByNotification:(BOOL)notification completion:(void (^)(void))completion {
    __weak YTPivotBarViewController *weakSelf = self;
    void (^wrapped)(void) = ^{
        if (completion) completion();

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            PSIOpenSubscriptionsIfOnHome(weakSelf);
        });
    };

    %orig(offline, notification, wrapped);
}
%end

///////////////////////////////////////////////////////////

// The Shorts player: the Short you opened plays, but the vertical pager can't be scrolled to the next one

static BOOL PSIIsInsideShortsPlayer(UIView *view) {
    for (UIResponder *responder = view; responder; responder = responder.nextResponder) {
        // YTAppReelWatchRootViewController in current versions, YTReelWatchRootViewController in older ones
        NSString *name = NSStringFromClass([responder class]);
        if ([name containsString:@"ReelWatchRootViewController"] || [name isEqualToString:@"YTShortsPlayerViewController"]) return YES;
    }

    return NO;
}

// The pager is the collection view of YTScrollablePageCollectionViewController inside the Shorts player
@interface YTScrollablePageCollectionViewController : UIViewController
@end

static void PSILockShortsPager(UIViewController *controller) {
    if (![PSIUtils getBoolPref:@"hide_shorts"] || !PSIIsInsideShortsPlayer(controller.view)) return;

    for (UIView *view in controller.view.subviews) {
        if (![view isKindOfClass:[UICollectionView class]]) continue;

        UICollectionView *pager = (UICollectionView *)view;
        if (pager.scrollEnabled) PSILog(@"Locked Shorts pager");
        pager.scrollEnabled = NO;
    }

    if ([controller.view isKindOfClass:[UICollectionView class]]) ((UICollectionView *)controller.view).scrollEnabled = NO;
}

%hook YTScrollablePageCollectionViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    PSILockShortsPager(self);
}

// YouTube re-enables scrolling as pages load; lock it again after every layout pass
- (void)viewDidLayoutSubviews {
    %orig;
    PSILockShortsPager(self);
}
%end

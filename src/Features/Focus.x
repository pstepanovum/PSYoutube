#import "../Utils.h"

// Less rabbit-holing: no autoplay into recommendations, no end screen cards, no Premium promos

// Autoplay of a recommended video ("autonav") when a video ends. Playlists and queues you started
// still continue (that's "autoplay", not "autonav").
@interface YTAutoplayAutonavController : NSObject
@end

%hook YTAutoplayAutonavController
- (void)playAutonav {
    if ([PSIUtils getBoolPref:@"disable_autonav"]) return;

    %orig;
}

- (void)playAutonavEndscreenCountdown {
    if ([PSIUtils getBoolPref:@"disable_autonav"]) return;

    %orig;
}

// The "Up next in 5..." countdown
- (BOOL)canRunCountdown {
    return [PSIUtils getBoolPref:@"disable_autonav"] ? NO : %orig;
}
%end

// Suggested videos and channel cards the creator places over the last seconds of a video
@interface YTCreatorEndscreenView : UIView
@end

%hook YTCreatorEndscreenView
- (void)layoutSubviews {
    %orig;

    if ([PSIUtils getBoolPref:@"hide_endscreen_cards"]) self.hidden = YES;
}
%end

// "Try YouTube Premium" and similar promo bars
@interface YTAppMealbarPromoControllerImpl : NSObject
@end

%hook YTAppMealbarPromoControllerImpl
- (void)startWithFirstResponder:(id)responder {
    if ([PSIUtils getBoolPref:@"hide_premium_promos"]) return;

    %orig;
}
%end

// "Get Premium" buttons and "Try YouTube Premium for $0" entries (You page, menus, settings)
static BOOL PSIIsPremiumUpsell(UIView *view) {
    NSString *label = view.accessibilityLabel;
    if (!label.length) return NO;

    return [label isEqualToString:@"Get Premium"] || [label containsString:@"Try YouTube Premium"] || [label containsString:@"Get YouTube Premium"];
}

static void PSIHidePremiumUpsell(UIView *view) {
    if (![PSIUtils getBoolPref:@"hide_premium_promos"] || !PSIIsPremiumUpsell(view)) return;

    // Containers can expose the combined text of everything inside them; only hide row-sized views
    if (view.bounds.size.height > 90 || [view isKindOfClass:[UIScrollView class]]) return;

    // Hide the row the label sits in, but never a container: some pages are a single cell
    UIView *target = view;
    for (UIView *ancestor = view.superview; ancestor; ancestor = ancestor.superview) {
        if (ancestor.bounds.size.height > 90 || [ancestor isKindOfClass:[UIScrollView class]]) break;
        target = ancestor;
    }

    target.hidden = YES;
}

%hook UIButton
- (void)didMoveToWindow {
    %orig;
    PSIHidePremiumUpsell(self);
}
%end

@interface _ASDisplayView : UIView
@end

%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    PSIHidePremiumUpsell(self);
}
%end

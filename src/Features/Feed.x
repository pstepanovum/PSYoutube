#import "../Utils.h"
#import "../../modules/YouTubeHeader/YTIItemSectionRenderer.h"
#import "../../modules/YouTubeHeader/YTIItemSectionSupportedRenderers.h"
#import "../../modules/YouTubeHeader/YTIElementRenderer.h"
#import "../../modules/YouTubeHeader/YTIElementRendererCompatibilityOptions.h"

// Video ads: the player response lists ads to play before/during a video; hand back empty lists,
// and never create the coordinator that plays them

@interface YTIPlayerResponse : NSObject
@end

@interface YTLocalPlaybackController : NSObject
@end

%hook YTIPlayerResponse
- (NSMutableArray *)playerAdsArray {
    return [PSIUtils getBoolPref:@"block_ads"] ? [NSMutableArray array] : %orig;
}

- (NSMutableArray *)adSlotsArray {
    return [PSIUtils getBoolPref:@"block_ads"] ? [NSMutableArray array] : %orig;
}
%end

%hook YTLocalPlaybackController
- (id)createAdsPlaybackCoordinator {
    return [PSIUtils getBoolPref:@"block_ads"] ? nil : %orig;
}
%end

///////////////////////////////////////////////////////////

// Feeds (home, search, watch next): remove ads (promoted renderers, and elements that carry
// ad logging data) and Shorts shelves (elements built from the Shorts shelf templates)

static BOOL PSIIsAdItem(YTIItemSectionSupportedRenderers *item) {
    if (item.hasPromotedVideoRenderer || item.hasPromotedVideoInlineMutedRenderer || item.hasCompactPromotedVideoRenderer) return YES;

    YTIElementRenderer *element = item.elementRenderer;
    return element && element.hasCompatibilityOptions && element.compatibilityOptions.hasAdLoggingData;
}

static BOOL PSIIsShortsItem(YTIItemSectionSupportedRenderers *item) {
    YTIElementRenderer *element = item.elementRenderer;
    if (!element) return NO;

    NSString *description = [element description];
    return [description containsString:@"shorts_shelf.eml"] || [description containsString:@"shorts_video_cell.eml"];
}

static BOOL PSIShouldRemoveItem(id item) {
    if (![item isKindOfClass:%c(YTIItemSectionSupportedRenderers)]) return NO;


    if ([PSIUtils getBoolPref:@"block_ads"] && PSIIsAdItem(item)) return YES;
    if ([PSIUtils getBoolPref:@"hide_shorts"] && PSIIsShortsItem(item)) return YES;

    return NO;
}

static NSArray *PSIFilterSections(NSArray *sections) {
    NSMutableArray *kept = [NSMutableArray array];
    for (id section in sections) {
        if ([section isKindOfClass:%c(YTIItemSectionRenderer)]) {
            NSMutableArray *contents = ((YTIItemSectionRenderer *)section).contentsArray;
            NSIndexSet *removed = [contents indexesOfObjectsPassingTest:^BOOL(id item, NSUInteger index, BOOL *stop) {
                return PSIShouldRemoveItem(item);
            }];
            [contents removeObjectsAtIndexes:removed];

            // Drop sections that are now empty
            if (contents.count == 0 && removed.count > 0) continue;
        }

        [kept addObject:section];
    }

    return kept;
}

@interface YTInnerTubeCollectionViewController : UIViewController
@end

%hook YTInnerTubeCollectionViewController
- (void)addSectionsFromArray:(NSArray *)array {
    %orig(PSIFilterSections(array));
}

// YouTube sometimes draws the You page far below its content once it has loaded (a blank screen until
// it's scrolled). Scroll it to the top once the content is in, which settles the layout.
- (void)displaySectionsWithReloadingSectionControllerByRenderer:(id)renderer {
    %orig;

    __weak UIViewController *weakSelf = (UIViewController *)self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIScrollView *scrollView = nil;
        for (UIView *view = weakSelf.view; view && !scrollView; view = view.subviews.firstObject) {
            if ([view isKindOfClass:[UIScrollView class]]) scrollView = (UIScrollView *)view;
        }
        if (!scrollView || scrollView.isDragging) return;

        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -scrollView.adjustedContentInset.top) animated:YES];
    });
}
%end

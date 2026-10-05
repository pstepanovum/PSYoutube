#import "Utils.h"
#import "Tweak.h"
#import "Settings/PSISettingsBackup.h"

// * Tweak version *
NSString *PSIVersionString = @"v0.1.0";

// Settings are set up before any YouTube code runs, so no feature can read them unset
static void PSISetupSettings(void) {
    // Bring back settings from before a reinstall
    [PSISettingsBackup restoreIfNeeded];

    // Default config
    NSDictionary *psiDefaults = @{
        @"background_playback": @(YES),
        @"block_ads": @(YES),
        @"hide_shorts": @(YES),
        @"hide_home_tab": @(YES),
        @"hide_create_tab": @(YES),
        @"hide_search_history": @(YES),
        @"disable_autonav": @(YES),
        @"hide_endscreen_cards": @(YES),
        @"hide_premium_promos": @(YES),
        @"fix_playback": @(YES),
        @"sb_sponsor": @(YES),
        @"sb_selfpromo": @(YES),
        @"sb_interaction": @(YES),
        @"sb_intro": @(NO),
        @"sb_outro": @(NO),
        @"sb_preview": @(NO),
        @"sb_music_offtopic": @(NO),
        @"sb_filler": @(NO),
        @"flex_gesture": @(NO)
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:psiDefaults];
}

///////////////////////////////////////////////////////////

// Settings and FLEX access: hold 4 fingers for settings, 5 fingers for FLEX (when enabled)
@interface PSIGestureHandler : NSObject
@end

@implementation PSIGestureHandler
- (void)handleSettingsGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    [PSIUtils showSettingsVC:sender.view.window];
}
- (void)handleFlexGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan || ![PSIUtils getBoolPref:@"flex_gesture"]) return;

    id manager = ((id (*)(id, SEL))objc_msgSend)((id)objc_getClass("FLEXManager"), sel_registerName("sharedManager"));
    ((void (*)(id, SEL))objc_msgSend)(manager, sel_registerName("showExplorer"));
}
@end

static PSIGestureHandler *gestureHandler;

%hook UIWindow
- (void)becomeKeyWindow {
    %orig;

    if ([objc_getAssociatedObject(self, _cmd) boolValue]) return;
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (!gestureHandler) gestureHandler = [PSIGestureHandler new];

    UILongPressGestureRecognizer *settingsGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:gestureHandler action:@selector(handleSettingsGesture:)];
    settingsGesture.minimumPressDuration = 1;
    settingsGesture.numberOfTouchesRequired = 4;
    settingsGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:settingsGesture];

    UILongPressGestureRecognizer *flexGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:gestureHandler action:@selector(handleFlexGesture:)];
    flexGesture.minimumPressDuration = 1;
    flexGesture.numberOfTouchesRequired = 5;
    flexGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:flexGesture];
}
%end

// PSYoutube section at the top of YouTube's own Settings screen.
// YouTube builds its settings from numbered categories; we add our own category to the first
// settings group and fill it in when YouTube asks for its items.
static const NSInteger PSISettingsCategory = 'psyt';

@interface YTSettingsViewController : UIViewController
- (void)setSectionItems:(NSMutableArray *)sectionItems forCategory:(NSInteger)category title:(NSString *)title icon:(id)icon titleDescription:(NSString *)titleDescription headerHidden:(BOOL)headerHidden;
- (NSMutableDictionary *)settingsSectionControllers;
@end

@interface YTSettingsSectionItem : NSObject
+ (instancetype)itemWithTitle:(NSString *)title titleDescription:(NSString *)titleDescription accessibilityIdentifier:(NSString *)accessibilityIdentifier detailTextBlock:(id)detailTextBlock selectBlock:(BOOL (^)(id cell, NSUInteger arg))selectBlock;
@end

@interface YTIIcon : NSObject
@property (nonatomic, assign) int iconType;
@end

@interface YTSettingsSectionItemManager : NSObject
- (id)parentResponder;
@end

@interface YTSettingsGroupData : NSObject
@end

%hook YTSettingsGroupData
- (NSArray<NSNumber *> *)orderedCategoriesForGroupType:(NSUInteger)groupType {
    NSArray *categories = %orig;

    // The first group shown (1, the account group) gets our category at the top
    if (groupType == 1 && ![categories containsObject:@(PSISettingsCategory)]) {
        return [@[@(PSISettingsCategory)] arrayByAddingObjectsFromArray:categories ?: @[]];
    }

    return categories;
}
%end

%hook YTAppSettingsPresentationData
+ (NSArray *)settingsCategoryOrder {
    NSArray *order = %orig;
    if ([order containsObject:@(PSISettingsCategory)]) return order;

    return [@[@(PSISettingsCategory)] arrayByAddingObjectsFromArray:order ?: @[]];
}
%end

// YouTube only creates sections for categories its server sends; create ours before rows are arranged
static BOOL PSIAddingSettingsSection;

static void PSIAddSettingsSection(YTSettingsViewController *settingsViewController) {
    if (PSIAddingSettingsSection || ![settingsViewController respondsToSelector:@selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:)]) return;
    PSIAddingSettingsSection = YES;

    YTSettingsSectionItem *item = [%c(YTSettingsSectionItem) itemWithTitle:@"PSYoutube settings"
                                                          titleDescription:@"Background playback, ads, SponsorBlock, Shorts and more"
                                                   accessibilityIdentifier:@"PSYoutubeSettings"
                                                           detailTextBlock:nil
                                                               selectBlock:^BOOL(id cell, NSUInteger arg) {
        [PSIUtils showSettingsVC:settingsViewController.view.window];
        return YES;
    }];

    // YouTube's "tune" (sliders) icon, like the other settings rows
    YTIIcon *icon = [%c(YTIIcon) new];
    icon.iconType = 530;

    [settingsViewController setSectionItems:[NSMutableArray arrayWithObject:item] forCategory:PSISettingsCategory title:@"PSYoutube" icon:icon titleDescription:nil headerHidden:NO];

    PSIAddingSettingsSection = NO;
}

// Tapping our row would open YouTube's own (empty) page for the category; open the PSYoutube settings instead
static BOOL PSIViewContainsText(UIView *view, NSString *text) {
    if ([view.accessibilityLabel containsString:text]) return YES;
    if ([view isKindOfClass:[UILabel class]] && [((UILabel *)view).text isEqualToString:text]) return YES;

    for (UIView *subview in view.subviews) {
        if (PSIViewContainsText(subview, text)) return YES;
    }

    return NO;
}

%hook YTSettingsViewController
- (void)organizeSectionControllersInGroups {
    PSIAddSettingsSection(self);

    %orig;
}
%end

// The list inside each settings page handles taps; open the PSYoutube settings when our row is tapped
@interface YTCollectionViewController : UIViewController
@end

%hook YTCollectionViewController
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.parentViewController isKindOfClass:%c(YTSettingsViewController)]) {
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (cell && PSIViewContainsText(cell, @"PSYoutube")) {
            [collectionView deselectItemAtIndexPath:indexPath animated:YES];
            [PSIUtils showSettingsVC:self.view.window];
            return;
        }
    }

    %orig;
}
%end

%hook YTSettingsSectionItemManager
- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category != PSISettingsCategory) {
        %orig;
        return;
    }

    PSIAddSettingsSection([self parentResponder]);
}
%end

%ctor {
    PSISetupSettings();

    %init;
}

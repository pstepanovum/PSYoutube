#import "TweakSettings.h"
#import "PSISettingsBackup.h"

@implementation PSITweakSettings

// MARK: - Sections

///
/// This returns an array of sections, with each section consisting of a dictionary
///
/// `"title"`: The section title (leave blank for no title)
///
/// `"rows"`: An array of **PSISetting** classes, potentially containing a "navigationCellWithTitle" initializer to allow for nested setting pages.
///
/// `"footer`: The section footer (leave blank for no footer)

+ (NSArray *)sections {
    return @[
        @{
            @"header": @"Playback",
            @"rows": @[
                [PSISetting switchCellWithTitle:@"Background playback" subtitle:@"Keep playing when the app is in the background or the screen is locked" defaultsKey:@"background_playback" requiresRestart:YES],
                [PSISetting switchCellWithTitle:@"Playback fixes" subtitle:@"Avoids \"Something went wrong. Tap to retry\" on re-signed installs" defaultsKey:@"fix_playback" requiresRestart:YES]
            ]
        },
        @{
            @"header": @"Tabs",
            @"rows": @[
                [PSISetting switchCellWithTitle:@"Hide Home tab" subtitle:@"Removes the recommendations feed; the app opens on Subscriptions" defaultsKey:@"hide_home_tab" requiresRestart:YES],
                [PSISetting switchCellWithTitle:@"Hide Shorts" subtitle:@"Removes the Shorts tab and shelves; a Short you open plays, but you can't scroll to the next" defaultsKey:@"hide_shorts" requiresRestart:YES],
                [PSISetting switchCellWithTitle:@"Hide Create tab" subtitle:@"Removes the + (upload) button" defaultsKey:@"hide_create_tab" requiresRestart:YES]
            ]
        },
        @{
            @"header": @"Focus",
            @"rows": @[
                [PSISetting switchCellWithTitle:@"No autoplay of recommendations" subtitle:@"When a video ends, nothing new starts by itself (playlists still continue)" defaultsKey:@"disable_autonav"],
                [PSISetting switchCellWithTitle:@"Hide recommended videos" subtitle:@"No list of suggested videos under the one you're watching; the description and comments stay" defaultsKey:@"hide_related_videos"],
                [PSISetting switchCellWithTitle:@"Hide end screen cards" subtitle:@"Hides the suggested videos placed over the last seconds of a video" defaultsKey:@"hide_endscreen_cards"],
                [PSISetting switchCellWithTitle:@"Hide Premium promos" subtitle:@"No \"Try YouTube Premium\" bars" defaultsKey:@"hide_premium_promos"],
                [PSISetting switchCellWithTitle:@"No trending or search history" subtitle:@"Nothing is shown under the search bar until you type. To stop recording history, pause it in YouTube: Settings > Manage all history" defaultsKey:@"hide_search_history"]
            ]
        },
        @{
            @"header": @"Ads",
            @"rows": @[
                [PSISetting switchCellWithTitle:@"Block ads" subtitle:@"Removes video ads and promoted items in feeds" defaultsKey:@"block_ads" requiresRestart:YES]
            ]
        },
        @{
            @"header": @"SponsorBlock",
            @"rows": @[
                [PSISetting switchCellWithTitle:@"Sponsors" subtitle:@"Paid promotions and sponsorships" defaultsKey:@"sb_sponsor"],
                [PSISetting switchCellWithTitle:@"Self-promotion" subtitle:@"Unpaid promotion of the creator's own merch or channels" defaultsKey:@"sb_selfpromo"],
                [PSISetting switchCellWithTitle:@"Interaction reminders" subtitle:@"\"Like and subscribe\" reminders" defaultsKey:@"sb_interaction"],
                [PSISetting switchCellWithTitle:@"Intros" subtitle:@"Intro animations and intermissions" defaultsKey:@"sb_intro"],
                [PSISetting switchCellWithTitle:@"Endcards and credits" subtitle:@"Outros and end screens" defaultsKey:@"sb_outro"],
                [PSISetting switchCellWithTitle:@"Previews and recaps" subtitle:@"Previews of what's coming and recaps" defaultsKey:@"sb_preview"],
                [PSISetting switchCellWithTitle:@"Filler" subtitle:@"Tangents and jokes not needed for the main content" defaultsKey:@"sb_filler"],
                [PSISetting switchCellWithTitle:@"Non-music sections" subtitle:@"Talking parts in music videos" defaultsKey:@"sb_music_offtopic"],
                [PSISetting linkCellWithTitle:@"About SponsorBlock" subtitle:@"Segments submitted by the SponsorBlock community" icon:[PSISymbol symbolWithName:@"forward.end"] url:@"https://sponsor.ajay.app"]
            ],
            @"footer": @"Skipped automatically, once per video. Data by SponsorBlock (CC BY-NC-SA 4.0)."
        },
        @{
            @"header": @"Debug",
            @"rows": @[
                [PSISetting switchCellWithTitle:@"Enable FLEX gesture" subtitle:@"Hold 5 fingers on the screen to open the FLEX explorer" defaultsKey:@"flex_gesture"]
            ]
        },
        @{
            @"header": @"About",
            @"rows": @[
                [PSISetting linkCellWithTitle:@"GitHub" subtitle:@"@pstepanovum" icon:[PSISymbol symbolWithName:@"person.crop.circle"] url:@"https://github.com/pstepanovum"],
                [PSISetting linkCellWithTitle:@"Repository" subtitle:@"pstepanovum/PSYoutube" icon:[PSISymbol symbolWithName:@"chevron.left.forwardslash.chevron.right"] url:@"https://github.com/pstepanovum/PSYoutube"]
            ],
            @"footer": [NSString stringWithFormat:@"PSYoutube %@\n\nYouTube v%@", PSIVersionString, [PSIUtils appVersionString]]
        }
    ];
}


// MARK: - Title

+ (NSString *)title {
    return @"PSYoutube Settings";
}


// MARK: - Menus

+ (NSDictionary *)menus {
    return @{};
}

@end

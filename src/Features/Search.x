#import "../Utils.h"

// Search without trending searches or history: nothing is shown under an empty search bar,
// and the search history stored on the device isn't offered. Autocomplete while typing stays.

@interface YTSearchSuggestionsController : NSObject
@end

%hook YTSearchSuggestionsController
// Trending searches and history shown before typing ("zero state")
- (void)makeZeroStateRequestWithRefresh:(BOOL)refresh {
    if ([PSIUtils getBoolPref:@"hide_search_history"]) return;

    %orig;
}

- (void)makeZeroStateSuggestRequestWithResponseBlock:(id)responseBlock errorBlock:(id)errorBlock refresh:(BOOL)refresh fromBackground:(BOOL)fromBackground {
    if ([PSIUtils getBoolPref:@"hide_search_history"]) return;

    %orig;
}

- (void)makePersonalizedSuggestRequestAfterDelay:(double)delay {
    if ([PSIUtils getBoolPref:@"hide_search_history"]) return;

    %orig;
}

// Search history kept on the device
- (NSArray *)localSuggestions {
    return [PSIUtils getBoolPref:@"hide_search_history"] ? @[] : %orig;
}
%end

#import "../Utils.h"

// Playback fixes for re-signed installs, against "Something went wrong. Tap to retry":
// don't attach the encoded client integrity context to playback requests, and send empty
// spam signals, both of which a re-signed app can fail

@interface YTHotConfig : NSObject
@end

@interface YTAdShieldUtils : NSObject
@end

@interface YTDataUtils : NSObject
@end

%hook YTHotConfig
- (BOOL)clientInfraClientConfigIosEnableFillingEncodedHacksInnertubeContext {
    return [PSIUtils getBoolPref:@"fix_playback"] ? NO : %orig;
}
%end

%hook YTAdShieldUtils
+ (id)spamSignalsDictionary {
    return [PSIUtils getBoolPref:@"fix_playback"] ? @{} : %orig;
}
+ (id)spamSignalsDictionaryWithoutIDFA {
    return [PSIUtils getBoolPref:@"fix_playback"] ? @{} : %orig;
}
%end

%hook YTDataUtils
+ (id)spamSignalsDictionary {
    return [PSIUtils getBoolPref:@"fix_playback"] ? @{ @"ms": @"" } : %orig;
}
+ (id)spamSignalsDictionaryWithoutIDFA {
    return [PSIUtils getBoolPref:@"fix_playback"] ? @{} : %orig;
}
%end

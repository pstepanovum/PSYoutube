#import "../Utils.h"

// Keep playing when the app goes to the background or the screen locks.
// YouTube asks the video's playability status and the media layer whether background playback is allowed.

@interface YTIPlayabilityStatus : NSObject
@end

@interface MLVideo : NSObject
@end

%hook YTIPlayabilityStatus
- (BOOL)isPlayableInBackground {
    return [PSIUtils getBoolPref:@"background_playback"] ? YES : %orig;
}
%end

%hook MLVideo
- (BOOL)playableInBackground {
    return [PSIUtils getBoolPref:@"background_playback"] ? YES : %orig;
}
%end

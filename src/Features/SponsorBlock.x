#import <CommonCrypto/CommonDigest.h>
#import "../Utils.h"
#import "../../modules/YouTubeHeader/YTPlayerViewController.h"
#import "../../modules/YouTubeHeader/YTSingleVideoTime.h"

// Automatic skipping of sponsor segments (and other categories) using SponsorBlock, https://sponsor.ajay.app
// SponsorBlock data by Ajay Ramachandran and contributors, CC BY-NC-SA 4.0

static NSString *const PSISponsorBlockAPI = @"https://sponsor.ajay.app/api/skipSegments/";

// Settings key -> SponsorBlock category
static NSDictionary<NSString *, NSString *> *PSISponsorBlockCategories(void) {
    return @{
        @"sb_sponsor": @"sponsor",
        @"sb_selfpromo": @"selfpromo",
        @"sb_interaction": @"interaction",
        @"sb_intro": @"intro",
        @"sb_outro": @"outro",
        @"sb_preview": @"preview",
        @"sb_music_offtopic": @"music_offtopic",
        @"sb_filler": @"filler"
    };
}

static NSString *PSISponsorBlockCategoryName(NSString *category) {
    return @{
        @"sponsor": @"sponsor",
        @"selfpromo": @"self-promotion",
        @"interaction": @"interaction reminder",
        @"intro": @"intro",
        @"outro": @"outro",
        @"preview": @"preview",
        @"music_offtopic": @"non-music section",
        @"filler": @"filler"
    }[category] ?: category;
}

// Video ID -> segments ({ "category", "start", "end", "UUID" }), fetched once per video
static NSMutableDictionary<NSString *, NSArray *> *PSISegmentsByVideo;
static NSMutableSet<NSString *> *PSIFetchingVideos;

// Segments already skipped in the current video, so rewinding into one is allowed
static NSMutableSet<NSString *> *PSISkippedSegments;
static NSString *PSISkippedVideo;

static NSString *PSIHashPrefix(NSString *videoID) {
    NSData *data = [videoID dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);

    return [NSString stringWithFormat:@"%02x%02x", digest[0], digest[1]];
}

static void PSIFetchSegments(NSString *videoID) {
    if (!PSISegmentsByVideo) {
        PSISegmentsByVideo = [NSMutableDictionary dictionary];
        PSIFetchingVideos = [NSMutableSet set];
    }
    if (PSISegmentsByVideo[videoID] || [PSIFetchingVideos containsObject:videoID]) return;

    NSMutableArray *categories = [NSMutableArray array];
    [PSISponsorBlockCategories() enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *category, BOOL *stop) {
        if ([PSIUtils getBoolPref:key]) [categories addObject:category];
    }];
    if (categories.count == 0) return;

    [PSIFetchingVideos addObject:videoID];

    // Only a 4-character hash prefix is sent; the matching video is picked out locally
    NSData *categoriesJSON = [NSJSONSerialization dataWithJSONObject:categories options:0 error:nil];
    NSURLComponents *components = [NSURLComponents componentsWithString:[PSISponsorBlockAPI stringByAppendingString:PSIHashPrefix(videoID)]];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"categories" value:[[NSString alloc] initWithData:categoriesJSON encoding:NSUTF8StringEncoding]],
        [NSURLQueryItem queryItemWithName:@"actionType" value:@"skip"]
    ];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:components.URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSMutableArray *segments = [NSMutableArray array];

        NSArray *videos = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if ([videos isKindOfClass:[NSArray class]]) {
            for (NSDictionary *video in videos) {
                if (![video isKindOfClass:[NSDictionary class]] || ![video[@"videoID"] isEqualToString:videoID]) continue;

                for (NSDictionary *segment in video[@"segments"]) {
                    NSArray *range = segment[@"segment"];
                    if (![range isKindOfClass:[NSArray class]] || range.count != 2) continue;

                    [segments addObject:@{
                        @"category": segment[@"category"] ?: @"",
                        @"start": range[0],
                        @"end": range[1],
                        @"UUID": segment[@"UUID"] ?: [NSUUID UUID].UUIDString
                    }];
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [PSIFetchingVideos removeObject:videoID];

            // A failed request (offline) is retried next time; "no segments" is remembered
            if (!error) PSISegmentsByVideo[videoID] = segments;

            if (segments.count) PSILog(@"SponsorBlock: %lu segment(s) for %@", (unsigned long)segments.count, videoID);
        });
    }];
    [task resume];
}

static void PSIShowSkipNotice(UIView *container, NSString *text) {
    if (!container) return;

    UILabel *label = [UILabel new];
    label.text = [NSString stringWithFormat:@"  Skipped %@  ", text];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    label.layer.cornerRadius = 8;
    label.layer.masksToBounds = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-24],
        [label.heightAnchor constraintEqualToConstant:28]
    ]];

    [UIView animateWithDuration:0.3 delay:1.5 options:0 animations:^{
        label.alpha = 0;
    } completion:^(BOOL finished) {
        [label removeFromSuperview];
    }];
}

%hook YTPlayerViewController
- (void)singleVideo:(id)video currentVideoTimeDidChange:(YTSingleVideoTime *)time {
    %orig;

    if (self.isPlayingAd) return;

    NSString *videoID = [self currentVideoID];
    if (!videoID.length) return;

    if (![videoID isEqualToString:PSISkippedVideo]) {
        PSISkippedVideo = videoID;
        PSISkippedSegments = [NSMutableSet set];
    }

    NSArray *segments = PSISegmentsByVideo[videoID];
    if (!segments) {
        PSIFetchSegments(videoID);
        return;
    }

    CGFloat now = time.time;
    for (NSDictionary *segment in segments) {
        CGFloat start = [segment[@"start"] doubleValue];
        CGFloat end = [segment[@"end"] doubleValue];

        if (now < start || now >= end - 0.5 || [PSISkippedSegments containsObject:segment[@"UUID"]]) continue;

        [PSISkippedSegments addObject:segment[@"UUID"]];
        [self seekToTime:end];

        PSILog(@"SponsorBlock: skipped %@ %.1f-%.1f", segment[@"category"], start, end);
        PSIShowSkipNotice(self.view, PSISponsorBlockCategoryName(segment[@"category"]));
        break;
    }
}
%end

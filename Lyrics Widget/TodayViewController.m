//
//  TodayViewController.m
//  Lyrics Widget
//
//  Created by Hamed on 9/9/1398 AP.
//  Copyright © 1398 Hamed. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "iTunes.h"
#import "Music.h"
#import "Spotify.h"
#import "LyricsFinder.h"


@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, readonly) MusicApplication *MusicApp;
@property (nonatomic, readonly) iTunesApplication *iTunesApp;
@property (nonatomic, readonly) SpotifyApplication *SpotifyApp;


@property (nonatomic, weak) IBOutlet NSImageView *artworkImageView;

@property (nonatomic, weak) IBOutlet NSTextField *trackNameLabel;

@property (nonatomic, weak) IBOutlet NSTextField *artistNameAndAlbumNameLabel;
@property (nonatomic, weak) IBOutlet NSTextField *trackLyrics;

@property (weak) IBOutlet NSLayoutConstraint *imagewidth;
@property (weak) IBOutlet NSLayoutConstraint *imageheight;

@end

@implementation TodayViewController


- (void)viewWillAppear
{
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView:) name:@"com.apple.Music.playerInfo" object:nil];
}

- (void)viewWillDisappear
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Private Method
- (void)updateView:(NSNotification *)notification
{
    
    if(self.MusicApp.running && self.MusicApp.playerState == MusicEPlSPlaying) {
        MusicTrack *track = self.MusicApp.currentTrack;
        self.view.hidden = NO;
        
        NSString *trackName = track.name;
        NSString *artistName = track.artist;
        NSString *albumName = track.album;
        
        self.trackNameLabel.stringValue = trackName ? trackName : @"";
        self.artistNameAndAlbumNameLabel.stringValue = [NSString stringWithFormat:@"%@%@%@", artistName ? artistName : @"", (artistName.length && albumName.length) ? @" - " : @"", albumName ? albumName : @""];
        
        
        
        if (![[[self.MusicApp currentTrack] lyrics]  isEqual: @""] ){
            
            self.trackLyrics.stringValue = [[self.MusicApp currentTrack] lyrics];
            
        }
        else{
            
            self.trackLyrics.stringValue =  @"" ;
            
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            dispatch_async(queue, ^{
                NSString *lyrics = [LyricsFinder findLyricsOf:[track name]by:[track artist]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.trackLyrics.stringValue =  lyrics ;
                    if (![lyrics isEqual: @""] ){
                        
                        
                        track.lyrics=lyrics;
                        
                    }
                    
                });
            });
            
            
        }
        
        
        MusicArtwork *artwork = track.artworks.firstObject;
        NSImage *artworkImage = [[NSImage alloc] init];
        
        // For some reason in the Music app sometimes the expected return of NSImage from trackArt.data
        // is instead an NSAppleEventDescriptor containing raw data otherwise it's an image like normal.
        // Also trackArt.rawData appears to be no longer used and empty :(
        if ([artwork.data.className isEqualToString:@"NSAppleEventDescriptor"]) {
            NSAppleEventDescriptor *t = (NSAppleEventDescriptor*)artwork.data;
            NSData *d = t.data;
            artworkImage = [[NSImage alloc] initWithData:d];
        } else {
            artworkImage = artwork.data;
        }
        
                
        if(!artworkImage) {
            NSImage *placeholder = [NSImage imageNamed:@"musicArtwork"];
            artworkImage = placeholder;
        }
        self.artworkImageView.image = artworkImage;

    }
    else if(self.iTunesApp.running && self.iTunesApp.playerState == iTunesEPlSPlaying) {
        iTunesTrack *track = self.iTunesApp.currentTrack;
        self.view.hidden = NO;
        
        NSString *trackName = track.name;
        NSString *artistName = track.artist;
        NSString *albumName = track.album;
        
        self.trackNameLabel.stringValue = trackName ? trackName : @"";
        self.artistNameAndAlbumNameLabel.stringValue = [NSString stringWithFormat:@"%@%@%@", artistName ? artistName : @"", (artistName.length && albumName.length) ? @" - " : @"", albumName ? albumName : @""];
        
        
        
        if (![[[self.iTunesApp currentTrack] lyrics]  isEqual: @""] ){
            
            self.trackLyrics.stringValue = [[self.iTunesApp currentTrack] lyrics];
            
        }
        else{
            
            self.trackLyrics.stringValue =  @"" ;
            
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
            dispatch_async(queue, ^{
                NSString *lyrics = [LyricsFinder findLyricsOf:[track name]by:[track artist]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.trackLyrics.stringValue =  lyrics ;
                    if (![lyrics isEqual: @""] ){
                        
                        
                        track.lyrics=lyrics;
                        
                    }
                    
                });
            });
            
            
        }
        
        
        iTunesArtwork *artwork = track.artworks[0];
        
        NSImage *artworkImage = [[NSImage alloc] initWithData:artwork.rawData];
        if(!artworkImage) {
            NSImage *placeholder = [NSImage imageNamed:@"musicArtwork"];
            artworkImage = placeholder;
        }
        self.artworkImageView.image = artworkImage;
        
    }
    else if (self.SpotifyApp.running && self.SpotifyApp.playerState == SpotifyEPlSPlaying) {
        self.view.hidden = NO;
        SpotifyTrack *spotifytrack = self.SpotifyApp.currentTrack;
        NSString *trackName = spotifytrack.name;
        NSString *artistName = spotifytrack.artist;
        NSString *albumName = spotifytrack.album;
        
        
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@" -.*remaster.*" options:NSRegularExpressionCaseInsensitive error:&error];
        
        trackName = [regex stringByReplacingMatchesInString:trackName options:0 range:NSMakeRange(0, [trackName length]) withTemplate:@""];
        
        self.trackNameLabel.stringValue = trackName ? trackName : @"";
        self.artistNameAndAlbumNameLabel.stringValue = [NSString stringWithFormat:@"%@%@%@", artistName ? artistName : @"", (artistName.length && albumName.length) ? @" - " : @"", albumName ? albumName : @""];

        self.trackLyrics.stringValue =  @"" ;
        
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(queue, ^{
            NSString *lyrics = [LyricsFinder findLyricsOf:trackName by:artistName];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.trackLyrics.stringValue =  lyrics ;
                
            });
        });
        
        NSLog(@"artwork '%@'", spotifytrack.artworkUrl);

        NSImage *artworkImage = [[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString: spotifytrack.artworkUrl]];

        
        if(!artworkImage) {
            NSImage *placeholder = [NSImage imageNamed:@"musicArtwork"];
            artworkImage = placeholder;
        }
        self.artworkImageView.image = artworkImage;
    }
    else {
        self.view.hidden = YES;
        self.imageheight.constant=0;
        self.imagewidth.constant=0;
    }
}


#pragma mark -
#pragma mark Accessor Method
- (MusicApplication *)MusicApp
{
    static MusicApplication *MusicApp = nil;
    if(!MusicApp) {
        MusicApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.Music"];
        
    }
    return MusicApp;
}

- (iTunesApplication *)iTunesApp
{
    static iTunesApplication *iTunesApp = nil;
    if(!iTunesApp) {
        iTunesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        
    }
    return iTunesApp;
}

- (SpotifyApplication *)SpotifyApp
{
    static SpotifyApplication *SpotifyApp = nil;
    if(!SpotifyApp) {
        SpotifyApp = [SBApplication applicationWithBundleIdentifier:@"com.spotify.client"];
        
    }
    return SpotifyApp;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    [self updateView:nil];
    
    completionHandler(NCUpdateResultNewData);
}

@end


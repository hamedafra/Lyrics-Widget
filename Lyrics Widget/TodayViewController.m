//
//  TodayViewController.m
//  Lyrics Widget
//
//  Created by Hamed on 5/24/16.
//  Copyright © 2016 Hamed. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "iTunes.h"
#import "LyricsFinder.h"


@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, readonly) iTunesApplication *iTunesApp;
@property (nonatomic, weak) IBOutlet NSImageView *artworkImageView;

@property (nonatomic, weak) IBOutlet NSTextField *trackNameLabel;

@property (nonatomic, weak) IBOutlet NSTextField *artistNameAndAlbumNameLabel;
@property (nonatomic, weak) IBOutlet NSTextField *trackLyrics;


@end

@implementation TodayViewController


- (void)viewWillAppear
{
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView:) name:@"com.apple.iTunes.playerInfo" object:nil];
}

- (void)viewWillDisappear
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Private Method
- (void)updateView:(NSNotification *)notification
{
    
    iTunesTrack *track = self.iTunesApp.currentTrack;
    if(self.iTunesApp.running && track.persistentID) {
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
            NSImage *placeholder = [NSImage imageNamed:@"ArtworkPlaceholder"];
            artworkImage = placeholder;
        }
        self.artworkImageView.image = artworkImage;
    }
    else {
        self.view.hidden = YES;
    }
}


#pragma mark -
#pragma mark Accessor Method
- (iTunesApplication *)iTunesApp
{
    static iTunesApplication *iTunesApp = nil;
    if(!iTunesApp) {
        iTunesApp = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
        
    }
    return iTunesApp;
}


- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler {
    [self updateView:nil];
    
    completionHandler(NCUpdateResultNewData);
}

@end


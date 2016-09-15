//
//  LyricsFinder.h
//  Created by Hamed on 5/24/16.
//  Copyright © 2016 Hamed. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@interface LyricsFinder : NSObject

+ (NSString *)findLyricsOf:(NSString *)title by:(NSString *)artist;
+ (BOOL)validateLyrics:(NSString *)lyrics;

@end

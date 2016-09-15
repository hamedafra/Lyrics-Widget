//
//  LyricsFinder.m
//  Created by Hamed on 5/24/16.
//  Copyright © 2016 Hamed. All rights reserved.
//
//
#import "LyricsFinder.h"

@implementation LyricsFinder

/**
 * replace whitespaces by underscores and escape special URI characters
 */
+(NSString *) escapeUri:(NSString *)uri withSeparator:(NSString *)separator
{
  uri = [uri stringByReplacingOccurrencesOfString:@" "
                                       withString:separator];
  
  CFStringRef escapedURI = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                   (CFStringRef)uri,
                                                                   NULL,
                                                                   (CFStringRef)@";/?:@&=+$,",
                                                                   kCFStringEncodingUTF8);
  return ((NSString *) CFBridgingRelease(escapedURI));
}

/**
 * create azlyrics URL
 */
+(NSString *) createazLyricsUrl:(NSString *)title by:(NSString *)artist
{
    NSString *url = @"http://www.azlyrics.com/lyrics/";
    
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^the " options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *artistname = [regex stringByReplacingMatchesInString:artist options:0 range:NSMakeRange(0, [artist length]) withTemplate:@""];
    artistname= [[artistname componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    artistname= [artistname lowercaseString];



    


    url = [url stringByAppendingString:artistname];
    url = [url stringByAppendingString:@"/"];
    NSString *song= [[title componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    song= [song lowercaseString];
    url = [url stringByAppendingString:song];
    url = [url stringByAppendingString:@".html"];
    return url;
}

/**
 * create lyrics.wikia.com URL for given title and artist
 */
+(NSString *) createLyricsWikiaUrlFor:(NSString *)title by:(NSString *)artist
{
  NSString *url = @"https://lyrics.wikia.com/";
  url = [url stringByAppendingString:[LyricsFinder escapeUri:artist withSeparator:@"_"]];
  url = [url stringByAppendingString:@":"];
  url = [url stringByAppendingString:[LyricsFinder escapeUri:title withSeparator:@"_"]];
  return url;
}

/**
 * download lyrics from given URL. returns nil, if lyrics not found
 */
+ (NSString *)downloadazlyricsLyricsFrom:(NSString *)url
{
  NSLog(@"downloading '%@'", url);
  
  
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    
    if (data == nil) {
        
        return nil;
    }
    
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data
                                                          options:NSXMLDocumentTidyHTML
                                                            error:nil];

  
  if (document == nil) {
    return nil;
  }
    
    NSString *content = document.XMLString;
    
    NSString* scanString = @"";
    NSString *startTag= @"<div><!-- Usage of azlyrics.com content by any third-party lyrics provider is prohibited by our licensing agreement. Sorry about that. -->";
    NSString *endTag= @"</div>";
    
    
    if ([content rangeOfString:startTag].location == NSNotFound) {
        return nil;
    } 
    
    if (content.length > 0) {
        
        NSScanner* scanner = [[NSScanner alloc] initWithString:content];
        
        @try {
            [scanner scanUpToString:startTag intoString:nil];
            scanner.scanLocation += [startTag length];
            [scanner scanUpToString:endTag intoString:&scanString];
        }
        @catch (NSException *exception) {
            return nil;
        }
        @finally {
            NSString *returnString = [ scanString stringByReplacingOccurrencesOfString:@"<i>" withString:@""];
            returnString = [ returnString stringByReplacingOccurrencesOfString:@"</i>" withString:@""];
            returnString = [ returnString stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
            
            return returnString;
            
        }
        
    }
    
    
  
 
}

/**
 * download lyrics from given URL. returns nil, if lyrics not found
 */
+ (NSString *)downloadLyricsWikiaLyricsFrom:(NSString *)url
{
  NSLog(@"downloading '%@'", url);
  NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
  if (data == nil) {
      
    return nil;
  }
  NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data
                                                        options:NSXMLDocumentTidyHTML
                                                          error:nil];
  if (document == nil) {
    return nil;
  }
  
  NSMutableArray *lyricLines = [NSMutableArray new];
  NSString *content = [document stringValue];
  NSArray *lines = [content componentsSeparatedByString: @"\n"];
  
  NSString *line;
  NSEnumerator* iter = [lines objectEnumerator];
  BOOL isLyric = FALSE;
  BOOL firstLyricLine = FALSE;
  while (line = [iter nextObject]) {
      
    if ([line rangeOfString:@"You must enable javascript to view this page. This is a requirement of our licensing agreement with music Gracenote."].location != NSNotFound) {
      // last line before lyrics
      isLyric = TRUE;
      firstLyricLine = TRUE;
    }
    else if ([line isEqualToString:@"<p>NewPP limit report"]) {
      // first line after lyrics
      isLyric = FALSE;
    }
    else if (isLyric) {
      if (firstLyricLine) {
        // remove ad from first line
        NSRange range = [line rangeOfString:@"Ringtone to your Cell Ad"];
        if (range.location != NSNotFound) {
          line = [line substringFromIndex:(range.location + range.length)];
        }
        
        // remove function call from first line
        range = [line rangeOfString:@"})();"];
        if ([line hasPrefix:@"(function() {"] && range.location != NSNotFound) {
          line = [line substringFromIndex:(range.location + range.length)];
        }
        
        firstLyricLine = FALSE;
      }
      [lyricLines addObject:line]; // add line to array
    }
  }
  
  if ([lyricLines	count] == 0) {
    return nil;
  }
  
  return [lyricLines componentsJoinedByString:@"\n"];
}

/**
 * find lyrics for given title and artist. returns empty NSString, if lyrics not found
 */
+ (NSString *)findLyricsOf:(NSString *)title by:(NSString *)artist
{
  if (title == nil || artist == nil) {
    return @"";
  }
  
  NSString *lyrics;
  NSString *url;
  
  // try do download lyrics from musixmatch.com using given title and artist
  url = [LyricsFinder createazLyricsUrl:title by:artist];
  lyrics = [LyricsFinder downloadazlyricsLyricsFrom:url];
  if (lyrics != nil)
    return lyrics;
  
  // try do download lyrics from lyrics.wikia.com using given title and artist
  url = [LyricsFinder createLyricsWikiaUrlFor:title by:artist];
  lyrics = [LyricsFinder downloadLyricsWikiaLyricsFrom:url];
  if (lyrics != nil)
    return lyrics;
  
  // try to download lyrics from lyrics.wikia.com using given artist and capitalized title
  url = [LyricsFinder createLyricsWikiaUrlFor:[title capitalizedString] by:artist];
  lyrics = [LyricsFinder downloadLyricsWikiaLyricsFrom:url];
  if (lyrics != nil)
    return lyrics;
  
  return @"";
}

/**
 * Validates the given lyrics and return TRUE iff they are valid.
 */
+ (BOOL)validateLyrics:(NSString *)lyrics
{
  if ([lyrics isEqualToString:@""])
    return FALSE;
  
  if ([lyrics hasPrefix:@"(function() {"])
    return FALSE;
  
  return TRUE;
}


@end

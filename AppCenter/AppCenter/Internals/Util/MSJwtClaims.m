// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>
#import "MSAppCenterInternal.h"
#import "MSJwtClaims.h"
#import "MSLogger.h"

static NSString *const kMSJwtPartsSeparator = @".";
static NSString *const kMSSubjectClaim = @"sub";
static NSString *const kMSExpirationClaim = @"exp";

@implementation MSJwtClaims

- (instancetype)initWithSubject:(NSString *)subject expirationDate:(NSDate *)expirationDate {
  self = [super init];
  if (self) {
    _subject = subject;
    _expirationDate = expirationDate;
  }
  return self;
}

+ (MSJwtClaims *)parse:(NSString *)jwt {
  NSArray *parts = [jwt componentsSeparatedByString:kMSJwtPartsSeparator];
  if ([parts count] < 2) {
    MSLogError([MSAppCenter logTag], @"Failed to parse JWT, not enough parts.");
    return nil;
  }
  NSString *base64ClaimsPart = parts[1];
  @try {
    NSError *error;
    NSData *claimsPartData = [[NSData alloc] initWithBase64EncodedString:base64ClaimsPart options:0];
    NSDictionary *claims = [NSJSONSerialization JSONObjectWithData:claimsPartData options:0 error:&error];
    if ([claims objectForKey:kMSExpirationClaim] == nil || [claims objectForKey:kMSSubjectClaim] == nil) {
      MSLogError([MSAppCenter logTag], @"Deserialized claims is missing `sub` or `exp`");
      return nil;
    }

    // We will treat invalid expiration times as an interval of 0 because there is not an easy way to determine the
    // type of of the value being returned from the dictionary.
    int expirationTimeIntervalSince1970 = [[claims objectForKey:kMSExpirationClaim] intValue];
    return [[MSJwtClaims alloc] initWithSubject:[claims objectForKey:kMSSubjectClaim]
                                 expirationDate:[[NSDate alloc] initWithTimeIntervalSince1970:expirationTimeIntervalSince1970]];
  } @catch (NSException *e) {
    MSLogError([MSAppCenter logTag], @"Failed to parse JWT: %@", e);
    return nil;
  }
}

- (NSString *)getSubject {
  return self.subject;
}

- (NSDate *)getExpirationDate {
  return self.expirationDate;
}

@end

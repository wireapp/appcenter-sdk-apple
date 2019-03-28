// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAppCenterInternal.h"
#import "MSAuthTokenContextDelegate.h"
#import "MSAuthTokenInfo.h"
#import "MSAuthTokenValidityInfo.h"
#import "MSConstants.h"
#import "MSKeychainUtil.h"
#import "MSLogger.h"
#import "MSUtility.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSAuthTokenContextDelegate;

/**
 * MSAuthTokenContext is a singleton responsible for keeping an in-memory reference to an auth token that the Identity service provides.
 * This enables all App Center modules to access the token, and receive a notification when the token changes.
 */
@interface MSAuthTokenContext : NSObject

/**
 * Cached authorization token.
 */
@property(nullable, atomic, readonly) NSString *authToken;

/**
 * Get singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 * Add delegate.
 *
 * @param delegate Delegate.
 */
- (void)addDelegate:(id<MSAuthTokenContextDelegate>)delegate;

/**
 * Remove delegate.
 *
 * @param delegate Delegate.
 */
- (void)removeDelegate:(id<MSAuthTokenContextDelegate>)delegate;

/**
 * Set current auth token and account id.
 *
 * @param authToken token to be added to the storage.
 * @param accountId account id to be added to the storage.
 * @param expiresOn expiration date of a token.
 */
- (void)setAuthToken:(nullable NSString *)authToken withAccountId:(nullable NSString *)accountId expiresOn:(nullable NSDate *)expiresOn;

/**
 * Returns current auth token.
 *
 * @return auth token.
 */
- (nullable NSString *)authToken;

/**
 * Returns current account identifier.
 *
 * @return account identifier.
 */
- (nullable NSString *)accountId;

/**
 * Returns array of auth tokens validity info.
 *
 * @return Array of MSAuthTokenValidityInfo
 */
- (NSMutableArray<MSAuthTokenValidityInfo *> *)authTokenValidityArray;

/**
 * Removes the token from history. Please note that only oldest token is
 * allowed to remove. To reset current to anonymous, use
 * the saveToken method with nil value instead.
 *
 * @param authToken Auth token to remove. Despite the fact that only the oldest
 *                  token can be removed, it's required to avoid removing
 *                  the wrong one on duplicated calls etc.
 */
- (void)removeAuthToken:(nullable NSString *)authToken;

@end

NS_ASSUME_NONNULL_END

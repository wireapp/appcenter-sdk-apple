#import "AppDelegate.h"
#import "AppCenterDelegateObjC.h"
#import "Constants.h"
#import "Sasquatch-Swift.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>

#if GCC_PREPROCESSOR_MACRO_PUPPET
#import "AppCenter.h"
#import "AppCenterAnalytics.h"
#import "AppCenterCrashes.h"
#import "AppCenterDistribute.h"
#import "AppCenterPush.h"

// Internal ones
#import "MSAnalyticsInternal.h"

#define APP_SECRET_VALUE "7dfb022a-17b5-4d4a-9c75-12bc3ef5e6b7"
#else
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;
@import AppCenterDistribute;
@import AppCenterPush;

#define APP_SECRET_VALUE "3ccfe7f5-ec01-4de5-883c-f563bbbe147a"
#endif

enum StartupMode {
  APPCENTER,
  ONECOLLECTOR,
  BOTH,
  NONE,
  SKIP
};

@interface AppDelegate () <
#if GCC_PREPROCESSOR_MACRO_PUPPET
    MSAnalyticsDelegate,
#endif
    MSCrashesDelegate, MSDistributeDelegate, MSPushDelegate>

@property(nonatomic) MSAnalyticsResult *analyticsResult;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

#if GCC_PREPROCESSOR_MACRO_PUPPET
  self.analyticsResult = [MSAnalyticsResult new];
  [MSAnalytics setDelegate:self];

  for (UIViewController *controller in
       [(UITabBarController *)self.window.rootViewController viewControllers]) {
    if ([controller isKindOfClass:[MSAnalyticsViewController class]]) {
      [(MSAnalyticsViewController *)controller
          setAnalyticsResult:self.analyticsResult];
    }
  }
#endif

  // Cusomize App Center SDK.
  [MSDistribute setDelegate:self];
  [MSPush setDelegate:self];
  [MSAppCenter setLogLevel:MSLogLevelVerbose];

  // Start App Center SDK.
  NSArray<Class> *services = @[
    [MSAnalytics class], [MSCrashes class], [MSDistribute class], [MSPush class]
  ];
  NSInteger startTarget =
      [[NSUserDefaults standardUserDefaults] integerForKey:kMSStartTargetKey];
  switch (startTarget) {
  case APPCENTER:
    [MSAppCenter start:[NSString stringWithUTF8String:APP_SECRET_VALUE]
          withServices:services];
    break;
  case ONECOLLECTOR:
    [MSAppCenter start:[NSString
                           stringWithFormat:@"target=%@", kMSObjCTargetToken]
          withServices:services];
    break;
  case BOTH:
    [MSAppCenter start:[NSString stringWithFormat:@"appsecret=%s;target=%@",
                                                  APP_SECRET_VALUE,
                                                  kMSObjCTargetToken]
          withServices:services];
    break;
  case NONE:
    [MSAppCenter startWithServices:services];
    break;
  }
  [self crashes];
  [self setAppCenterDelegate];
  return YES;
}

#pragma mark - Application life cycle

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

#pragma mark - Private

- (void)crashes {
  if ([MSCrashes hasCrashedInLastSession]) {
    MSErrorReport *errorReport = [MSCrashes lastSessionCrashReport];
    NSLog(@"We crashed with Signal: %@", errorReport.signal);
    MSDevice *device = [errorReport device];
    NSString *osVersion = [device osVersion];
    NSString *appVersion = [device appVersion];
    NSString *appBuild = [device appBuild];
    NSLog(@"OS Version is: %@", osVersion);
    NSLog(@"App Version is: %@", appVersion);
    NSLog(@"App Build is: %@", appBuild);
  }

  [MSCrashes setDelegate:self];
  [MSCrashes
      setUserConfirmationHandler:(^(NSArray<MSErrorReport *> *errorReports) {

        // Use MSAlertViewController to show a dialog to the user where they can
        // choose if they want to provide a crash report.
        UIAlertController *alertController = [UIAlertController
            alertControllerWithTitle:@"Sorry about that!"
                             message:@"Do you want to send an anonymous crash "
                                     @"report so we can fix the issue?"
                      preferredStyle:UIAlertControllerStyleAlert];

        // Add a "Don't send"-Button and call the
        // notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
        [alertController
            addAction:[UIAlertAction
                          actionWithTitle:@"Don't send"
                                    style:UIAlertActionStyleCancel
                                  handler:^(UIAlertAction *action) {
                                    [MSCrashes notifyWithUserConfirmation:
                                                   MSUserConfirmationDontSend];
                                  }]];

        // Add a "Send"-Button and call the notifyWithUserConfirmation-callback
        // with MSUserConfirmationSend
        [alertController
            addAction:[UIAlertAction actionWithTitle:@"Send"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
                                               [MSCrashes
                                                   notifyWithUserConfirmation:
                                                       MSUserConfirmationSend];
                                             }]];

        // Add a "Always send"-Button and call the
        // notifyWithUserConfirmation-callback with MSUserConfirmationAlways
        [alertController
            addAction:[UIAlertAction
                          actionWithTitle:@"Always send"
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
                                    [MSCrashes notifyWithUserConfirmation:
                                                   MSUserConfirmationAlways];
                                  }]];
        // Show the alert controller.
        [self.window.rootViewController presentViewController:alertController
                                                     animated:YES
                                                   completion:nil];

        return YES;
      })];
}

- (void)setAppCenterDelegate {
  AppCenterDelegateObjC *appCenterDel = [[AppCenterDelegateObjC alloc] init];
  for (UIViewController *controller in
       [(UITabBarController *)self.window.rootViewController viewControllers]) {
    id<AppCenterProtocol> sasquatchController =
        (id<AppCenterProtocol>)controller;
    sasquatchController.appCenter = appCenterDel;
  }
}

#if GCC_PREPROCESSOR_MACRO_PUPPET
#pragma mark - MSAnalyticsDelegate

- (void)analytics:(MSAnalytics *)analytics
    willSendEventLog:(MSEventLog *)eventLog {
  [self.analyticsResult willSendWithEventLog:eventLog];
  [NSNotificationCenter.defaultCenter
      postNotificationName:kUpdateAnalyticsResultNotification
                    object:self.analyticsResult];
}

- (void)analytics:(MSAnalytics *)analytics
    didSucceedSendingEventLog:(MSEventLog *)eventLog {
  [self.analyticsResult didSucceedSendingWithEventLog:eventLog];
  [NSNotificationCenter.defaultCenter
      postNotificationName:kUpdateAnalyticsResultNotification
                    object:self.analyticsResult];
}

- (void)analytics:(MSAnalytics *)analytics
    didFailSendingEventLog:(MSEventLog *)eventLog
                 withError:(NSError *)error {
  [self.analyticsResult didFailSendingWithEventLog:eventLog withError:error];
  [NSNotificationCenter.defaultCenter
      postNotificationName:kUpdateAnalyticsResultNotification
                    object:self.analyticsResult];
}
#endif

#pragma mark - MSCrashesDelegate

- (BOOL)crashes:(MSCrashes *)crashes
    shouldProcessErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"Should process error report with: %@", errorReport.exceptionReason);
  return YES;
}

- (void)crashes:(MSCrashes *)crashes
    willSendErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"Will send error report with: %@", errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes
    didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
  NSLog(@"Did succeed error report sending with: %@",
        errorReport.exceptionReason);
}

- (void)crashes:(MSCrashes *)crashes
    didFailSendingErrorReport:(MSErrorReport *)errorReport
                    withError:(NSError *)error {
  NSLog(@"Did fail sending report with: %@, and error: %@",
        errorReport.exceptionReason, error.localizedDescription);
}

- (NSArray<MSErrorAttachmentLog *> *)attachmentsWithCrashes:(MSCrashes *)crashes
                                             forErrorReport:
                                                 (MSErrorReport *)errorReport {
  NSMutableArray *attachments = [[NSMutableArray alloc] init];

  // Text attachment.
  NSString *text =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"textAttachment"];
  if (text != nil && text.length > 0) {
    MSErrorAttachmentLog *textAttachment =
        [MSErrorAttachmentLog attachmentWithText:text filename:@"user.log"];
    [attachments addObject:textAttachment];
  }

  // Binary attachment.
  NSURL *referenceUrl =
      [[NSUserDefaults standardUserDefaults] URLForKey:@"fileAttachment"];
  if (referenceUrl) {
    PHAsset *asset = [[PHAsset fetchAssetsWithALAssetURLs:@[ referenceUrl ]
                                                  options:nil] lastObject];
    if (asset) {
      PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
      options.synchronous = YES;
      [[PHImageManager defaultManager]
          requestImageDataForAsset:asset
                           options:options
                     resultHandler:^(NSData *_Nullable imageData,
                                     NSString *_Nullable dataUTI,
                                     __unused UIImageOrientation orientation,
                                     __unused NSDictionary *_Nullable info) {
                       CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(
                           kUTTagClassFilenameExtension,
                           (__bridge CFStringRef)[dataUTI pathExtension], nil);
                       NSString *MIMEType = (__bridge_transfer NSString *)
                           UTTypeCopyPreferredTagWithClass(UTI,
                                                           kUTTagClassMIMEType);
                       CFRelease(UTI);
                       MSErrorAttachmentLog *binaryAttachment =
                           [MSErrorAttachmentLog attachmentWithBinary:imageData
                                                             filename:dataUTI
                                                          contentType:MIMEType];
                       [attachments addObject:binaryAttachment];
                       NSLog(@"Add binary attachment with %tu bytes",
                             [imageData length]);
                     }];
    }
  }
  return attachments;
}

#pragma mark - MSDistributeDelegate

- (BOOL)distribute:(MSDistribute *)distribute
    releaseAvailableWithDetails:(MSReleaseDetails *)details {

  if ([[[NSUserDefaults new] objectForKey:kSASCustomizedUpdateAlertKey]
          isEqual:@1]) {

    // Show a dialog to the user where they can choose if they want to update.
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:NSLocalizedStringFromTable(
                                     @"distribute_alert_title", @"Sasquatch",
                                     @"")
                         message:NSLocalizedStringFromTable(
                                     @"distribute_alert_message", @"Sasquatch",
                                     @"")
                  preferredStyle:UIAlertControllerStyleAlert];

    // Add a "Yes"-Button and call the notifyUpdateAction-callback with
    // MSUpdateActionUpdate
    [alertController
        addAction:[UIAlertAction
                      actionWithTitle:NSLocalizedStringFromTable(
                                          @"distribute_alert_yes", @"Sasquatch",
                                          @"")
                                style:UIAlertActionStyleCancel
                              handler:^(UIAlertAction *action) {
                                [MSDistribute
                                    notifyUpdateAction:MSUpdateActionUpdate];
                              }]];

    // Add a "No"-Button and call the notifyUpdateAction-callback with
    // MSUpdateActionPostpone
    [alertController
        addAction:[UIAlertAction
                      actionWithTitle:NSLocalizedStringFromTable(
                                          @"distribute_alert_no", @"Sasquatch",
                                          @"")
                                style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                [MSDistribute
                                    notifyUpdateAction:MSUpdateActionPostpone];
                              }]];

    // Show the alert controller.
    [self.window.rootViewController presentViewController:alertController
                                                 animated:YES
                                               completion:nil];
    return YES;
  }
  return NO;
}

#pragma mark - MSPushDelegate

- (void)push:(MSPush *)push
    didReceivePushNotification:(MSPushNotification *)pushNotification {
  NSString *title = pushNotification.title ?: @"";
  NSString *message = pushNotification.message;
  NSMutableString *customData = nil;
  for (NSString *key in pushNotification.customData) {
    ([customData length] == 0) ? customData = [NSMutableString new]
                               : [customData appendString:@", "];
    [customData appendFormat:@"%@: %@", key,
                             [pushNotification.customData objectForKey:key]];
  }
  if (UIApplication.sharedApplication.applicationState ==
      UIApplicationStateBackground) {
    NSLog(@"Notification received in background, title: \"%@\", message: "
          @"\"%@\", custom data: \"%@\"",
          title, message, customData);
  } else {
    message = [NSString stringWithFormat:@"%@%@%@", (message ? message : @""),
                                         (message && customData ? @"\n" : @""),
                                         (customData ? customData : @"")];

    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    [alertController
        addAction:[UIAlertAction actionWithTitle:@"OK"
                                           style:UIAlertActionStyleCancel
                                         handler:nil]];

    // Show the alert controller.
    [self.window.rootViewController presentViewController:alertController
                                                 animated:YES
                                               completion:nil];
  }
}

@end

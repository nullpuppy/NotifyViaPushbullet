//
//  TPI_NotifyViaPushBullet.m
//  NotifyViaPushbullet
//
//  Created by Dustin Knie on 9/2/15.
//  Copyright © 2015 Dustin Knie. All rights reserved.
//

#import "TPI_NotifyViaPushBullet.h"

#define PUSHBULLET_URI @"https://api.pushbullet.com/v2/pushes"

@interface TPI_NotifyViaPushBullet()

@property (strong) IBOutlet NSView *preferencesView;
@property (weak) IBOutlet NSButton *isEnabledButton;
@property (weak) IBOutlet NSTextField *apiKeyTextField;
@property (weak) IBOutlet NSButton *testPushButton;

- (NSView *)pluginPreferencesPaneView;
- (NSString *)pluginPreferencesPaneMenuItemName;

-(IBAction)buttonPressed:(id)sender;

@end

@implementation TPI_NotifyViaPushBullet

- (void)pluginLoadedIntoMemory {
    NSLog(@"Loaded plugin: Notify Via Pushbullet");
    LogToConsole(@"Loaded plugin: Notify Via Pushbullet");
    [self performBlockOnMainThread:^{
        NSDictionary *defaults = @{
            @"Notify Via Pushbullet -> Enable Notifications": @(YES),
            @"Notify Via Pushbullet -> Api Key": @"Put your key here",
                                   };
        [RZUserDefaults() registerDefaults:defaults];
        
        [TPIBundleFromClass() loadNibNamed:@"Preferences" owner:self topLevelObjects:nil];
    }];
}

- (NSString *)pluginPreferencesPaneMenuItemName {
    return @"Notify via Pushbullet";
}

- (NSView *)pluginPreferencesPaneView {
    return self.preferencesView;
}

- (IBAction)buttonPressed:(id)sender {
    NSLog(@"Pushed a button!");
    if([(NSView *)sender tag] == 0) {
        [self sendPush:@"Textual Notification Test" body:@"You got notified!"];
    }
}

- (void)sendPush:(NSString *)title body:(NSString *)body {
    NSString *apiKey = [RZUserDefaults() stringForKey:@"Notify Via Pushbullet -> Api Key"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:PUSHBULLET_URI]];
    [request setHTTPMethod:@"POST"];
    [request setValue:apiKey forHTTPHeaderField:@"Access-Token"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    NSString *postBody = [NSString stringWithFormat:@"{\"type\": \"note\", \"title\": \"%@\", \"body\": \"%@\"}", title, body];
    NSData *postData = [postBody dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:postData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *connectionError){
        // TODO: do things with rate-limit info in response, and deal with errors.
    }] resume];
}

- (void)didPostNewMessageForViewController:(TVCLogController *)logController messageInfo:(NSDictionary *)messageInfo isThemeReload:(BOOL)isThemeReload isHistoryReload:(BOOL)isHistoryReload {
    if(isThemeReload || isHistoryReload) {
        return;
    }
    BOOL isEnabled = [RZUserDefaults() boolForKey:@"Notify Via Pushbullet -> Enable Notifications"];
    if(isEnabled == YES) {
        IRCChannel *channel = [logController associatedChannel];
        IRCClient *client = [logController associatedClient];
        BOOL isMention = [[messageInfo valueForKey:THOPluginProtocolDidPostNewMessageKeywordMatchFoundAttribute] boolValue];
        BOOL isPrivateMessage = [channel isPrivateMessage];
        NSString *sender = [messageInfo stringForKey:THOPluginProtocolDidPostNewMessageSenderNicknameAttribute];
        // TODO: reformat message so it can be sent in a json body.
        NSString *message = [messageInfo stringForKey:THOPluginProtocolDidPostNewMessageMessageBodyAttribute];
        NSString *recievedAt = [[messageInfo objectForKey:THOPluginProtocolDidPostNewMessageReceivedAtTimeAttribute] description];
        
        if(isMention || (isPrivateMessage && [sender isNotEqualTo:[client localNickname]])) {
            [self sendPush:[NSString stringWithFormat:@"[%@] %@ at %@", [channel name], sender, recievedAt] body:message];
        }
    }
}

@end

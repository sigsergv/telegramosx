//
//  Telegram.h
//  TelegramTest
//
//  Created by Dmitry Kondratyev on 10/28/13.
//  Copyright (c) 2013 keepcoder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MainViewController.h"
#import "TelegramFirstController.h"
#import "AppDelegate.h"
#import "SettingsWindowController.h"
#import "ASQueue.h"

@interface Telegram : NSObjectController

+ (Telegram *)sharedInstance;



Telegram * TelegramInstance();


BOOL isTestServer();
NSString* appName();

@property (nonatomic, strong) IBOutlet TelegramFirstController *firstController;

+ (RightViewController *)rightViewController;
+ (LeftViewController *)leftViewController;
+ (MainViewController *)mainViewController;
+ (SettingsWindowController *)settingsWindowController;
+ (AppDelegate *)delegate;


- (void)makeFirstController:(TMViewController *)controller;

- (void)onAuthSuccess;
- (void)onLogoutSuccess;
+ (void)drop;


@property (nonatomic) BOOL isWindowActive;
@property (nonatomic, assign) BOOL isOnline;

- (void)setAccountOnline;
- (void)setAccountOffline:(BOOL)force;


- (void)showMessagesFromDialog:(TGDialog *)dialog sender:(id)sender;
- (void)showUserInfoWithUserId:(int)userID conversation:(TL_conversation *)conversaion sender:(id)sender;
- (void)showMessagesWidthUser:(TGUser *)user sender:(id)sender;
- (void)showNotSelectedDialog;
@end

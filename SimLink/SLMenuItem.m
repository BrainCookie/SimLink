//
//  SLMenuItem.m
//  SimLink
//
//  Created by Iska on 13/03/14.
//  Copyright (c) 2014 BrainCookie. All rights reserved.
//

#import "SLMenuItem.h"
#import "SLApplicationBundle.h"
#import "SLSimulatorRemoteClient.h"

@interface SLMenuItem ()
{
	SLApplicationBundle *_appBundle;
	SLMenuItemAction _action;
}

- (BOOL)setupWithPath:(NSString *)path;
- (void)openApplicationFolder;
- (void)deleteApplicationFolder;
- (void)clearApplicationDocumentsFolder;
- (void)runApplicationInSimulator;

@end

@implementation SLMenuItem

#pragma mark - Lifecycle

- (id)initWithApplicationDirectoryPath:(NSString *)path
{
	self = [super initWithTitle:@"" action:NULL keyEquivalent:@""];
	if (self) {
		if (![self setupWithPath:path]) return nil;
	}
	return self;
}

- (BOOL)setupWithPath:(NSString *)path
{
	_appBundle = [[SLApplicationBundle alloc] initWithApplicationDirectoryPath:path];

    if (_appBundle == nil) return NO;

	self.title = _appBundle.displayName;
	SLMenuItemView *view = [[SLMenuItemView alloc] initWithName:_appBundle.displayName
										   identifier:_appBundle.identifier
											  version:_appBundle.version
												 size:_appBundle.size
											  andIcon:_appBundle.icon];
	view.delegate = self;
	self.view = view;

    return YES;
}

#pragma mark - Actions

- (void)setCurrentAction:(NSNumber *)action
{
	_action = [action shortValue];
}

- (void)openApplicationFolder
{
	NSString *path = [_appBundle.path stringByAppendingPathComponent:_appBundle.name];
	NSURL *url = [NSURL fileURLWithPath:path];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[  url ]];
}

- (void)deleteApplicationFolder
{
	if ([_appBundle isSystemApplication]) return;

	[[NSFileManager defaultManager] removeItemAtPath:_appBundle.path error:nil];

	NSMenu *menu = self.menu;
	NSInteger index = [menu indexOfItem:self];
	[menu removeItemAtIndex:index];
	[menu removeItemAtIndex:index];
	[self.menu update];
}

- (void)clearApplicationDocumentsFolder
{
	NSString *documentsPath = [_appBundle.path stringByAppendingPathComponent:@"Documents"];

	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:documentsPath];

	NSError *error = nil;
	NSString *file;
	while (file = [enumerator nextObject]) {
		[[NSFileManager defaultManager] removeItemAtPath:[documentsPath stringByAppendingPathComponent:file] error:&error];
		if (error) {
			NSLog(@"Error removing item: %@", file);
		}
	}
}

- (void)runApplicationInSimulator
{
	NSString *path = [_appBundle.path stringByAppendingPathComponent:_appBundle.name];
	[[SLSimulatorRemoteClient sharedClient] launchApplicationAtPath:[path stringByResolvingSymlinksInPath]];
}

#pragma mark - App View Delegate (SLMenuItemViewDelegate)

- (void)menuItemViewClicked:(SLMenuItemView *)appView
{
	switch (_action) {
		case SLMenuItemActionDefault:
			[self openApplicationFolder];
			break;
		case SLMenuItemActionDelete:
			[self deleteApplicationFolder];
			break;
		case SLMenuItemActionClearDoduments:
			[self clearApplicationDocumentsFolder];
			break;
		case SLMenuItemActionRun:
			[self runApplicationInSimulator];
			break;
	}
}

@end

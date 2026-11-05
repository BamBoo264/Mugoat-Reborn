#import <Foundation/Foundation.h>
#import "PackInstall.h"
#include <assert.h>
static void writeFixture(NSURL *root,NSString *path,NSString *text){
 NSFileManager *fm=NSFileManager.defaultManager;NSURL *url=[root URLByAppendingPathComponent:path];
 assert([fm createDirectoryAtURL:url.URLByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil]);
 assert([text writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil]);
}
int main(void){@autoreleasepool{
 NSFileManager *fm=NSFileManager.defaultManager;
 NSURL *root=[[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:[@"reborn-pack-test-" stringByAppendingString:NSUUID.UUID.UUIDString] isDirectory:YES];
 NSURL *source=[root URLByAppendingPathComponent:@"source"],*mods=[root URLByAppendingPathComponent:@"data/mods"];
 for(NSString *name in @[@"mod.json",@"menyooStuff/menyooConfig.ini",@"dotnet/ScriptHookVDotNet.dll",@"dotnet/PostHook.DotNet.dll"])writeFixture(source,name,@"fixture");
 NSError *error=nil;assert(RBInstallPack(source,mods,&error)==1);assert(error==nil);
 NSURL *target=[mods URLByAppendingPathComponent:@"scripthook"];
 assert([[NSString stringWithContentsOfURL:[target URLByAppendingPathComponent:@"mod.json"] encoding:NSUTF8StringEncoding error:nil] isEqualToString:@"fixture"]);
 writeFixture(target,@"menyooStuff/menyooConfig.ini",@"user settings");assert(RBInstallPack(source,mods,&error)==2);
 assert([[NSString stringWithContentsOfURL:[target URLByAppendingPathComponent:@"menyooStuff/menyooConfig.ini"] encoding:NSUTF8StringEncoding error:nil] isEqualToString:@"user settings"]);
 assert([[NSString stringWithContentsOfURL:[source URLByAppendingPathComponent:@"menyooStuff/menyooConfig.ini"] encoding:NSUTF8StringEncoding error:nil] isEqualToString:@"fixture"]);
 NSURL *bad=[root URLByAppendingPathComponent:@"bad-source"];writeFixture(bad,@"mod.json",@"incomplete");
 assert(RBInstallPack(bad,[root URLByAppendingPathComponent:@"other-mods"],&error)==0);
 NSURL *file=[root URLByAppendingPathComponent:@"not-a-directory"];writeFixture(root,@"not-a-directory",@"file");assert(RBInstallPack(source,file,&error)==0);
 for(NSString *entry in [fm contentsOfDirectoryAtPath:mods.path error:nil])assert(![entry hasPrefix:@".reborn-scripthook-"]);
 assert([root.lastPathComponent hasPrefix:@"reborn-pack-test-"]);[fm removeItemAtURL:root error:nil];
 puts("Native installer: complete copy, no overwrite, source immutable, bad input, stage cleanup PASS");
}return 0;}

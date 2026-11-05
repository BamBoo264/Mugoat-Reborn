#import "PackInstall.h"
static BOOL fail(NSError **error,NSString *message){if(error)*error=[NSError errorWithDomain:@"RebornPack" code:1 userInfo:@{NSLocalizedDescriptionKey:message}];return NO;}
static BOOL normalDirectory(NSURL *url){
 NSNumber *directory=nil,*symlink=nil;
 [url getResourceValue:&directory forKey:NSURLIsDirectoryKey error:nil];[url getResourceValue:&symlink forKey:NSURLIsSymbolicLinkKey error:nil];return directory.boolValue&&!symlink.boolValue;
}
int RBInstallPack(NSURL *source,NSURL *mods,NSError **error){
 NSFileManager *fm=NSFileManager.defaultManager;
 if(!normalDirectory(source))return fail(error,@"Thiếu thư mục tài nguyên ScriptHook trong app.");
 NSArray *required=@[@"mod.json",@"menyooStuff/menyooConfig.ini",@"dotnet/ScriptHookVDotNet.dll",@"dotnet/PostHook.DotNet.dll"];
 for(NSString *path in required)if(![fm isReadableFileAtPath:[source URLByAppendingPathComponent:path].path])return fail(error,[NSString stringWithFormat:@"Thiếu tài nguyên %@",path]);
 if([fm fileExistsAtPath:mods.path]&&!normalDirectory(mods))return fail(error,@"Thư mục mods không hợp lệ; không ghi dữ liệu.");
 if(![fm createDirectoryAtURL:mods withIntermediateDirectories:YES attributes:nil error:error])return 0;
 NSURL *target=[mods URLByAppendingPathComponent:@"scripthook" isDirectory:YES];
 if([fm fileExistsAtPath:target.path])return 2; // Never overwrite the user's configuration or installed mod.
 NSURL *stage=[mods URLByAppendingPathComponent:[@".reborn-scripthook-" stringByAppendingString:NSUUID.UUID.UUIDString] isDirectory:YES];
 if(![fm copyItemAtURL:source toURL:stage error:error]){
  // stage is a newly generated direct child, never a user-supplied deletion path.
  if(normalDirectory(stage))[fm removeItemAtURL:stage error:nil];return 0;
 }
 for(NSString *path in required)if(![fm isReadableFileAtPath:[stage URLByAppendingPathComponent:path].path]){[fm removeItemAtURL:stage error:nil];return fail(error,@"Bản sao ScriptHook chưa đầy đủ.");}
 if(![fm moveItemAtURL:stage toURL:target error:error]){[fm removeItemAtURL:stage error:nil];return 0;}
 return 1;
}

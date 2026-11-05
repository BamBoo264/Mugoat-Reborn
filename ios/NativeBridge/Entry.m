#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "PackInstall.h"
#include <stdlib.h>

// Native localization plus one-time resource provisioning on the launcher.
// No rendering hook or game-frame callback in this module.
__attribute__((constructor)) static void rebornLanguage(void) {
    setenv("MACPORT_LAUNCHER_LANGUAGE", "vi", 1);
    @autoreleasepool {
        NSFileManager *fm = NSFileManager.defaultManager;
        NSURL *documents = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        NSURL *source = [NSBundle.mainBundle URLForResource:@"launcher_vi" withExtension:@"json"];
        if (!documents || !source) return;
        NSData *data = [NSData dataWithContentsOfURL:source];
        if (!data) return;
        NSURL *folder = [documents URLByAppendingPathComponent:@"launcherlang" isDirectory:YES];
        NSError *error = nil;
        if ([fm createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSURL *target = [folder URLByAppendingPathComponent:@"launcher_vi.json"];
            if (![[NSData dataWithContentsOfURL:target] isEqualToData:data]) {
                [data writeToURL:target options:NSDataWritingAtomic error:&error];
            }
        }
        if (error) NSLog(@"[Reborn] Vietnamese language registration: %@", error.localizedDescription);
    }
}

static void (*launcherAppear)(id,SEL,BOOL);static BOOL checkingPack=NO,attemptedPack=NO;
static void preparePack(UIViewController *host){
 if(checkingPack||attemptedPack||host.presentedViewController)return;
 NSFileManager *fm=NSFileManager.defaultManager;
 NSURL *docs=[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
 NSURL *root=[docs URLByAppendingPathComponent:@"GTAV" isDirectory:YES];
 if(![fm isReadableFileAtPath:[root URLByAppendingPathComponent:@"common.rpf"].path])return;
 NSURL *target=[root URLByAppendingPathComponent:@"mods/scripthook" isDirectory:YES];
 if([fm fileExistsAtPath:target.path])return;
 NSURL *source=[NSBundle.mainBundle URLForResource:@"RebornScriptHookPack" withExtension:nil];
 if(!source)return;checkingPack=YES;attemptedPack=YES;
 UIAlertController *progress=[UIAlertController alertControllerWithTitle:@"Đang chuẩn bị Menyoo" message:@"Cài tài nguyên ScriptHook một lần. Vui lòng chờ; dữ liệu game gốc không bị thay đổi." preferredStyle:UIAlertControllerStyleAlert];
 [host presentViewController:progress animated:YES completion:^{
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY,0),^{
   NSError *error=nil;int result=RBInstallPack(source,[root URLByAppendingPathComponent:@"mods" isDirectory:YES],&error);
   dispatch_async(dispatch_get_main_queue(),^{
    [progress dismissViewControllerAnimated:YES completion:^{
     checkingPack=NO;
     NSString *message=result?@"Đã chuẩn bị Menyoo. Hãy tắt hẳn rồi mở lại app để runtime nhận gói ScriptHook. Trong game: menu hỗ trợ > Add-ons > Menyoo. Camera thử nghiệm nằm ở nút Camera trong trang Add-ons.":(error.localizedDescription?:@"Không cài được tài nguyên. Kiểm tra dung lượng trống rồi mở lại app để thử lại.");
     NSLog(@"[Reborn] ScriptHook preparation: %@",message);
     UIAlertController *done=[UIAlertController alertControllerWithTitle:result?@"ScriptHook đã sẵn sàng":@"Chưa cài được Menyoo" message:message preferredStyle:UIAlertControllerStyleAlert];[done addAction:[UIAlertAction actionWithTitle:@"Đã hiểu" style:UIAlertActionStyleDefault handler:nil]];[host presentViewController:done animated:YES completion:nil];
    }];
   });
  });
 }];
}
static void launcherAppeared(id self,SEL cmd,BOOL animated){launcherAppear(self,cmd,animated);preparePack(self);}
__attribute__((constructor)) static void installPackHook(void){
 dispatch_async(dispatch_get_main_queue(),^{
  Class cls=NSClassFromString(@"MPLauncherViewController");if(!cls)return;
  SEL sel=@selector(viewDidAppear:);Method m=class_getInstanceMethod(cls,sel);if(!m)return;
  launcherAppear=(void *)method_getImplementation(m);
  if(!class_addMethod(cls,sel,(IMP)launcherAppeared,method_getTypeEncoding(m)))method_setImplementation(class_getInstanceMethod(cls,sel),(IMP)launcherAppeared);
 });
}

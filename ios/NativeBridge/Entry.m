#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "RebornBridge-Swift.h"
static void (*originalAppear)(id, SEL, BOOL);
static void rebornAppear(id self, SEL cmd, BOOL animated) {
    originalAppear(self, cmd, animated);
    [RebornNativeEntry installOn:self];
}
__attribute__((constructor)) static void rebornLoad(void) {
    // Only the confirmed native launcher class. Never hook game frames or UIKit globally.
    dispatch_async(dispatch_get_main_queue(), ^{
        Class cls = NSClassFromString(@"MPLauncherViewController");
        if (!cls) { NSLog(@"[Reborn] Native launcher class absent; bridge disabled"); return; }
        SEL sel = @selector(viewDidAppear:);
        Method method = class_getInstanceMethod(cls, sel);
        if (!method) return;
        originalAppear = (void *)method_getImplementation(method);
        class_addMethod(cls, sel, (IMP)rebornAppear, method_getTypeEncoding(method));
        method = class_getInstanceMethod(cls, sel);
        method_setImplementation(method, (IMP)rebornAppear);
        NSLog(@"[Reborn] Import bridge attached; engine/render settings unchanged");
    });
}

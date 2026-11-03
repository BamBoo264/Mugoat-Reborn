#import <Foundation/Foundation.h>
#include <stdlib.h>

// Only the native port's supported localization mechanism. No UI swizzling,
// input callbacks, rendering hooks, per-frame work or game-data writes.
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

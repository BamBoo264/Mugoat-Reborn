#import <UIKit/UIKit.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#include <stdbool.h>
#include <stdint.h>
extern void RBPresentCameraSettings(UIViewController *host);
typedef const void *(*KeyInfoFunction)(uint16_t);
typedef void (*KeyEventFunction)(const void *,bool,unsigned);
static KeyInfoFunction keyInfo;static KeyEventFunction keyEvent;
static BOOL resolveKeys(void){
 if(!keyInfo)keyInfo=(KeyInfoFunction)dlsym(RTLD_DEFAULT,"_ZN6compat10KeyFromMacEt");
 if(!keyEvent)keyEvent=(KeyEventFunction)dlsym(RTLD_DEFAULT,"_ZN6compat8KeyEventERKNS_7KeyInfoEbj");
 return keyInfo&&keyEvent;
}
static UIViewController *topController(UIWindow *window){UIViewController *c=window.rootViewController;while(c.presentedViewController)c=c.presentedViewController;return c;}
@interface RBPluginKeysPanel:UIView
@property UILabel *titleLabel;
@property UIScrollView *keys;
@property NSMutableSet<NSNumber*> *held;
@property NSMutableDictionary<NSNumber*,NSNumber*> *generation;
@property NSMutableDictionary<NSNumber*,NSNumber*> *started;
@property BOOL collapsed;
@end
@implementation RBPluginKeysPanel
-(instancetype)initWithFrame:(CGRect)frame{
 if(!(self=[super initWithFrame:frame]))return nil;
 self.held=[NSMutableSet new];self.generation=[NSMutableDictionary new];self.started=[NSMutableDictionary new];
 self.backgroundColor=[UIColor colorWithWhite:0.06 alpha:0.88];self.layer.cornerRadius=12;self.clipsToBounds=YES;
 self.titleLabel=[UILabel new];self.titleLabel.text=@"Phím plugin";self.titleLabel.font=[UIFont boldSystemFontOfSize:12];self.titleLabel.textColor=UIColor.whiteColor;self.titleLabel.userInteractionEnabled=YES;
 [self.titleLabel addGestureRecognizer:[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(drag:)]];[self addSubview:self.titleLabel];
 UIButton *fold=[UIButton buttonWithType:UIButtonTypeSystem];[fold setTitle:@"− / +" forState:UIControlStateNormal];fold.tag=900;[fold addTarget:self action:@selector(fold) forControlEvents:UIControlEventTouchUpInside];[self addSubview:fold];
 UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];[close setTitle:@"×" forState:UIControlStateNormal];close.tag=901;[close addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];[self addSubview:close];
 self.keys=[UIScrollView new];[self addSubview:self.keys];
 NSArray *labels=@[@"F1",@"F2",@"F3",@"F4",@"F5",@"F6",@"F7 Cam",@"F8",@"F9",@"F10",@"F11",@"F12",@"Num8",@"Num2",@"Num4",@"Num6",@"Num5",@"Num0",@"↑",@"↓",@"←",@"→",@"Enter",@"Back",@"Esc",@"Tab"];
 const int codes[]={122,120,99,118,96,97,98,100,101,109,103,111,91,84,86,88,87,82,126,125,123,124,36,51,53,48};
 for(NSUInteger i=0;i<labels.count;i++){
  UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.tag=codes[i];b.titleLabel.font=[UIFont boldSystemFontOfSize:11];[b setTitle:labels[i] forState:UIControlStateNormal];[b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];b.backgroundColor=[UIColor colorWithWhite:0.22 alpha:1];b.layer.cornerRadius=6;
  if(codes[i]==98)[b addTarget:self action:@selector(camera) forControlEvents:UIControlEventTouchUpInside];
  else{[b addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown];[b addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];}
  [self.keys addSubview:b];
 }
 [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(releaseAll) name:UIApplicationWillResignActiveNotification object:nil];return self;
}
-(void)dealloc{[[NSNotificationCenter defaultCenter]removeObserver:self];[self releaseAll];}
-(void)layoutSubviews{
 [super layoutSubviews];CGFloat w=self.bounds.size.width;
 self.titleLabel.frame=CGRectMake(12,0,w-110,34);[self viewWithTag:900].frame=CGRectMake(w-96,0,55,34);[self viewWithTag:901].frame=CGRectMake(w-39,0,34,34);
 self.keys.frame=CGRectMake(8,36,w-16,MAX(0,self.bounds.size.height-44));self.keys.hidden=self.collapsed;
 CGFloat cell=(w-26)/6;int i=0;for(UIView *view in self.keys.subviews)if([view isKindOfClass:UIButton.class]){view.frame=CGRectMake((i%6)*cell,(i/6)*38,cell-4,34);i++;}
 self.keys.contentSize=CGSizeMake(w-16,((i+5)/6)*38);
}
-(void)send:(NSNumber *)number down:(BOOL)pressed{
 if(!resolveKeys())return;const uint8_t *info=keyInfo(number.unsignedShortValue);if(!info||(!info[0]&&!info[1]))return;
 keyEvent(info,pressed,0);
}
-(void)down:(UIButton *)button{
 NSNumber *k=@(button.tag);if(!resolveKeys()){self.titleLabel.text=@"API phím chưa sẵn sàng";return;}
 if([self.held containsObject:k])[self send:k down:NO];
 self.generation[k]=@([self.generation[k] unsignedIntegerValue]+1);self.started[k]=@(NSProcessInfo.processInfo.systemUptime);[self.held addObject:k];[self send:k down:YES];button.alpha=0.6;
}
-(void)up:(UIButton *)button{
 NSNumber *k=@(button.tag);button.alpha=1;if(![self.held containsObject:k])return;
 NSUInteger token=[self.generation[k] unsignedIntegerValue];double elapsed=NSProcessInfo.processInfo.systemUptime-[self.started[k] doubleValue];
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(MAX(0,0.12-elapsed)*NSEC_PER_SEC)),dispatch_get_main_queue(),^{
  if([self.generation[k] unsignedIntegerValue]==token&&[self.held containsObject:k]){[self send:k down:NO];[self.held removeObject:k];}
 });
}
-(void)releaseAll{for(NSNumber *k in self.held.allObjects){[self send:k down:NO];self.generation[k]=@([self.generation[k] unsignedIntegerValue]+1);}[self.held removeAllObjects];}
-(void)close{[self releaseAll];[self removeFromSuperview];}
-(void)fold{[self releaseAll];self.collapsed=!self.collapsed;CGRect frame=self.frame;frame.size.height=self.collapsed?34:230;frame.size.width=self.collapsed?200:MIN(310,self.superview.bounds.size.width-self.superview.safeAreaInsets.left-self.superview.safeAreaInsets.right-12);self.frame=frame;[self clampFrame];[self setNeedsLayout];}
-(void)camera{[self releaseAll];UIViewController *host=topController(self.window);if(host)RBPresentCameraSettings(host);}
-(void)clampFrame{
 if(!self.superview)return;UIEdgeInsets safe=self.superview.safeAreaInsets;CGRect f=self.frame;CGSize s=self.superview.bounds.size;
 f.origin.x=MAX(safe.left+4,MIN(f.origin.x,s.width-safe.right-f.size.width-4));f.origin.y=MAX(safe.top+4,MIN(f.origin.y,s.height-safe.bottom-f.size.height-4));self.frame=f;
}
-(void)drag:(UIPanGestureRecognizer *)gesture{
 CGPoint offset=[gesture translationInView:self.superview];self.center=CGPointMake(self.center.x+offset.x,self.center.y+offset.y);[gesture setTranslation:CGPointZero inView:self.superview];[self clampFrame];
}
@end
static void showKeys(UIWindow *window,BOOL expanded){
 if(!window)return;UIView *old=[window viewWithTag:0x524b59];if(old){if(expanded&&((RBPluginKeysPanel *)old).collapsed)[(RBPluginKeysPanel *)old fold];[window bringSubviewToFront:old];return;}
 CGFloat width=MIN(310,window.bounds.size.width-window.safeAreaInsets.left-window.safeAreaInsets.right-12);
 RBPluginKeysPanel *panel=[[RBPluginKeysPanel alloc]initWithFrame:CGRectMake((window.bounds.size.width-width)/2,window.safeAreaInsets.top+8,width,230)];panel.tag=0x524b59;[window addSubview:panel];if(!expanded)[panel fold];[panel clampFrame];
}
static void openKeys(id self,SEL cmd){
 UIViewController *host=self;UIWindow *window=host.view.window;
 if(host.presentingViewController||host.navigationController.presentingViewController)[host dismissViewControllerAnimated:YES completion:^{showKeys(window,YES);}];else showKeys(window,YES);
}
void RBInstallKeyButton(UIViewController *host){
 for(UIBarButtonItem *item in host.navigationItem.leftBarButtonItems)if(item.tag==0x524b42)return;
 class_addMethod(host.class,NSSelectorFromString(@"rebornOpenPluginKeys"),(IMP)openKeys,"v@:");
 UIBarButtonItem *button=[[UIBarButtonItem alloc]initWithTitle:@"Phím" style:UIBarButtonItemStylePlain target:host action:NSSelectorFromString(@"rebornOpenPluginKeys")];button.tag=0x524b42;
 NSMutableArray *items=[(host.navigationItem.leftBarButtonItems?:@[]) mutableCopy];[items addObject:button];host.navigationItem.leftBarButtonItems=items;
}

void RBShowPluginKeysHUD(void){
 for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)if(scene.activationState==UISceneActivationStateForegroundActive&&[scene isKindOfClass:UIWindowScene.class]){
  for(UIWindow *window in ((UIWindowScene *)scene).windows)if(window.isKeyWindow){showKeys(window,NO);return;}
 }
}

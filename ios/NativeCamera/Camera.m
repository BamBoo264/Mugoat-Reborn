#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <stdint.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <string.h>
#include "CameraPolicy.h"
#include "NativeHashes.h"
extern void scriptRegister(void *module,void (*main)(void));
extern void scriptWait(unsigned long milliseconds);
extern void nativeInit(uint64_t hash);
extern void nativePush64(uint64_t value);
extern uint64_t *nativeCall(void);
static _Atomic(int) enabled=0;
static _Atomic(float) fov=85,forwardOffset=0.12f,heightOffset=0.03f;
static int camera=0,attachedPed=0;static float yawOffset=0,pitch=0;
#define U(x) ((uint64_t)(x))
static uint64_t F(float x){uint32_t b;memcpy(&b,&x,4);return b;}
static float asFloat(uint64_t b){uint32_t low=(uint32_t)b;float x;memcpy(&x,&low,4);return x;}
static uint64_t call(uint64_t h,int count,...){
 nativeInit(h);va_list ap;va_start(ap,count);for(int i=0;i<count;i++)nativePush64(va_arg(ap,uint64_t));va_end(ap);
 uint64_t *r=nativeCall();return r?r[0]:0;
}
static void releaseCamera(void){
 if(!camera)return;
 // Only relinquish scripted rendering if OUR camera is still the rendered one.
 // A mission that replaced it keeps its own camera.
 if(call(H_DOES_CAM_EXIST,1,U(camera))){
  if(call(H_IS_CAM_RENDERING,1,U(camera)))call(H_RENDER_SCRIPT_CAMS,6,U(0),U(0),U(0),U(1),U(0),U(0));
  call(H_DESTROY_CAM,2,U(camera),U(0));
 }
 camera=0;attachedPed=0;yawOffset=0;pitch=0;
 NSLog(@"[RebornCamera] Returned camera to game");
}
static void cameraMain(void){
 NSLog(@"[RebornCamera] Native script started; disabled by default");
 for(;;){
  if(!atomic_load(&enabled)){releaseCamera();scriptWait(250);continue;}
  int player=(int)call(H_PLAYER_ID,0),ped=(int)call(H_PLAYER_PED_ID,0);
  CameraGate g={.enabled=1,.playing=(int)call(H_IS_PLAYER_PLAYING,1,U(player)),.control=(int)call(H_IS_PLAYER_CONTROL_ON,1,U(player)),.pedExists=ped && (int)call(H_DOES_ENTITY_EXIST,1,U(ped)),.paused=(int)call(H_IS_PAUSE_MENU_ACTIVE,0),.cutscene=(int)call(H_IS_CUTSCENE_ACTIVE,0),.faded=(int)call(H_IS_SCREEN_FADED_OUT,0),.switching=(int)call(H_IS_PLAYER_SWITCH_IN_PROGRESS,0)};
  if(g.pedExists){g.alive=!call(H_IS_ENTITY_DEAD,2,U(ped),U(0));g.inVehicle=(int)call(H_IS_PED_IN_ANY_VEHICLE,2,U(ped),U(0));g.firstPerson=call(H_GET_FOLLOW_VEHICLE_CAM_VIEW_MODE,0)==4;g.aiming=(int)call(H_IS_PLAYER_FREE_AIMING,1,U(player));g.shooting=(int)call(H_IS_PED_SHOOTING,1,U(ped));}
  if(!cameraAllowed(g)){releaseCamera();scriptWait(100);continue;}
  if(camera && (attachedPed!=ped || !call(H_IS_CAM_RENDERING,1,U(camera)))){releaseCamera();scriptWait(100);continue;}
  if(!camera){
   // Do not take over another script/mission camera.
   if(!call(H_IS_GAMEPLAY_CAM_RENDERING,0)){scriptWait(100);continue;}
   camera=(int)call(H_CREATE_CAM,2,U((uintptr_t)"DEFAULT_SCRIPTED_CAMERA"),U(1));
   if(!camera || !call(H_DOES_CAM_EXIST,1,U(camera))){camera=0;atomic_store(&enabled,0);NSLog(@"[RebornCamera] Native camera creation failed; feature disabled");scriptWait(250);continue;}
   attachedPed=ped;yawOffset=0;pitch=0;
   call(H_SET_CAM_NEAR_CLIP,2,U(camera),F(0.05f));
   call(H_SET_CAM_FOV,2,U(camera),F(atomic_load(&fov)));
   call(H_ATTACH_CAM_TO_PED_BONE,7,U(camera),U(ped),U(31086),F(0),F(atomic_load(&forwardOffset)),F(atomic_load(&heightOffset)),U(1));
   call(H_SET_CAM_ROT,5,U(camera),F(0),F(0),call(H_GET_ENTITY_HEADING,1,U(ped)),U(2));
   call(H_RENDER_SCRIPT_CAMS,6,U(1),U(0),U(0),U(1),U(0),U(0));
   NSLog(@"[RebornCamera] Vehicle first-person camera active (FOV %.0f)",atomic_load(&fov));
  }
  float dt=cameraClamp(asFloat(call(H_GET_FRAME_TIME,0)),0.001f,0.05f,1.0f/60.0f);
  float dx=cameraClamp(asFloat(call(H_GET_DISABLED_CONTROL_NORMAL,2,U(0),U(1))),-1,1,0);
  float dy=cameraClamp(asFloat(call(H_GET_DISABLED_CONTROL_NORMAL,2,U(0),U(2))),-1,1,0);
  yawOffset=cameraClamp(yawOffset-dx*140*dt,-130,130,0);pitch=cameraClamp(pitch-dy*100*dt,-55,55,0);
  float heading=asFloat(call(H_GET_ENTITY_HEADING,1,U(ped)));
  call(H_ATTACH_CAM_TO_PED_BONE,7,U(camera),U(ped),U(31086),F(0),F(atomic_load(&forwardOffset)),F(atomic_load(&heightOffset)),U(1));
  call(H_SET_CAM_ROT,5,U(camera),F(pitch),F(0),F(heading+yawOffset),U(2));
  call(H_SET_CAM_FOV,2,U(camera),F(atomic_load(&fov)));
  scriptWait(0);
 }
}
@interface RebornCameraSettings:UIViewController
@end
@implementation RebornCameraSettings
-(void)close{[self dismissViewControllerAnimated:YES completion:nil];}
-(void)change:(UIControl *)control{
 NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
 if(control.tag==1){BOOL value=((UISwitch *)control).on;atomic_store(&enabled,value);[d setBool:value forKey:@"RebornCamera.enabled"];}
 else {float x=((UISlider *)control).value;
  if(control.tag==2){x=cameraClamp(x,65,110,85);atomic_store(&fov,x);[d setFloat:x forKey:@"RebornCamera.fov"];}
  if(control.tag==3){x=cameraClamp(x,-0.1f,0.5f,0.12f);atomic_store(&forwardOffset,x);[d setFloat:x forKey:@"RebornCamera.forward"];}
  if(control.tag==4){x=cameraClamp(x,-0.15f,0.25f,0.03f);atomic_store(&heightOffset,x);[d setFloat:x forKey:@"RebornCamera.height"];}
 }
}
-(void)viewDidLoad{
 [super viewDidLoad];self.title=@"Camera trên xe (thử nghiệm)";self.view.backgroundColor=UIColor.systemBackgroundColor;
 self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
 UIScrollView *scroll=[UIScrollView new];scroll.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:scroll];
 UIStackView *stack=[UIStackView new];stack.axis=UILayoutConstraintAxisVertical;stack.spacing=16;stack.translatesAutoresizingMaskIntoConstraints=NO;[scroll addSubview:stack];
 UILabel *note=[UILabel new];note.numberOfLines=0;note.text=@"Chỉ áp dụng khi đang ngồi trên xe và dùng góc nhìn thứ nhất. Camera gốc được trả lại khi ra xe, ngắm bắn, tạm dừng hoặc chuyển cảnh. Mặc định tắt; có thể chỉnh ngay trong game.";[stack addArrangedSubview:note];
 UIStackView *row=[UIStackView new];UILabel *label=[UILabel new];label.text=@"Bật camera rộng trên xe";UISwitch *toggle=[UISwitch new];toggle.tag=1;toggle.on=atomic_load(&enabled);[toggle addTarget:self action:@selector(change:) forControlEvents:UIControlEventValueChanged];[row addArrangedSubview:label];[row addArrangedSubview:toggle];[stack addArrangedSubview:row];
 NSArray *titles=@[@"FOV: 65° — 110°",@"Vị trí trước/sau: −0,10 — 0,50 m",@"Độ cao: −0,15 — 0,25 m"];
 float values[]={atomic_load(&fov),atomic_load(&forwardOffset),atomic_load(&heightOffset)},mins[]={65,-0.1f,-0.15f},maxs[]={110,0.5f,0.25f};
 for(int i=0;i<3;i++){UILabel *t=[UILabel new];t.text=titles[i];[stack addArrangedSubview:t];UISlider *s=[UISlider new];s.tag=i+2;s.minimumValue=mins[i];s.maximumValue=maxs[i];s.value=values[i];[s addTarget:self action:@selector(change:) forControlEvents:UIControlEventValueChanged];[stack addArrangedSubview:s];}
 [NSLayoutConstraint activateConstraints:@[[scroll.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],[scroll.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],[scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],[scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],[stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20],[stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20],[stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:20],[stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20],[stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40]]];
}
@end
static void (*originalAppear)(id,SEL,BOOL);
static void openCamera(id self,SEL cmd){
 UIViewController *host=self;if(host.presentedViewController)return;
 [host presentViewController:[[UINavigationController alloc]initWithRootViewController:[RebornCameraSettings new]] animated:YES completion:nil];
}
static void appeared(id self,SEL cmd,BOOL animated){
 originalAppear(self,cmd,animated);UIViewController *host=self;
 for(UIBarButtonItem *item in host.navigationItem.leftBarButtonItems)if(item.tag==0x524343)return;
 UIBarButtonItem *button=[[UIBarButtonItem alloc]initWithTitle:@"Camera" style:UIBarButtonItemStylePlain target:self action:NSSelectorFromString(@"rebornOpenCamera")];button.tag=0x524343;
 NSMutableArray *items=[(host.navigationItem.leftBarButtonItems?:@[]) mutableCopy];[items addObject:button];host.navigationItem.leftBarButtonItems=items;
}
__attribute__((constructor)) static void setupCameraMenu(void){
 NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
 atomic_store(&enabled,[d boolForKey:@"RebornCamera.enabled"]);
 if([d objectForKey:@"RebornCamera.fov"])atomic_store(&fov,cameraClamp([d floatForKey:@"RebornCamera.fov"],65,110,85));
 if([d objectForKey:@"RebornCamera.forward"])atomic_store(&forwardOffset,cameraClamp([d floatForKey:@"RebornCamera.forward"],-0.1f,0.5f,0.12f));
 if([d objectForKey:@"RebornCamera.height"])atomic_store(&heightOffset,cameraClamp([d floatForKey:@"RebornCamera.height"],-0.15f,0.25f,0.03f));
 dispatch_async(dispatch_get_main_queue(),^{
  Class cls=NSClassFromString(@"PHAddonsController");if(!cls){NSLog(@"[RebornCamera] Add-ons menu unavailable");return;}
  class_addMethod(cls,NSSelectorFromString(@"rebornOpenCamera"),(IMP)openCamera,"v@:");
  SEL sel=@selector(viewDidAppear:);Method m=class_getInstanceMethod(cls,sel);originalAppear=(void *)method_getImplementation(m);
  if(!class_addMethod(cls,sel,(IMP)appeared,method_getTypeEncoding(m)))method_setImplementation(class_getInstanceMethod(cls,sel),(IMP)appeared);
 });
}
__attribute__((visibility("default"))) int DllMain(void *module,unsigned reason,void *reserved){
 if(reason==1)scriptRegister(module,cameraMain);return 1;
}

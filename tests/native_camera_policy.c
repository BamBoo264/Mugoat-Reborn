#include "CameraPolicy.h"
#include <assert.h>
#include <stdio.h>
int main(void){
 CameraGate g={.enabled=1,.playing=1,.control=1,.pedExists=1,.alive=1,.inVehicle=1,.firstPerson=1};
 assert(cameraAllowed(g));
 for(int i=0;i<13;i++){
  CameraGate bad=g;int *flags[]={&bad.enabled,&bad.playing,&bad.control,&bad.pedExists,&bad.alive,&bad.inVehicle,&bad.firstPerson,&bad.paused,&bad.cutscene,&bad.faded,&bad.switching,&bad.aiming,&bad.shooting};*flags[i]=i<7?0:1;assert(!cameraAllowed(bad));
 }
 assert(cameraClamp(NAN,65,110,85)==85);assert(cameraClamp(INFINITY,65,110,85)==85);
 assert(cameraClamp(500,65,110,85)==110);assert(cameraClamp(5,65,110,85)==65);
 assert(cameraClamp(90,65,110,85)==90);
 puts("Camera gate: off/on-foot/third-person/cutscene/pause/aim/shoot/death/loading checks PASS");return 0;
}

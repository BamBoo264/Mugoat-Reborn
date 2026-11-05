#pragma once
#include <math.h>
typedef struct { int enabled,playing,control,pedExists,alive,inVehicle,firstPerson,paused,cutscene,faded,switching,aiming,shooting; } CameraGate;
static inline int cameraAllowed(CameraGate g) {
 return g.enabled && g.playing && g.control && g.pedExists && g.alive && g.inVehicle && g.firstPerson && !g.paused && !g.cutscene && !g.faded && !g.switching && !g.aiming && !g.shooting;
}
static inline float cameraClamp(float x,float lo,float hi,float fallback) { return !isfinite(x)?fallback:fmaxf(lo,fminf(hi,x)); }

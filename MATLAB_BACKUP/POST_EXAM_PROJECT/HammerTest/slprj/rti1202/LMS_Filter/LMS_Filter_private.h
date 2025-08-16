#ifndef RTW_HEADER_LMS_Filter_private_h_
#define RTW_HEADER_LMS_Filter_private_h_
#include "rtwtypes.h"
#include "multiword_types.h"
#include "LMS_Filter.h"
#include "LMS_Filter_types.h"
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm) (*((rtm)->errorStatus))
#endif
#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val) (*((rtm)->errorStatus) = (val))
#endif
#ifndef rtmGetErrorStatusPointer
#define rtmGetErrorStatusPointer(rtm) (rtm)->errorStatus
#endif
#ifndef rtmSetErrorStatusPointer
#define rtmSetErrorStatusPointer(rtm, val) ((rtm)->errorStatus = (val))
#endif
extern lszzu35gke2_prot lszzu35gke_prot ;
#endif

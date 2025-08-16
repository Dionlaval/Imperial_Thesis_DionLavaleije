#ifndef RTW_HEADER_LMS_Filter_h_
#define RTW_HEADER_LMS_Filter_h_
#ifndef LMS_Filter_COMMON_INCLUDES_
#define LMS_Filter_COMMON_INCLUDES_
#include <rti_assert.h>
#include "rtwtypes.h"
#include "rtw_continuous.h"
#include "rtw_solver.h"
#endif
#include "LMS_Filter_types.h"
#include <string.h>
typedef struct { real_T jcxdic3v4h_prot [ 17 ] ; real_T enoj0sibht_prot ;
real_T jlmo2npkrk_prot ; real_T lzuawxwdj5_prot [ 17 ] ; real_T
o130ggj3u0_prot [ 17 ] ; } kg2yjpnqnn_prot ; typedef struct { real_T
b0o2fora00_prot [ 17 ] ; } aleu0citye_prot ; struct lszzu35gke2_prot_ {
real_T LMS_Fil_Memory_InitialCondition ; } ; struct jgxfnrktog_prot { const
char_T * * errorStatus ; } ; typedef struct { kg2yjpnqnn_prot rtb ;
aleu0citye_prot rtdw ; mpylf3tcrm_prot rtm ; } bgppt5gu45g_prot ; extern
real_T rtP_lms_var_gain ; extern void g1dlon5am3_prot ( const char_T * *
rt_errorStatus , mpylf3tcrm_prot * const lhqi5lyder_prot , kg2yjpnqnn_prot *
localB , aleu0citye_prot * localDW ) ; extern void ktvp3vh4kc_prot (
aleu0citye_prot * localDW ) ; extern void fpw2rh51ok_prot ( aleu0citye_prot *
localDW ) ; extern void o3zl3jtf1m_prot ( kg2yjpnqnn_prot * localB ,
aleu0citye_prot * localDW ) ; extern void LMS_Filter ( const real_T *
lqts2nl4cu_prot , const real_T hg2m1ofvri_prot [ 17 ] , real_T *
eig3qh5lww_prot , real_T jxr5gnqtni_prot [ 17 ] , kg2yjpnqnn_prot * localB ,
aleu0citye_prot * localDW ) ;
#endif

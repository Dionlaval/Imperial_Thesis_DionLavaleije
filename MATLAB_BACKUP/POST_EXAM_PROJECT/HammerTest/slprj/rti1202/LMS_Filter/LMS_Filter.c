#include "rti_initref_cpp.h"
#include "LMS_Filter.h"
#include "rtwtypes.h"
#include "LMS_Filter_private.h"
#include <string.h>
lszzu35gke2_prot lszzu35gke_prot = { 0.0 } ; void ktvp3vh4kc_prot (
aleu0citye_prot * localDW ) { int32_T i_prot ; for ( i_prot = 0 ; i_prot < 17
; i_prot ++ ) { localDW -> b0o2fora00_prot [ i_prot ] = lszzu35gke_prot .
LMS_Fil_Memory_InitialCondition ; } } void fpw2rh51ok_prot ( aleu0citye_prot
* localDW ) { int32_T i_prot ; for ( i_prot = 0 ; i_prot < 17 ; i_prot ++ ) {
localDW -> b0o2fora00_prot [ i_prot ] = lszzu35gke_prot .
LMS_Fil_Memory_InitialCondition ; } } void LMS_Filter ( const real_T *
lqts2nl4cu_prot , const real_T hg2m1ofvri_prot [ 17 ] , real_T *
eig3qh5lww_prot , real_T jxr5gnqtni_prot [ 17 ] , kg2yjpnqnn_prot * localB ,
aleu0citye_prot * localDW ) { real_T jxr5gnqtni_prot_prot ; real_T tmp_prot ;
int32_T i_prot ; tmp_prot = - 0.0 ; for ( i_prot = 0 ; i_prot < 17 ; i_prot
++ ) { jxr5gnqtni_prot_prot = localDW -> b0o2fora00_prot [ i_prot ] ;
jxr5gnqtni_prot [ i_prot ] = jxr5gnqtni_prot_prot ; jxr5gnqtni_prot_prot *=
hg2m1ofvri_prot [ i_prot ] ; localB -> jcxdic3v4h_prot [ i_prot ] =
jxr5gnqtni_prot_prot ; tmp_prot += jxr5gnqtni_prot_prot ; } * eig3qh5lww_prot
= tmp_prot ; localB -> enoj0sibht_prot = * lqts2nl4cu_prot - *
eig3qh5lww_prot ; localB -> jlmo2npkrk_prot = localB -> enoj0sibht_prot *
rtP_lms_var_gain ; for ( i_prot = 0 ; i_prot < 17 ; i_prot ++ ) { localB ->
lzuawxwdj5_prot [ i_prot ] = localB -> jlmo2npkrk_prot * hg2m1ofvri_prot [
i_prot ] ; } for ( i_prot = 0 ; i_prot < 17 ; i_prot ++ ) { localB ->
o130ggj3u0_prot [ i_prot ] = jxr5gnqtni_prot [ i_prot ] + localB ->
lzuawxwdj5_prot [ i_prot ] ; } } void o3zl3jtf1m_prot ( kg2yjpnqnn_prot *
localB , aleu0citye_prot * localDW ) { memcpy ( & localDW -> b0o2fora00_prot
[ 0 ] , & localB -> o130ggj3u0_prot [ 0 ] , 17U * sizeof ( real_T ) ) ; }
void g1dlon5am3_prot ( const char_T * * rt_errorStatus , mpylf3tcrm_prot *
const lhqi5lyder_prot , kg2yjpnqnn_prot * localB , aleu0citye_prot * localDW
) { rtmSetErrorStatusPointer ( lhqi5lyder_prot , rt_errorStatus ) ; ( void )
memset ( ( ( void * ) localB ) , 0 , sizeof ( kg2yjpnqnn_prot ) ) ; ( void )
memset ( ( void * ) localDW , 0 , sizeof ( aleu0citye_prot ) ) ; {
RTI_INIT_CODE_ENV ( ) ; } }

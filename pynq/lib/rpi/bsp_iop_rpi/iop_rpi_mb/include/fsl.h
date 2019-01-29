#ifndef FSL_H
#define FSL_H
/*****************************************************************************/
/**
*
* @file fsl.h
*
* @addtogroup microblaze_fsl_macro MicroBlaze Processor FSL Macros
*
*  Microblaze BSP includes macros to provide convenient access to accelerators
* connected to the MicroBlaze Fast Simplex Link (FSL) Interfaces.To use these functions,
* include the header file fsl.h in your source code
*
* @{
*
******************************************************************************/
#include "mb_interface.h"       /* Legacy reasons. We just have to include this guy who defines the FSL stuff */

#ifdef __cplusplus
extern "C" {
#endif

/* Extended FSL macros. These now replace all of the previous FSL macros */
#define FSL_DEFAULT
#define FSL_NONBLOCKING                          n
#define FSL_EXCEPTION                            e
#define FSL_CONTROL                              c
#define FSL_ATOMIC                               a

#define FSL_NONBLOCKING_EXCEPTION                ne
#define FSL_NONBLOCKING_CONTROL                  nc
#define FSL_NONBLOCKING_ATOMIC                   na
#define FSL_EXCEPTION_CONTROL                    ec
#define FSL_EXCEPTION_ATOMIC                     ea
#define FSL_CONTROL_ATOMIC                       ca

#define FSL_NONBLOCKING_EXCEPTION_CONTROL        nec
#define FSL_NONBLOCKING_EXCEPTION_ATOMIC         nea
#define FSL_NONBLOCKING_CONTROL_ATOMIC           nca
#define FSL_EXCEPTION_CONTROL_ATOMIC             eca

#define FSL_NONBLOCKING_EXCEPTION_CONTROL_ATOMIC neca

/**
Performs a get function on an input FSL of the MicroBlaze processor
@param val    variable to sink data from get function
@param id     literal in the range of 0 to 7 (0 to 15 for MicroBlaze v7.00.a and later)
@param flags  valid FSL macro flags
*/
#define getfslx(val, id, flags)      asm volatile (stringify(flags) "get\t%0,rfsl" stringify(id) : "=d" (val))

/**
Performs a put function on an input FSL of the MicroBlaze processor
@param val    variable to source data to put function
@param id     literal in the range of 0 to 7 (0 to 15 for MicroBlaze v7.00.a and later)
@param flags  valid FSL macro flags
*/
#define putfslx(val, id, flags)      asm volatile (stringify(flags) "put\t%0,rfsl" stringify(id) :: "d" (val))

/**
Performs a test get function on an input FSL of the MicroBlaze processor
@param val    variable to sink data from get function
@param id     literal in the range of 0 to 7 (0 to 15 for MicroBlaze v7.00.a and later)
@param flags  valid FSL macro flags
*/
#define tgetfslx(val, id, flags)     asm volatile ("t" stringify(flags) "get\t%0,rfsl" stringify(id) : "=d" (val))

/**
Performs a put function on an input FSL of the MicroBlaze processor
@param id     FSL identifier
@param flags  valid FSL macro flags
*/
#define tputfslx(id, flags)          asm volatile ("t" stringify(flags) "put\trfsl" stringify(id))

/**
Performs a getd function on an input FSL of the MicroBlaze processor
@param val    variable to sink data from getd function
@param var    literal in the range of 0 to 7 (0 to 15 for MicroBlaze v7.00.a and later)
@param flags  valid FSL macro flags
*/
#define getdfslx(val, var, flags)    asm volatile (stringify(flags) "getd\t%0,%1" : "=d" (val) : "d" (var))

/**
Performs a putd function on an input FSL of the MicroBlaze processor
@param val    variable to source data to putd function
@param var    literal in the range of 0 to 7 (0 to 15 for MicroBlaze v7.00.a and later)
@param flags  valid FSL macro flags
*/
#define putdfslx(val, var, flags)    asm volatile (stringify(flags) "putd\t%0,%1" :: "d" (val), "d" (var))

/**
Performs a test getd function on an input FSL of the MicroBlaze processor;
@param val    variable to sink data from getd function
@param var    literal in the range of 0 to 7 (0 to 15 for MicroBlaze v7.00.a and later)
@param flags  valid FSL macro flags
*/
#define tgetdfslx(val, var, flags)   asm volatile ("t" stringify(flags) "getd\t%0,%1" : "=d" (val) : "d" (var))

/**
Performs a put function on an input FSL of the MicroBlaze processor
@param var     FSL identifier
@param flags  valid FSL macro flags
*/
#define tputdfslx(var, flags)        asm volatile ("t" stringify(flags) "putd\t%0" :: "d" (var))


#ifdef __cplusplus
}
#endif
#endif /* FSL_H */
/**
* @} End of "addtogroup microblaze_fsl_macro".
*/

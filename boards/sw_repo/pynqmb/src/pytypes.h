#pragma once

/** An integer type that raises a Python exception when returned with a negative value
 */
typedef int py_int;

/** A floating point type that raises a Python exception when returned with NaN
 */
typedef float py_float;

/** Signal an error from a py_float returning function */
#define PY_FLOAT_ERROR (0.0f/0.0f)

/** An integer type that turns into a Python Bool object and can signal errors
 */
typedef unsigned int py_bool;

/** A type that can be used to signal an error with no return value otherwise
 *
 */
typedef int py_void;

/** Successul return from py_void functions */
#define PY_SUCCESS (0)

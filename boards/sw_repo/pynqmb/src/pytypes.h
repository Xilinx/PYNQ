#pragma once

/** An integer type that raises a Python exception when returned with a negative value
 */
typedef int py_int;

/** A floating point type that raises a Python exception when returned with NaN
 */
typedef float py_float;

/** An integer type that turns into a Python Bool object and can signal errors
 */
typedef unsigned int py_bool;

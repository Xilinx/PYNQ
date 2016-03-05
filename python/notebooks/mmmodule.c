#include <Python.h>
#define data_t int
#define A_NROWS 128
#define A_NCOLS 128
#define B_NROWS 128
#define B_NCOLS 128
#define TILE_SIZE 4

/* ===================== Matrix multiplication ==============================*/
void mmult_sw(data_t *A, data_t *B, data_t *C){
	// new implementation of 6-loop optimized
	int I,J,K,i,j,k;
	for (I = 0; I < A_NROWS/TILE_SIZE; I++){
	      for (J = 0; J < B_NCOLS/TILE_SIZE; J++){
	        for (K = 0; K < A_NCOLS/TILE_SIZE; K++){
	            for (i = I*TILE_SIZE; i < (I+1)*TILE_SIZE; i++){
	                for (j = J*TILE_SIZE; j < (J+1)*TILE_SIZE; j++){
	                    for (k = K*TILE_SIZE; k < (K+1)*TILE_SIZE;k+=4){
	                        C[i*B_NCOLS+j] += A[i*B_NCOLS+k]*B[k*B_NCOLS+j]+A[i*B_NCOLS+k+1]*B[(k+1)*B_NCOLS+j]+A[i*B_NCOLS+k+2]*B[(k+2)*B_NCOLS+j]+A[i*B_NCOLS+k+3]*B[(k+3)*B_NCOLS+j];
	                    }
	                }
	            }
	        }
	      }
	    }
}

static PyObject *mmmodError;

typedef struct Array {
    data_t array[A_NROWS*A_NCOLS];
} Array;

static Array *mmmod_get_array(PyObject *obj) {
  return (Array *) PyCapsule_GetPointer(obj, "Array");
}

static PyObject *mmmod_create_object(Array *a) {
    return PyCapsule_New(a, "Array", NULL);
}

static PyObject *mmmod_Array(PyObject *self, PyObject *args) {
  Array *a;
  int x, i;
  
  x = 0;
  if (!PyArg_ParseTuple(args,"|i", &x)) {
    PyErr_SetString(mmmodError, "cannot initialize the array.");
    return NULL;
  }
  
  a = (Array *) malloc(sizeof(Array));
  for (i=0;i<A_NROWS*A_NCOLS;i++){
        a->array[i]=x;
    }
  return mmmod_create_object(a);
}

static PyObject *mmmod_clear(PyObject *obj, PyObject* args) {
    int i;
    PyObject *py_a;
    Array *a;
    
    if(!PyArg_ParseTuple(args,"O", &py_a)){
		PyErr_SetString(mmmodError, "cannot parse input tuple when clearing.");
		return NULL; //return error if none found
	}
    if (!(a = mmmod_get_array(py_a))) {
        PyErr_SetString(mmmodError, "cannot get array when clearing.");
        return NULL;
    }
    for (i=0;i<A_NROWS*A_NCOLS;i++){
        a->array[i]=0;
    }
    Py_RETURN_NONE;
}

static PyObject *mmmod_set(PyObject *obj, PyObject* args) {
    int i;
    PyObject *py_a;
    int x;
    Array *a;
    
    if(!PyArg_ParseTuple(args,"Oi", &py_a, &x)){
		PyErr_SetString(mmmodError, "cannot parse input tuple when setting.");
		return NULL; //return error if none found
	}
    if (!(a = mmmod_get_array(py_a))) {
        PyErr_SetString(mmmodError, "cannot get array when setting.");
        return NULL;
    }
    for (i=0;i<A_NROWS*A_NCOLS;i++){
        a->array[i]=x;
    }
    Py_RETURN_NONE;
}

static PyObject* mmmod_write(PyObject* self, PyObject* args){
	PyObject *py_a;
	Array *a;
    int i,j;
    int val;
    
    if(!PyArg_ParseTuple(args,"Oiii", &py_a, &i, &j, &val)){
		PyErr_SetString(mmmodError, "cannot parse input tuple when writing.");
		return NULL; //return error if none found
	}
	
    if (!(a = mmmod_get_array(py_a))) {
        PyErr_SetString(mmmodError, "cannot get array when writing.");
        return NULL;
    }
    a->array[i*A_NCOLS+j] = val; 
	Py_RETURN_NONE;
}

static PyObject* mmmod_read(PyObject* self, PyObject* args){
	PyObject *py_a;
	Array *a;
    int i,j;
    
    if(!PyArg_ParseTuple(args,"Oii", &py_a, &i, &j)){
		PyErr_SetString(mmmodError, "cannot parse input tuple when reading.");
		return NULL; //return error if none found
	}
	
    if (!(a = mmmod_get_array(py_a))) {
        PyErr_SetString(mmmodError, "cannot get array when reading.");
        return NULL;
    }
    return Py_BuildValue("i", a->array[i*A_NCOLS+j]);
}

static PyObject* mmmod_mmult_sw(PyObject* self, PyObject* args){
	PyObject *py_a;
	PyObject *py_b;
	PyObject *py_c;
	Array *a; 
    Array *b;
    Array *c;
    
    if(!PyArg_ParseTuple(args,"OOO", &py_a, &py_b, &py_c)){
		PyErr_SetString(mmmodError, "cannot parse input tuple when multiplying.");
		return NULL; //return error if none found
	}
	
    if (!(a = mmmod_get_array(py_a))) {
        PyErr_SetString(mmmodError, "cannot get array A.");
        return NULL;
    }
    if (!(b = mmmod_get_array(py_b))) {
        PyErr_SetString(mmmodError, "cannot get array B.");
        return NULL;
    }
    if (!(c = mmmod_get_array(py_c))) {
        PyErr_SetString(mmmodError, "cannot get array C.");
        return NULL;
    }
    mmult_sw(a->array, b->array, c->array);
	Py_RETURN_NONE;
}

static PyMethodDef mmmod_methods[] = {
	//"Python name"		c-function name		argument presentation		description
	{"Array",	        mmmod_Array,         METH_VARARGS,				"Create the array"},
	{"write",	        mmmod_write,         METH_VARARGS,				"Write an array element"},
	{"read",	        mmmod_read,          METH_VARARGS,				"Read an array element"},
	{"clear", 	        mmmod_clear,         METH_VARARGS,				"Clear the array"},
	{"set", 	        mmmod_set,         METH_VARARGS,				"Set the array"},
	{"mmult_sw",		mmmod_mmult_sw, 	 METH_VARARGS,				"Matrix multiplication"},
	{NULL,NULL,0,NULL}	/* Sentinel */
};

static struct PyModuleDef mmmod = {
    PyModuleDef_HEAD_INIT,
    "mmmod", /* name of module */
    "",          /* module documentation, may be NULL */
    -1,          /* per-interpreter state size of module, or -1 if keeps global variables. */
    mmmod_methods
};

PyMODINIT_FUNC PyInit_mmmod(void){
	PyObject *m; 
	m = PyModule_Create(&mmmod);
	if (m == NULL) return m;
		
	mmmodError = PyErr_NewException("mmmod.error", NULL, NULL); //python error object
	Py_INCREF(mmmodError);
	PyModule_AddObject(m, "error", mmmodError);
	return m;
}

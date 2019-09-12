# -*- coding: utf-8 -*-
# Copyright (c) 2014, Almar Klein and Wade Brainerd
# tinynumpy is distributed under the terms of the MIT License.
#
# Original code by Wade Brainerd (https://github.com/wadetb/tinyndarray)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

""" 
A lightweight, pure Python, numpy compliant ndarray class.

The documenation in this module is rather compact. For details on each
function, see the corresponding documentation at:
http://docs.scipy.org/doc/numpy/reference/index.html Be aware that the
behavior of tinynumpy may deviate in some ways from numpy, or that
certain features may not be supported.
"""

# todo: keep track of readonly better
# todo: mathematical operators
# todo: more methods?
# todo: logspace, meshgrid
# todo: Fortran order?

from __future__ import division
from __future__ import absolute_import

import itertools
import struct
import sys
import ctypes

from math import sqrt
import operator

# Python 2/3 compat
if sys.version_info >= (3, ):
    xrange = range

# Define version numer
__version__ = '0.0.1dev'

# Define dtypes: struct name, short name, numpy name, ctypes type
_dtypes = [('B', 'b1', 'bool', ctypes.c_bool),
           ('b', 'i1', 'int8', ctypes.c_int8),
           ('B', 'u1', 'uint8', ctypes.c_uint8),
           ('h', 'i2', 'int16', ctypes.c_int16),
           ('H', 'u2', 'uint16', ctypes.c_uint16),
           ('i', 'i4', 'int32', ctypes.c_int32),
           ('I', 'u4', 'uint32', ctypes.c_uint32),
           ('q', 'i8', 'int64', ctypes.c_int64),
           ('Q', 'u8', 'uint64', ctypes.c_uint64),
           ('f', 'f4', 'float32', ctypes.c_float),
           ('d', 'f8', 'float64', ctypes.c_double),
           ]

# Inject common dtype names
_known_dtypes = [d[2] for d in _dtypes]
for d in _known_dtypes:
    globals()[d] = d

newaxis = None


def _convert_dtype(dtype, to='numpy'):
    """ Convert dtype, if could not find, pass as it was.
    """
    if dtype is None:
        return dtype
    dtype = str(dtype)
    index = {'array':0, 'short':1, 'numpy':2, 'ctypes':3}[to]
    for dd in _dtypes:
        if dtype in dd:
            return dd[index]
    return dtype  # Otherwise return original


def _ceildiv(a, b):
    return -(-a // b)


def _get_step(view):
    """ Return step to walk over array. If 1, the array is fully
    C-contiguous. If 0, the striding is such that one cannot
    step through the array.
    """
    cont_strides = _strides_for_shape(view.shape, view.itemsize)
    
    step = view.strides[-1] // cont_strides[-1]
    corrected_strides = tuple([i * step for i in cont_strides])
    
    almost_cont = view.strides == corrected_strides
    if almost_cont:
        return step
    else:
        return 0  # not contiguous


def _strides_for_shape(shape, itemsize):
    strides = []
    stride_product = 1
    for s in reversed(shape):
        strides.append(stride_product)
        stride_product *= s
    return tuple([i * itemsize for i in reversed(strides)])


def _size_for_shape(shape):
    stride_product = 1
    for s in shape:
        stride_product *= s
    return stride_product


def squeeze_strides(s):
    """ Pop strides for singular dimensions. """
    return tuple([s[0]] + [s[i] for i in range(1, len(s)) if s[i] != s[i-1]])


def _shape_from_object(obj):
    
    shape = []
    # todo: make more efficient, use len() etc
    def _shape_from_object_r(index, element, axis):
        try:
            for i, e in enumerate(element):
                _shape_from_object_r(i, e, axis+1)
            while len(shape) <= axis:
                shape.append(0)
            l = i + 1
            s = shape[axis]
            if l > s:
                shape[axis] = l
        except TypeError:
            pass

    _shape_from_object_r(0, obj, 0)
    return tuple(shape)


def _assign_from_object(array, obj):
    key = []
    # todo: make more efficient, especially the try-except
    def _assign_from_object_r(element):
        try:
            for i, e in enumerate(element):
                key.append(i)
                _assign_from_object_r(e)
                key.pop()
        except TypeError:
            array[tuple(key)] = element

    _assign_from_object_r(obj)


def _increment_mutable_key(key, shape):
    for axis in reversed(xrange(len(shape))):
        key[axis] += 1
        if key[axis] < shape[axis]:
            return True
        if axis == 0:
            return False
        key[axis] = 0


def _key_for_index(index, shape):
    key = []
    cumshape = [1]
    for i in reversed(shape):
        cumshape.insert(0, cumshape[0] * i)
    for s in cumshape[1:-1]:
        n = index // s
        key.append(n)
        index -= n * s
    key.append(index)
    return tuple(key)


def _zerositer(n):
    for i in xrange(n):
        yield 0



## Public functions

def frombuffer(buffer, dtype, count, offset=0):
    if isinstance(buffer, ndarray):
        offset += buffer._offset
        buffer = buffer._data
    if not isinstance(buffer, _FakeBuffer):
        raise RuntimeError('Only fake buffers supported')
    return ndarray((count,), dtype, buffer=buffer, offset=offset)

def array(obj, dtype=None, copy=True, order=None):
    """ array(obj, dtype=None, copy=True, order=None)
    
    Create a new array. If obj is an ndarray, and copy=False, a view
    of that array is returned. For details see:
    http://docs.scipy.org/doc/numpy/reference/generated/numpy.array.html
    """
    dtype = _convert_dtype(dtype)
    
    if isinstance(obj, ndarray):
        # From existing array
        a = obj.view()
        if dtype is not None and dtype != a.dtype:
            a = a.astype(dtype)
        elif copy:
            a = a.copy()
        return a
    if hasattr(obj, '__array_interface__'):
        # From something that looks like an array, we can create
        # the ctypes array for this and use that as a buffer
        D = obj.__array_interface__
        # Get dtype
        dtype_orig = _convert_dtype(D['typestr'][1:])
        # Create array
        if D['strides']:
            itemsize = int(D['typestr'][-1])
            bufsize = D['strides'][0] * D['shape'][0] // itemsize
        else:
            bufsize = _size_for_shape(D['shape'])
        
        BufType = (_convert_dtype(dtype_orig, 'ctypes') * bufsize)
        buffer = BufType.from_address(D['data'][0])
        a = ndarray(D['shape'], dtype_orig,
                    buffer=buffer, strides=D['strides'], order=order)
        # Convert or copy?
        if dtype is not None and dtype != dtype_orig:
            a = a.astype(dtype)
        elif copy:
            a = a.copy()
        return a
    else:
        # From some kind of iterable
        shape = _shape_from_object(obj)
        # Try to derive dtype
        if dtype is None:
            el = obj
            while isinstance(el, (tuple, list)) and el:
                el = el[0]
            if isinstance(el, int):
                dtype = 'int64'
        # Create array
        a = ndarray(shape, dtype, order=None)
        _assign_from_object(a, obj)
        return a


def zeros_like(a, dtype=None, order=None):
    """ Return an array of zeros with the same shape and type as a given array.
    """
    dtype = a.dtype if dtype is None else dtype
    return zeros(a.shape, dtype, order)


def ones_like(a, dtype=None, order=None):
    """ Return an array of ones with the same shape and type as a given array.
    """
    dtype = a.dtype if dtype is None else dtype
    return ones(a.shape, dtype, order)


def empty_like(a, dtype=None, order=None):
    """ Return a new array with the same shape and type as a given array.
    """
    dtype = a.dtype if dtype is None else dtype
    return empty(a.shape, dtype, order)


def zeros(shape, dtype=None, order=None):
    """Return a new array of given shape and type, filled with zeros
    """
    return empty(shape, dtype, order)


def ones(shape, dtype=None, order=None):
    """Return a new array of given shape and type, filled with ones
    """
    a = empty(shape, dtype, order)
    a.fill(1)
    return a


def eye(size):
    """Return a new 2d array with given dimensions, filled with ones on the
    diagonal and zeros elsewhere.
    """
    a = zeros((size,size))
    for i in xrange(size):
        a[i,i] = 1
    return a


def empty(shape, dtype=None, order=None):
    """Return a new array of given shape and type, without initializing entries
    """
    return ndarray(shape, dtype, order=order)


def arange(*args, **kwargs):
    """ arange([start,] stop[, step,], dtype=None)

    Return evenly spaced values within a given interval.
    
    Values are generated within the half-open interval ``[start, stop)``
    (in other words, the interval including `start` but excluding `stop`).
    For integer arguments the function is equivalent to the Python built-in
    `range <http://docs.python.org/lib/built-in-funcs.html>`_ function,
    but returns an ndarray rather than a list.

    When using a non-integer step, such as 0.1, the results will often not
    be consistent.  It is better to use ``linspace`` for these cases.
    """
    # Get dtype
    dtype = kwargs.pop('dtype', None)
    if kwargs:
        x = list(kwargs.keys())[0]
        raise TypeError('arange() got an unexpected keyword argument %r' % x)
    # Parse start, stop, step
    if len(args) == 0:
        raise TypeError('Required argument "start" not found')
    elif len(args) == 1:
        start, stop, step = 0, int(args[0]), 1
    elif len(args) == 2:
        start, stop, step = int(args[0]), int(args[1]), 1
    elif len(args) == 3:
        start, stop, step = int(args[0]), int(args[1]), int(args[2])
    else:
        raise TypeError('Too many input arguments')
    # Init
    iter = xrange(start, stop, step)
    a = empty((len(iter),), dtype=dtype)
    a[:] = list(iter)
    return a


def linspace(start, stop, num=50, endpoint=True, retstep=False, dtype=None):
    """ linspace(start, stop, num=50, endpoint=True, retstep=False, dtype=None)
    
    Return evenly spaced numbers over a specified interval. Returns num
    evenly spaced samples, calculated over the interval [start, stop].
    The endpoint of the interval can optionally be excluded.
    """
    # Prepare
    start, stop = float(start), float(stop)
    ra = stop - start
    if endpoint:
        step = ra / (num-1)
    else:
        step = ra / num
    # Create
    a = empty((num,), dtype)
    a[:] = [start + i * step for i in xrange(num)]
    # Return
    if retstep:
        return a, step
    else:
        return a

def add(ndarray_vec1, ndarray_vec2):
    c = []
    for a, b in zip(ndarray_vec1, ndarray_vec2):
        c.append(a+b)
    cRay = array(c)
    return cRay

def subtract(ndarray_vec1, ndarray_vec2):
    c = []
    for a, b in zip(ndarray_vec1, ndarray_vec2):
        c.append(a-b)
    cRay = array(c)
    return cRay

def multiply(ndarray_vec1, ndarray_vec2):
    c = []
    for a, b in zip(ndarray_vec1, ndarray_vec2):
        c.append(a*b)
    cRay = array(c)
    return cRay

def divide(ndarray_vec1, integer):
    c = []
    for a in ndarray_vec1:
        c.append(a / integer)
    cRay = array(c)
    return cRay

def cross(u, v):
    """
    Return the cross product of two 2 or 3 dimensional vectors.
    """

    uDim = len(u)
    vDim = len(v)

    uxv = []

    # http://mathworld.wolfram.com/CrossProduct.html
    if uDim == vDim == 2:
        uxv = [u[0]*v[1]-u[1]*v[0]]            
    elif uDim == vDim == 3:
        for i in range(uDim):
            uxv = [u[1]*v[2]-u[2]*v[1], -(u[0]*v[2]-u[2]*v[0]),
                   u[0]*v[1]-u[1]*v[0]]
    else:
        raise IndexError('Vector has invalid dimensions')
    return uxv

def dot(u, v):
    """
    Return the dot product of two equal-dimensional vectors.
    """

    uDim = len(u)
    vDim = len(v)

    # http://reference.wolfram.com/language/ref/Dot.html
    if uDim == vDim:
        u_dot_v = sum(map(operator.mul, u, v))
    else:
        raise IndexError('Vector has invalid dimensions')
    return u_dot_v

class _FakeBuffer:
    def __init__(self, length, stype, hook=None, offset=0):
        self._struct = struct.Struct(stype)
        self._itemsize = self._struct.size
        self._bytearray = bytearray(length * self._itemsize)
        self._hook = hook
        self._offset = offset

    def __getitem__(self, key):
        offset = self._itemsize * key + self._offset
        if self._hook:
            return self._struct.unpack(
                self._hook.read(offset, self._itemsize))[0];
        else:
            return self._struct.unpack(self._bytearray[offset:offset+self._itemsize])[0]
    
    def __setitem__(self, key, value):
        if isinstance(key, slice):
            for i, v in itertools.zip_longest(range(key.start, key.stop, key.step), value):
                self.__setitem__(i,v)
        else:
            offset = self._itemsize * key + self._offset
            data = self._struct.pack(value)
            if self._hook:
                self._hook.write(offset, data)
            else:
                self._bytearray[offset:offset+self._itemsize] = data

## The class

class ndarray(object):
    """ ndarray(shape, dtype='float64', buffer=None, offset=0,
                strides=None, order=None)
    
    Array class similar to numpy's ndarray, implemented in pure Python.
    This class can be distinguished from a real numpy array in that
    the repr always shows the dtype as a string, and for larger arrays
    (more than 100 elements) it shows a short one-line repr.
    
    An array object represents a multidimensional, homogeneous array
    of fixed-size items.  An associated data-type property describes the
    format of each element in the array.
    
    Arrays should be constructed using `array`, `zeros` or `empty` (refer
    to the See Also section below).  The parameters given here refer to
    a low-level method (`ndarray(...)`) for instantiating an array.
    
    Parameters
    ----------
    shape : tuple of ints
        Shape of created array.
    dtype : data-type, optional
        Any object that can be interpreted as a numpy data type.
    buffer : object contaning data, optional
        Used to fill the array with data. If another ndarray is given,
        the underlying data is used. Can also be a ctypes.Array or any
        object that exposes the buffer interface.
    offset : int, optional
        Offset of array data in buffer.
    strides : tuple of ints, optional
        Strides of data in memory.
    order : {'C', 'F'}, optional  NOT SUPPORTED
        Row-major or column-major order.

    Attributes
    ----------
    T : ndarray
        Transpose of the array. In tinynumpy only supported for ndim <= 3.
    data : buffer
        The array's elements, in memory. In tinynumpy this is a ctypes array.
    dtype : str
        Describes the format of the elements in the array. In tinynumpy
        this is a string.
    flags : dict
        Dictionary containing information related to memory use, e.g.,
        'C_CONTIGUOUS', 'OWNDATA', 'WRITEABLE', etc.
    flat : iterator object
        Flattened version of the array as an iterator. In tinynumpy
        the iterator cannot be indexed.
    size : int
        Number of elements in the array.
    itemsize : int
        The memory use of each array element in bytes.
    nbytes : int
        The total number of bytes required to store the array data,
        i.e., ``itemsize * size``.
    ndim : int
        The array's number of dimensions.
    shape : tuple of ints
        Shape of the array.
    strides : tuple of ints
        The step-size required to move from one element to the next in
        memory. For example, a contiguous ``(3, 4)`` array of type
        ``int16`` in C-order has strides ``(8, 2)``.  This implies that
        to move from element to element in memory requires jumps of 2 bytes.
        To move from row-to-row, one needs to jump 8 bytes at a time
        (``2 * 4``).
    base : ndarray
        If the array is a view into another array, that array is its `base`
        (unless that array is also a view).  The `base` array is where the
        array data is actually stored.
    __array_interface__ : dict
        Dictionary with low level array information. Used by numpy to
        turn into a real numpy array. Can also be used to give C libraries
        access to the data via ctypes.
    
    See Also
    --------
    array : Construct an array.
    zeros : Create an array, each element of which is zero.
    empty : Create an array, but leave its allocated memory unchanged (i.e.,
            it contains "garbage").
    
    Notes
    -----
    There are two modes of creating an array:

    1. If `buffer` is None, then only `shape`, `dtype`, and `order`
       are used.
    2. If `buffer` is an object exposing the buffer interface, then
       all keywords are interpreted.
    
    """
    
    __slots__ = ['_dtype', '_shape', '_strides', '_itemsize', 
                 '_offset', '_base', '_data']
    
    def __init__(self, shape, dtype='float64', buffer=None, offset=0,
                 strides=None, order=None, hook=None):
        # Check order
        if order is not None:
            raise RuntimeError('ndarray order parameter is not supported')
        # Check and set shape
        assert isinstance(shape, tuple)
        assert all([isinstance(x, int) for x in shape])
        self._shape = shape
        # Check and set dtype
        dtype = _convert_dtype(dtype) if (dtype is not None) else 'float64'
        if dtype not in _known_dtypes:
            raise TypeError('data type %r not understood' % dtype)
        self._dtype = dtype
        # Itemsize is directly derived from dtype
        self._itemsize = int(_convert_dtype(dtype, 'short')[-1])
        
        if buffer is None:
            # New array
            self._base = None
            # Check and set offset and strides
            assert offset == 0
            self._offset = 0
            assert strides is None
            self._strides = _strides_for_shape(self._shape, self.itemsize)
        
        else:
            # Keep a reference to avoid memory cleanup
            self._base = buffer
            # for ndarray we use the data property
            if isinstance(buffer, ndarray):
                buffer = buffer.data
            # Check and set offset
            assert isinstance(offset, int) and offset >= 0
            self._offset = offset
            # Check and set strides
            if strides is None:
                strides = _strides_for_shape(shape, self.itemsize)
            assert isinstance(strides, tuple)
            assert all([isinstance(x, int) for x in strides])
            assert len(strides) == len(shape)
            self._strides = strides
        
        # Define our buffer class
        buffersize = self._strides[0] * self._shape[0] // self._itemsize
        stype = _convert_dtype(dtype, 'array')
        self._offset = 0
        
        # Create buffer
        if buffer is None:
            self._data = _FakeBuffer(buffersize, stype, hook)
        elif isinstance(buffer, _FakeBuffer):
            self._data = _FakeBuffer(buffersize, stype)
            self._data._bytearray = buffer._bytearray
            self._data._hook = buffer._hook
            self._data._offset = buffer._offset + offset * self._itemsize
        else:
            raise RuntimeError("Arrays can only be created from other arrays")
            
    
    @property
    def __array_interface__(self):
        """ Allow converting to real numpy array, or pass pointer to C library
        http://docs.scipy.org/doc/numpy/reference/arrays.interface.html
        """
        readonly = False
        # typestr
        typestr = '<' + _convert_dtype(self.dtype, 'short')
        # Pointer
        if isinstance(self._data, ctypes.Array):
            ptr = ctypes.addressof(self._data)
        elif hasattr(self._data, '__array_interface__'):
            ptr, readonly = self._data.__array_interface__['data']
        elif hasattr(self._data, 'buffer_info'):  # Python's array.array
            ptr = self._data.buffer_info()[0]
        elif isinstance(self._data, bytes):
            ptr = ctypes.cast(self._data, ctypes.c_void_p).value
            readonly = True
        else:
            raise TypeError('Cannot get address to underlying array data')
        ptr += self._offset * self.itemsize
        #
        return dict(version=3,
                    shape=self.shape,
                    typestr=typestr,
                    descr=[('', typestr)],
                    data=(ptr, readonly),
                    strides=self.strides,
                    #offset=self._offset,
                    #mask=None,
                    )
    
    def __len__(self):
        return self.shape[0]
    
    def __getitem__(self, key):
        offset, shape, strides = self._index_helper(key)
        if not shape:
            # Return scalar
            return self._data[offset]
        else:
            # Return view
            return ndarray(shape, self.dtype,
                           offset=offset, strides=strides, buffer=self)
    
    def __setitem__(self, key, value):
        
        # Get info for view
        offset, shape, strides = self._index_helper(key)
        
        # Is this easy?
        if not shape:
            self._data[offset] = value
            return

        # Create view to set data to
        view = ndarray(shape, self.dtype,
                        offset=offset, strides=strides, buffer=self)
        
        # Get data to set as a list (because getting slices from ctype
        # arrays yield lists anyway). The list is our "contiguous array" 
        if isinstance(value, (float, int)):
            value_list = [value] * view.size
        elif isinstance(value, (tuple, list)):
            value_list = value
        else:
            if not isinstance(value, ndarray):
                value = array(value, copy=False)
            value_list = value._toflatlist()
        
        # Check if size match
        if view.size != len(value_list):
            raise ValueError('Number of elements in source does not match '
                                'number of elements in target.')
        
        # Assign data in most efficient way that we can. This code
        # looks for the largest semi-contiguous block: the block that
        # we can access as a 1D array with a stepsize.
        subviews = [view]
        value_index = 0
        count = 0
        while subviews:
            subview = subviews.pop(0)
            step = _get_step(subview)
            if step:
                block = value_list[value_index:value_index+subview.size]
                s = slice(subview._offset, 
                            subview._offset + subview.size * step, 
                            step)
                view._data[s] = block
                value_index += subview.size
                count += 1
            else:
                for i in range(subview.shape[0]):
                    subviews.append(subview[i])
        assert value_index == len(value_list)
    
    def __float__(self):
        if self.size == 1:
            return float(self.data[self._offset])
        else:
            raise TypeError('Only length-1 arrays can be converted to scalar')
    
    def __int__(self):
        if self.size == 1:
            return int(self.data[self._offset])
        else:
            raise TypeError('Only length-1 arrays can be converted to scalar')
    
    def __repr__(self):
        # If more than 100 elements, show short repr
        if self.size > 100:
            shapestr = 'x'.join([str(i) for i in self.shape])
            return '<ndarray %s %s at 0x%x>' % (shapestr, self.dtype, id(self))
        # Otherwise, try to show in nice way
        def _repr_r(s, axis, offset):
            axisindent = min(2, max(0, (self.ndim - axis - 1)))
            if axis < len(self.shape):
                s += '['
                for k_index, k in enumerate(xrange(self.shape[axis])):
                    if k_index > 0:
                        s += ('\n       ' + ' ' * axis)  * axisindent
                    offset_ = offset + k * self._strides[axis] // self.itemsize
                    s = _repr_r(s, axis+1, offset_)
                    if k_index < self.shape[axis] - 1:
                        s += ', '
                s += ']'
            else:
                r = repr(self.data[offset])
                if '.' in r:
                    r = ' ' + r
                    if r.endswith('.0'):
                        r = r[:-1]
                s += r
            return s

        s = _repr_r('', 0, self._offset)
        if self.dtype != 'float64' and self.dtype != 'int32':
            return "array(" + s + ", dtype='%s')" % self.dtype
        else:
            return "array(" + s + ")"
    
    def __eq__(self, other):
        if other.__module__.split('.')[0] == 'numpy':
            return other == self
        else:
            out = empty(self.shape, 'bool')
            out[:] = [i1==i2 for (i1, i2) in zip(self.flat, other.flat)]
            return out
    
    ## Private helper functions
    
    def _index_helper(self, key):
        
        # Indexing spec is located at:
        # http://docs.scipy.org/doc/numpy/reference/arrays.indexing.html

        # Promote to tuple.
        if not isinstance(key, tuple):
            key = (key,)

        axis = 0
        shape = []
        strides = []
        offset = self._offset

        for k in key:
            axissize = self._shape[axis]
            if isinstance(k, int):
                if k >= axissize:
                    raise IndexError('index %i is out of bounds for axis %i '
                                     'with size %s' % (k, axis, axissize))
                offset += k * self._strides[axis] // self.itemsize
                axis += 1
            elif isinstance(k, slice):
                start, stop, step = k.indices(self.shape[axis])
                shape.append(_ceildiv(stop - start, step))
                strides.append(step * self._strides[axis])
                offset += start * self._strides[axis] // self.itemsize
                axis += 1
            elif k is Ellipsis:
                raise TypeError("ellipsis are not supported.")
            elif k is None:
                shape.append(1)
                stride = 1
                for s in self._strides[axis:]:
                    stride *= s
                strides.append(stride)
            else:
                raise TypeError("key elements must be instaces of int or slice.")

        shape.extend(self.shape[axis:])
        strides.extend(self._strides[axis:])
        
        return offset, tuple(shape), tuple(strides)
    
    def _toflatlist(self):
        value_list = []
        subviews = [self]
        count = 0
        while subviews:
            subview = subviews.pop(0)
            step = _get_step(subview)
            if step:
                s = slice(subview._offset, 
                          subview._offset + subview.size * step, 
                          step)
                value_list += self._data[s]
                count += 1
            else:
                for i in range(subview.shape[0]):
                    subviews.append(subview[i])
        return value_list
    
    ## Properties
    
    @property
    def ndim(self):
        return len(self._shape)
    
    @property
    def size(self):
        return _size_for_shape(self._shape)
    
    @property
    def nbytes(self):
        return _size_for_shape(self._shape) * self.itemsize
    
    def _get_shape(self):
        return self._shape
    
    def _set_shape(self, newshape):
        if newshape == self.shape:
            return
        if self.size != _size_for_shape(newshape):
            raise ValueError('Total size of new array must be unchanged')
        if _get_step(self) == 1:
            # Contiguous, hooray!
            self._shape = tuple(newshape)
            self._strides = _strides_for_shape(self._shape, self.itemsize)
            return
        
        # Else, try harder ... This code supports adding /removing
        # singleton dimensions. Although it may sometimes be possible
        # to split a dimension in two if the contiguous blocks allow
        # this, we don't bother with such complex cases for now.
        # Squeeze shape / strides 
        N = self.ndim
        shape = [self.shape[i] for i in range(N) if self.shape[i] > 1]
        strides = [self.strides[i] for i in range(N) if self.shape[i] > 1]
        # Check if squeezed shapes match
        newshape_ = [newshape[i] for i in range(len(newshape)) 
                     if newshape[i] > 1]
        if newshape_ != shape:
            raise AttributeError('incompatible shape for non-contiguous array')
        # Modify to make this data work in loop
        strides.append(strides[-1])
        shape.append(1)
        # Form new strides
        i = -1
        newstrides = []
        try:
            for s in reversed(newshape):
                if s == 1:
                    newstrides.append(strides[i] * shape[i])
                else:
                    i -= 1
                    newstrides.append(strides[i])
        except IndexError:
            # Fail
            raise AttributeError('incompatible shape for non-contiguous array')
        else:
            # Success
            newstrides.reverse()
            self._shape = tuple(newshape)
            self._strides = tuple(newstrides)
    
    shape = property(_get_shape, _set_shape)  # Python 2.5 compat (e.g. Jython)
    
    @property
    def strides(self):
        return self._strides
    
    @property
    def dtype(self):
        return self._dtype
    
    @property
    def itemsize(self):
        return self._itemsize
    
    @property
    def base(self):
        return self._base
    
    @property
    def data(self):
        return self._data
    
    @property
    def flat(self):
        subviews = [self]
        count = 0
        while subviews:
            subview = subviews.pop(0)
            step = _get_step(subview)
            if step:
                s = slice(subview._offset, 
                          subview._offset + subview.size * step, 
                          step)
                for i in self._data[s]:
                    yield i
            else:
                for i in range(subview.shape[0]):
                    subviews.append(subview[i])
    
    @property
    def T(self):
        if self.ndim < 2:
            return self
        else:
            return self.transpose()
    
    @property
    def flags(self):
        
        c_cont = _get_step(self) == 1
        return dict(C_CONTIGUOUS=c_cont,
                    F_CONTIGUOUS=(c_cont and self.ndim < 2),
                    OWNDATA=(self._base is None),
                    WRITEABLE=True, # todo: fix this
                    ALIGNED=c_cont,  # todo: different from contiguous?
                    UPDATEIFCOPY=False,  # We don't support this feature
               )
    
    ## Methods - managemenet
    
    def fill(self, value):
        assert isinstance(value, (int, float))
        self[:] = value
    
    def clip(self, a_min, a_max, out=None):
        if out is None:
            out = empty(self.shape, self.dtype)
        L = self._toflatlist()
        L = [min(a_max, max(a_min, x)) for x in L]
        out[:] = L
        return out
    
    def copy(self):
        out = empty(self.shape, self.dtype)
        out[:] = self
        return out
    
    def flatten(self):
        out = empty((self.size,), self.dtype)
        out[:] = self
        return out
    
    def ravel(self):
        return self.reshape((self.size, ))
    
    def repeat(self, repeats, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        out = empty((self.size * repeats,), self.dtype)
        for i in range(repeats):
            out[i*self.size:(i+1)*self.size] = self
        return out
    
    def reshape(self, newshape):
        out = self.view()
        try:
            out.shape = newshape
        except AttributeError:
            out = self.copy()
            out.shape = newshape
        return out
    
    def transpose(self):
        # Numpy returns a view, but we cannot do that since we do not
        # support Fortran ordering
        ndim = self.ndim
        if ndim < 2:
            return self.view()
        shape = self.shape[::-1]
        out = empty(shape, self.dtype)
        #
        if ndim == 2:
            for i in xrange(self.shape[0]):
                out[:, i] = self[i, :]
        elif ndim == 3:
            for i in xrange(self.shape[0]):
                for j in xrange(self.shape[1]):
                    out[:, j, i] = self[i, j, :]
        else:
            raise ValueError('Tinynumpy supports transpose up to ndim=3')
        return out
    
    def astype(self, dtype):
        out = empty(self.shape, dtype)
        out[:] = self
    
    def view(self, dtype=None, type=None):
        if dtype is None:
            dtype = self.dtype
        if dtype == self.dtype:
            return ndarray(self.shape, dtype, buffer=self, 
                           offset=self._offset, strides=self.strides)
        elif self.ndim == 1:
            itemsize = int(_convert_dtype(dtype, 'short')[-1])
            size = self.nbytes // itemsize
            offsetinbytes = self._offset * self.itemsize
            offset = offsetinbytes // itemsize
            return ndarray((size, ), dtype, buffer=self, offset=offset)
        else:
            raise ValueError('new type not compatible with array.')
    
    ## Methods - statistics
    
    # We use the self.flat generator here. self._toflatlist() would be
    # faster, but it might take up significantly more memory.
    
    def all(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        return all(self.flat)
    
    def any(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        return any(self.flat)
    
    def min(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        return min(self.flat)
    
    def max(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        return max(self.flat)
        #return max(self._toflatlist())  # almost twice as fast
    
    def sum(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        return sum(self.flat)
    
    def prod(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        p = 1.0
        for i in self.flat:
            p *= float(i)
        return p
        
    def ptp(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        mn = self.data[self._offset]
        mx = mn
        for i in self.flat:
            if i > mx:
                mx = i
            if i < mn:
                mn = i
        return mx - mn

    def mean(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        return self.sum() / self.size
    
    def argmax(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        r = self.data[self._offset]
        r_index = 0
        for i_index, i in enumerate(self.flat):
            if i > r:
                r = i
                r_index = i_index
        return r_index

    def argmin(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        r = self.data[self._offset]
        r_index = 0
        for i_index, i in enumerate(self.flat):
            if i < r:
                r = i
                r_index = i_index
        return r_index
    
    def cumprod(self, axis=None, out=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        if out is None:
            out = empty((self.size,), self.dtype)
        p = 1
        L = []
        for x in self.flat:
            p *= x
            L.append(p)
        out[:] = L
        return out

    def cumsum(self, axis=None, out=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        if out is None:
            out = empty((self.size,), self.dtype)
        p = 0
        L = []
        for x in self.flat:
            p += x
            L.append(p)
        out[:] = L
        return out

    def var(self, axis=None):
        if axis:
            raise (TypeError, "axis argument is not supported")
        m = self.mean()
        acc = 0
        for x in self.flat:
            acc += abs(x - m) ** 2
        return acc / self.size

    def std(self, axis=None):
        return sqrt(self.var(axis))

class nditer:
    def __init__(self, array):
        self.array = array
        self.key = [0] * len(self.array.shape)

    def __iter__(self):
        return self

    def __len__(self):
        return _size_for_shape(self.array.shape)

    def __getitem__(self, index):
        key = _key_for_index(index, self.array.shape)
        return self.array[key]

    def __next__(self):
        if self.key is None:
            raise StopIteration
        value = self.array[tuple(self.key)]
        if not _increment_mutable_key(self.key, self.array.shape):
            self.key = None
        return value

    def next(self):
        return self.__next__()

from distutils.core import setup, Extension

module1 = Extension('mmmod',
	libraries = ['pthread'],
	sources = ['mmmodule.c']
	)
	
setup (name = 'mmmod',
	   version = '1.0',
	   description = 'This is a matrix multiplication module',
	   author = 'yunqu',
	   url = 'https://sites.google.com/site/yunrockqu/home',
	   ext_modules=[module1]
	   )
	   
	
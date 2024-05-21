#   Copyright (c) 2019, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from setuptools import setup


with open("README.md", encoding='utf-8') as fh:
    readme_lines = fh.readlines()[:]
long_description = (''.join(readme_lines))


setup(
    name="xsdfec",
    version='1.0',
    description="Driver for the Soft-Decision Forward Error Correction IP",
    long_description=long_description,
    url='https://github.com/Xilinx/PYNQ/tree/master/sdbuild/packages/xsdfec',
    license='BSD 3-Clause',
    author="Craig Ramsay",
    author_email="cramsay01@gmail.com",
    packages=['xsdfec'],
    package_data={
        '': ['*.py', '*.so', '*.c'],
    },
    install_requires=[
        'wurlitzer',
        'parsec',
    ]
)


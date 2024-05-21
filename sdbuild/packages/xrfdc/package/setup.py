#   Copyright (c) 2019, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from setuptools import setup


with open("README.md", encoding='utf-8') as fh:
    readme_lines = fh.readlines()[:]
long_description = (''.join(readme_lines))


setup(
    name="xrfdc",
    version='1.0',
    description="Driver for the RFSoC RF Data Converter IP",
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/Xilinx/PYNQ/tree/master/sdbuild/packages/xrfdc',
    license='BSD 3-Clause',
    author="Craig Ramsay",
    author_email="cramsay01@gmail.com",
    packages=['xrfdc'],
    package_data={
        '': ['*.py', '*.so', '*.c'],
    },
    install_requires=[
        'wurlitzer',
    ]
)


#   Copyright (c) 2020, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause


from setuptools import setup


with open("README.md", encoding='utf-8') as fh:
    readme_lines = fh.readlines()[:]
long_description = (''.join(readme_lines))


setup(
    name="xrfclk",
    version='2.0',
    description="Driver for the clock synthesizers on Zynq RFSoC boards",
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/Xilinx/PYNQ/tree/master/sdbuild/packages/xrfclk',
    license='BSD 3-Clause',
    author="Yun Rock Qu",
    author_email="pynq_support@xilinx.com",
    packages=['xrfclk'],
    package_data={
        '': ['*.py', '*.so', '*.txt'],
    }
)


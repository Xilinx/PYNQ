# Copyright (C) 2022 Xilinx, Inc
# Copyright (C) 2022-2026 Advanced Micro Devices, Inc.
# SPDX-License-Identifier: BSD-3-Clause

PACKAGE_BUILD_pynq += ${PYNQ_UPDATE}
PACKAGE_BUILD_pynq += $(PYNQ_METADATA) $(PYNQ_UTILS)

ifdef REBUILD_PYNQ_SDIST
PACKAGE_BUILD_pynq += $(shell find "$(ROOTDIR)/../pynq" \
    -name '__pycache__' -prune -o -name '*.pyc' -prune -o -print)
endif

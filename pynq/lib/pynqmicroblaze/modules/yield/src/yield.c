// Copyright (C) 2022 Xilinx, Inc
// SPDX-License-Identifier: BSD-3-Clause

#include <yield.h>

void _handle_events(void);

void yield(void) {
    _handle_events();
}

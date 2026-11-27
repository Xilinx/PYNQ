// Copyright (C) 2026 Advanced Micro Devices, Inc.
// SPDX-License-Identifier: BSD-3-Clause

#ifndef PYNQ_INTERRUPT_H
#define PYNQ_INTERRUPT_H

#include <memory>
#include <string>
#include <grpcpp/grpcpp.h>
#include <remote_device.grpc.pb.h>

class InterruptManager {
public:
    InterruptManager();
    ~InterruptManager();
    std::string generation();
    std::string invalidate();
    bool resume(const std::string &generation);
    grpc::Status serve(grpc::ServerContext *context,
        grpc::ServerReaderWriter<remote_device::InterruptResponse,
                                 remote_device::InterruptRequest> *stream);
private:
    struct State;
    std::unique_ptr<State> state_;
};

#endif

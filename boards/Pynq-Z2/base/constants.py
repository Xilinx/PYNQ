#   Copyright (c) 2016, Xilinx, Inc.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   1.  Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
#   3.  Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
#   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#   OR BUSINESS INTERRUPTION). HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#   ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


__author__ = "Yun Rock Qu"
__copyright__ = "Copyright 2017, Xilinx"
__email__ = "pynq_support@xilinx.com"


PYNQZ2_RPI_SPECIFICATION = {'interface_width': 28,
                            'monitor_width': 64,
                            'traceable_io_pins': {'D27': 0,
                                                  'D28': 1,
                                                  'D3': 2,
                                                  'D5': 3,
                                                  'D7': 4,
                                                  'D29': 5,
                                                  'D31': 6,
                                                  'D26': 7,
                                                  'D24': 8,
                                                  'D21': 9,
                                                  'D19': 10,
                                                  'D23': 11,
                                                  'D32': 12,
                                                  'D33': 13,
                                                  'D8': 14,
                                                  'D10': 15,
                                                  'D36': 16,
                                                  'D11': 17,
                                                  'D12': 18,
                                                  'D35': 19,
                                                  'D38': 20,
                                                  'D40': 21,
                                                  'D15': 22,
                                                  'D16': 23,
                                                  'D18': 24,
                                                  'D22': 25,
                                                  'D37': 26,
                                                  'D13': 27
                                                  },
                            'traceable_tri_states': {'D27': 28,
                                                     'D28': 29,
                                                     'D3': 30,
                                                     'D5': 31,
                                                     'D7': 32,
                                                     'D29': 33,
                                                     'D31': 34,
                                                     'D26': 35,
                                                     'D24': 36,
                                                     'D21': 37,
                                                     'D19': 38,
                                                     'D23': 39,
                                                     'D32': 40,
                                                     'D33': 41,
                                                     'D8': 42,
                                                     'D10': 43,
                                                     'D36': 44,
                                                     'D11': 45,
                                                     'D12': 46,
                                                     'D35': 47,
                                                     'D38': 48,
                                                     'D40': 49,
                                                     'D15': 50,
                                                     'D16': 51,
                                                     'D18': 52,
                                                     'D22': 53,
                                                     'D37': 54,
                                                     'D13': 55
                                                     }
                            }
PYNQZ2_PMODA_SPECIFICATION = {'interface_width': 8,
                              'monitor_width': 64,
                              'traceable_io_pins': {'D0': 14,
                                                    'D1': 15,
                                                    'D2': 0,
                                                    'D3': 1,
                                                    'D4': 24,
                                                    'D5': 25,
                                                    'D6': 2,
                                                    'D7': 3
                                                    },
                              'traceable_tri_states': {'D0': 42,
                                                       'D1': 43,
                                                       'D2': 28,
                                                       'D3': 29,
                                                       'D4': 52,
                                                       'D5': 53,
                                                       'D6': 30,
                                                       'D7': 31
                                                       }
                              }
PYNQZ2_PMODB_SPECIFICATION = {'interface_width': 8,
                              'monitor_width': 32,
                              'traceable_io_pins': {'D0': 0,
                                                    'D1': 1,
                                                    'D2': 2,
                                                    'D3': 3,
                                                    'D4': 4,
                                                    'D5': 5,
                                                    'D6': 6,
                                                    'D7': 7
                                                    },
                              'traceable_tri_states': {'D0': 8,
                                                       'D1': 9,
                                                       'D2': 10,
                                                       'D3': 11,
                                                       'D4': 12,
                                                       'D5': 13,
                                                       'D6': 14,
                                                       'D7': 15
                                                       }
                              }
PYNQZ2_ARDUINO_SPECIFICATION = {'interface_width': 22,
                                'monitor_width': 64,
                                'traceable_io_pins': {'A0': 0,
                                                      'A1': 1,
                                                      'A2': 2,
                                                      'A3': 3,
                                                      'A4': 4,
                                                      'A5': 5,
                                                      'D0': 6,
                                                      'D1': 7,
                                                      'D2': 8,
                                                      'D3': 9,
                                                      'D4': 10,
                                                      'D5': 11,
                                                      'D6': 12,
                                                      'D7': 13,
                                                      'D8': 14,
                                                      'D9': 15,
                                                      'D10': 16,
                                                      'D11': 17,
                                                      'D12': 18,
                                                      'D13': 19,
                                                      'SDA': 20,
                                                      'SCL': 21
                                                      },
                                'traceable_tri_states': {'A0': 22,
                                                         'A1': 23,
                                                         'A2': 24,
                                                         'A3': 25,
                                                         'A4': 26,
                                                         'A5': 27,
                                                         'D0': 28,
                                                         'D1': 29,
                                                         'D2': 30,
                                                         'D3': 31,
                                                         'D4': 32,
                                                         'D5': 33,
                                                         'D6': 34,
                                                         'D7': 35,
                                                         'D8': 36,
                                                         'D9': 37,
                                                         'D10': 38,
                                                         'D11': 39,
                                                         'D12': 40,
                                                         'D13': 41,
                                                         'SDA': 42,
                                                         'SCL': 43
                                                         }
                                }

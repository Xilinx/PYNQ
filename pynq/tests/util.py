#   Copyright (c) 2016, Xilinx, Inc.
#   SPDX-License-Identifier: BSD-3-Clause



def user_answer_yes(text):
    answer = input(text + ' ([yes]/no)>>> ').lower()
    return answer == 'y' or answer == 'yes' or answer == ''


def user_answer_no(text):
    answer = input(text + ' (yes/[no])>>> ').lower()
    return answer == 'n' or answer == 'no' or answer == ''


def get_interface_id(text, options):
    options_str = [str(x) for x in options]
    options_text = '/'.join(options_str)
    ret_str = input(
        "Type in the interface ID of the {} ({}): ".format(
            text, options_text))
    ret_str = ret_str.strip().upper()
    if ret_str not in options_str:
        raise ValueError('Please use a valid interface ID.')
    return ret_str



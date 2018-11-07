#include <unistd.h>
#include <pyprintf.h>
#include <string.h>
#include <stdarg.h>

static const char printf_command = 2;

void complete_write(int fd, const char* data, unsigned int length) {
    while (length > 0) {
        int written = write(fd, data, length);
        length -= written;
        data += written;
    }
}

void pyprintf(const char* format, ...) {
    unsigned short len = strlen(format);
    complete_write(3, (const char *)&printf_command, 1);
    complete_write(3, (const char *)&len, 2);
    complete_write(3, format, len);
    int in_special = 0;
    va_list args;
    va_start(args, format);
    while (*format != '\0') {
        if (in_special) {
            switch (*format) {
            case 'd':
            case 'o':
            case 'u':
            case 'x':
            case 'X':
            {
                int val = va_arg(args, int);
                complete_write(3, (const char *)&val, sizeof(val));
            }
                break;
            case 'f':
            case 'F':
            case 'g':
            case 'G':
            case 'e':
            case 'E':
            {
                float val = (double)va_arg(args, double);
                complete_write(3, (const char *)&val, sizeof(val));
            }
                break;
            case 's':
            {
                char* str = (char*)va_arg(args, char*);
                short len = strlen(str);
                complete_write(3, (const char *)&len, sizeof(len));
                complete_write(3, str, len);
            }
                break;
            case 'c':
            {
                char val = (char)va_arg(args, int);
                complete_write(3, &val, sizeof(val));
            }
                break;
            }
            in_special = 0;
        } else if (*format == '%') {
            in_special = 1;
        }
        ++format;
    }
}

#include <yield.h>

void _handle_events(void);

void yield(void) {
    _handle_events();
}

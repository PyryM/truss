/*
 * 'Fake' string.h to be included by terra on windows systems which don't
 * have visual studio installed
 */

#ifndef STRING_H
#define STRING_H

#include <stddef.h>

void * memcpy ( void * destination, const void * source, size_t num );

#endif // STRING_H

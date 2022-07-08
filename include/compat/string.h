/*
 * 'Fake' string.h to be included by terra on windows systems which don't
 * have visual studio installed
 */
#ifndef TRUSS_STRING_H
#define TRUSS_STRING_H

/*
 * Used by truss to check whether this header has been included from compat
 * or from the actual system includes
 */
#define TRUSS_CHECK_STRING 7777

#include <stddef.h>

void * memcpy(void * destination, const void * source, size_t num);

#endif // TRUSS_STRING_H

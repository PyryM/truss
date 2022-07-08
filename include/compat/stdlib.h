/*
 * 'Fake' stdlib.h to be included by terra on windows systems which don't
 * have visual studio installed
 */
#ifndef TRUSS_STDLIB_H
#define TRUSS_STDLIB_H

/*
 * Used by truss to check whether this header has been included from fakestd
 * or from the actual system includes
 */
#define TRUSS_CHECK_STDLIB 7777

#include <stddef.h>

void* malloc(size_t size);
void free(void* ptr);

#endif /* TRUSS_STDLIB_H */

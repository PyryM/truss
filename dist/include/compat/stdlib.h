/*
 * 'Fake' stdlib.h to be included by terra on windows systems which don't
 * have visual studio installed
 */

#ifndef STDLIB_H
#define STDLIB_H

 /*
 *  Used by truss to check whether this header has been included from fakestd
 *  or from the actual system includes
 */
#define TRUSS_CHECK 7777

typedef unsigned long long size_t;

void* malloc (size_t size);
void free (void* ptr);

#endif /* STDLIB_H */

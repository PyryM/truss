/*
 * 'Fake' stdio.h to be included by terra on windows systems which don't
 * have visual studio installed
 */
#ifndef TRUSS_STDIO_H
#define TRUSS_STDIO_H

/*
 * Used by truss to check whether this header has been included from compat
 * or from the actual system includes
 */
#define TRUSS_CHECK_STDIO 7777

/* We only use sprintf and sscanf out of stdio */

int printf (const char *, ... );
int sprintf(char *, const char *, ...);
int sscanf(const char *, const char *, ...);

#endif /* TRUSS_STDIO_H */

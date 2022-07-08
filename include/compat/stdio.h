/*
 * 'Fake' stdio.h to be included by terra on windows systems which don't
 * have visual studio installed
 */
#ifndef TRUSS_STDIO_H
#define TRUSS_STDIO_H

#include "stddef.h"

/*
 * Used by truss to check whether this header has been included from compat
 * or from the actual system includes
 */
#define TRUSS_CHECK_STDIO 7777

/* We only use sprintf and sscanf out of stdio */

int printf (const char *, ... );
int sprintf(char *, const char *, ...);
int snprintf(char *, size_t, const char *, ... );
int sscanf(const char *, const char *, ...);

typedef struct FILE FILE;
size_t fread(void* ptr, size_t size, size_t count, FILE* stream);
size_t fwrite(const void* ptr, size_t size, size_t count, FILE* stream);
FILE* fopen(const char* filename, const char* mode);
int fclose(FILE* stream);
int fseek(FILE* stream, long int offset, int origin);
long int ftell(FILE* stream);
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#endif /* TRUSS_STDIO_H */

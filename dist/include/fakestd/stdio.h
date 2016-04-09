/*
 * 'Fake' stdio.h to be included by terra on windows systems which don't
 * have visual studio installed
 */

#ifndef STDIO_H
#define STDIO_H

/* We only use sprintf and sscanf out of stdio */

int	 sprintf(char *, const char *, ...);
int	 sscanf(const char *, const char *, ...);

#endif /* STDIO_H */
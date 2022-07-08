/*
 * Since truss only works on 64-bit machines, our compatibility header simply
 * assumes you are running on a 64-bit machine.
 */
#ifndef TRUSS_STDDEF_H
#define TRUSS_STDDEF_H

/*
 * Used by truss to check whether this header has been included from compat
 * or from the actual system includes
 */
#define TRUSS_CHECK_STDDEF 7777

#if defined(_WIN64)
  typedef long long unsigned int size_t;
  typedef long long int ssize_t;
#else
  typedef long unsigned int size_t;
  typedef long int ssize_t;
#endif

#endif /* TRUSS_STDDEF_H */

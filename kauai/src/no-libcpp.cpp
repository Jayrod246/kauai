#include <stdlib.h>

extern "C" void __cxa_pure_virtual() { while (1); }

void * operator new(size_t n)
{
  return malloc(n);
}
void operator delete(void * p)
{
  free(p);
}
/* *************************************************************************
     0                   1                   2                   3   
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
EAX | Shift |                     Reserved                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
EBX |   No. Process at this level   |            Reserved           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
ECX |   Level No.   |  Level type   |            Reserved           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
EDX |                           x2APIC ID                           |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 
************************************************************************** */
 
#include <stdio.h>

/////////////////////////////////////////////////////////////////
static void _cpuid(int op1, int op2, int *data) {
    asm("cpuid"
        : "=a" (data[0]), "=b" (data[1]), "=c" (data[3]), "=d" (data[2])
        : "a"(op1), "c"(op2));
}

/////////////////////////////////////////////////////////////////
static void __cpuid(int op1, int op2, int *data) {
    asm("cpuid"
        : "=a" (data[0]), "=b" (data[1]), "=c" (data[2]), "=d" (data[3])
        : "a"(op1), "c"(op2));
}

///////////////////////////////////////////////////////////////
int main (int argc, const char * argv[]) {
    int values[5];
    int level_type = 0;
    int i = 0;

    _cpuid(0, 0, values);
    printf("Vendor: %s\n", (char*) &values[1]);

    while (1)
    {
      __cpuid(0xB, i++, values);
    
      level_type = values[2] >> 8 & 0xFF;
      if (level_type == 0)
	      break;

      printf("Shift: %d, Count: %d, Level Id: %d, Level Type: %d, x2APIC: %d, Group: %d\n",
             values[0] & 0xF,
	     values[1] & 0xFFFF,
             values[2] & 0xFF,
	     level_type,
             values[3], values[3] >> (values[0] & 0xF));
    }
}

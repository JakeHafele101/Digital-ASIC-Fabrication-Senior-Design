// Native C program to verify the math for the DSP module
#include <stdio.h>

int main() {
  
  unsigned acc = 0;
  for (int i = 0; i < 1024; i++) {
    acc += i & 0xFF;
  }
  printf("Accumulator: %d %08X\n", acc, acc);
}
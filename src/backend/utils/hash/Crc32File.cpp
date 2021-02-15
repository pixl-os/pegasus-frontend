//
// Created by thierry.imbert on 12/02/2020.
//

#include "Crc32File.h"
#include "Crc32.h"

bool Crc32File::Crc32(unsigned int& targetCrc32)
{
  targetCrc32 = 0;
  FILE* f = fopen(mPath.ToChars(), "rb");
  if (f != nullptr)
  {
    char buffer[1 << 20]; // 1Mb buffer
    for (int read = 0; (read = (int) fread(buffer, 1, sizeof(buffer), f)) > 0;)
      targetCrc32 = crc32_16bytes(buffer, read, targetCrc32);
    fclose(f);
    return true;
  }
  return false;
}

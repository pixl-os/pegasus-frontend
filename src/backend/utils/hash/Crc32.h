// //////////////////////////////////////////////////////////
// Crc32.h
// Copyright (c) 2011-2019 Stephan Brumme. All rights reserved.
// Slicing-by-16 contributed by Bulat Ziganshin
// Tableless bytewise CRC contributed by Hagai Gold
// see http://create.stephan-brumme.com/disclaimer.html
//

// if running on an embedded system, you might consider shrinking the
// big Crc32Lookup table by undefining these lines:
#define CRC32_USE_LOOKUP_TABLE_SLICING_BY_16

// uint8_t, uint32_t, int32_t
#include <cstdint>
// size_t
#include <cstddef>

/// merge two CRC32 such that result = crc32(dataB, lengthB, crc32(dataA, lengthA))
uint32_t crc32_combine (uint32_t crcA, uint32_t crcB, size_t lengthB);

#ifdef CRC32_USE_LOOKUP_TABLE_SLICING_BY_16
/// compute CRC32 (Slicing-by-16 algorithm)
uint32_t crc32_16bytes (const void* data, size_t length, uint32_t previousCrc32 = 0);
#endif

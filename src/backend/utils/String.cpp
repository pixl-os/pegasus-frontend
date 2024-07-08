//
// Created by bkg2k on 18/07/22.
//
// As part of the RECALBOX Project
// http://www.recalbox.com
//

#include "String.h"
#include "Unicode.h"

const String StringStatics::Empty;
const char StringStatics::CR = '\r';
const char StringStatics::LF = '\n';
const String StringStatics::CRLF(LEGACY_STRING("\r\n"));
const String StringStatics::sDefaultTrimmedChar(LEGACY_STRING(" \t\r\n"));

// String's unicode array static initialization
bool StringStatics::sInitialized = String::InitializeUTF8Tables();

// Member instances
StringStatics::Unicode16Array StringStatics::sSmallToCapital;
StringStatics::Unicode16Array StringStatics::sCapitalToSmall;

// Initialize both UTF8 tables
bool StringStatics::InitializeUTF8Tables()
{
  for(int i = sUnicodeArraySize; --i >= 0; )
    sSmallToCapital[i] = sCapitalToSmall[i] = (Unicode16)i;

  for(int i = (int)(sizeof(UnicodeConverterTable) / sizeof(UnicodeConverterTable[0])); --i >= 0;)
  {
    const UnicodeConverter& c = UnicodeConverterTable[i];
    sSmallToCapital[c.Small] = c.Capital;
    sCapitalToSmall[c.Capital] = c.Small;
  }
  return true;
}


#pragma once

#include <utils/locale/Internationalizer.h>

#define STRING_AND_LENGTH(s) s, sizeof(s) - 1

//! Use it with const char*
#define _(String) Internationalizer::GetText(STRING_AND_LENGTH(String))
//! Use it with std::string
#define _S(String) Internationalizer::GetText(String.c_str(), (int)String.size())

//! Use it for singular/plural form, const char*
#define _N(String1, String2, Count) Internationalizer::GetNText(Count, STRING_AND_LENGTH(String1), STRING_AND_LENGTH(String2))
//! Use it for singular/plural form, const char*
#define _SN(String1, String2, Count) Internationalizer::GetNText(Count, String1.c_str(), (int)String1.size(), String2.c_str(), (int)String2.size())

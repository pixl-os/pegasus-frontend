//
// Created by bkg2k on 14/08/2020.
//

#include "NameFiltering.h"
#include <utils/Strings.h>

std::string NameFiltering::Filter(const std::string& sourceString, Source from)
{
  std::string result = sourceString;

  // Pi3 replacement
  if (result == "bcm2835 ALSA")
  {
    if (from == Source::Card) return "";
    return "Headphones";
  }
  if (result == "bcm2835 IEC958/HDMI") return "HDMI";

  // Pi4 filtering
  Strings::ReplaceAllIn(result, "bcm2835", "");

  // Generic HDMI
  Strings::ReplaceAllIn(result, "IEC958", "Digital/HDMI");

  return Strings::Trim(result);
}

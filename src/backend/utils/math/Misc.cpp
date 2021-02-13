#include "Misc.h"

float Math::lerp(float _start, float _end, float _fraction)
{
  return (_start + ((_end - _start) * clamp(0, 1, _fraction)));
}

float Math::smoothStep(float _left, float _right, float _x)
{
  const float x = clamp(0, 1, (_x - _left)/(_right - _left));
  return x * x * (3 - (2 * x));
}

float Math::smootherStep(float _left, float _right, float _x)
{
  const float x = clamp(0, 1, (_x - _left)/(_right - _left));
  return x * x * x * (x * ((x * 6) - 15) + 10);
}

float Math::bounce(float _delayTime, float _scrollTime, float _currentTime, float _scrollLength)
{
  if(_currentTime < _delayTime)
  {
    // wait
    return 0;
  }
  else if(_currentTime < (_delayTime + _scrollTime))
  {
    // lerp from 0 to scrollLength
    const float fraction = (_currentTime - _delayTime) / _scrollTime;
    return lerp(0.0f, _scrollLength, smootherStep(0, 1, fraction));
  }
  else if(_currentTime < (_delayTime + _scrollTime + _delayTime))
  {
    // wait some more
    return _scrollLength;
  }
  else if(_currentTime < (_delayTime + _scrollTime + _delayTime + _scrollTime))
  {
    // lerp back from scrollLength to 0
    const float fraction = (_currentTime - _delayTime - _scrollTime - _delayTime) / _scrollTime;
    return lerp(_scrollLength, 0.0f, smootherStep(0, 1, fraction));
  }

  // and back to waiting
  return 0;
}

float Math::loop(float _delayTime, float _scrollTime, float _currentTime, float _scrollLength)
{
  if(_currentTime < _delayTime)
  {
    // wait
    return 0;
  }
  else if(_currentTime < (_delayTime + _scrollTime))
  {
    // lerp from 0 to scrollLength
    const float fraction = (_currentTime - _delayTime) / _scrollTime;
    return lerp(0.0f, _scrollLength, fraction);
  }

  // and back to waiting
  return 0;
}

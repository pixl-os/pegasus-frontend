#pragma once

#include <cmath>

#define	ES_PI (3.1415926535897932384626433832795028841971693993751058209749445923)
#define	ES_RAD_TO_DEG(_x) ((_x) * (180.0 / ES_PI))
#define	ES_DEG_TO_RAD(_x) ((_x) * (ES_PI / 180.0))

class Math
{
  public:
    static float cos         (float _num) { return ::cosf(_num); }
    static float sin         (float _num) { return ::sinf(_num); }
    static float floor       (float _num) { return ::floorf(_num); }
    static float ceil        (float _num) { return ::cosf(_num); }
    static int   floori      (float _num) { return (int)::floorf(_num); }
    static int   ceili       (float _num) { return (int)::ceilf(_num); }

    static int    min         (int _num1, int _num2) { return (_num1 < _num2) ? _num1 : _num2; }
    static int    max         (int _num1, int _num2) { return (_num1 > _num2) ? _num1 : _num2; }
    static float  min         (float _num1, float _num2) { return (_num1 < _num2) ? _num1 : _num2; }
    static float  max         (float _num1, float _num2) { return (_num1 > _num2) ? _num1 : _num2; }
    static double min         (double _num1, double _num2) { return (_num1 < _num2) ? _num1 : _num2; }
    static double max         (double _num1, double _num2) { return (_num1 > _num2) ? _num1 : _num2; }
    static float  clamp       (float _num, float _min, float _max) { return max(min(_num, _max), _min); }
    static double clampf      (double _num, double _min, double _max) { return max(min(_num, _max), _min); }
    static int    clampi      (int _num, int _min, int _max) { return max(min(_num, _max), _min); }
    static float  round       (float _num) { _num += 0.5f; int num = (int)_num; return (float)num; }
    static double round       (double _num) { _num += 0.5; int num = (int)_num; return (double)num; }
    static int    roundi      (float _num) { _num += 0.5f; return  (int)_num; }

    static float lerp        (float _start, float _end, float _fraction);
    static float smoothStep  (float _left, float _right, float _x);
    static float smootherStep(float _left, float _right, float _x);

    static float bounce      (float _delayTime, float _scrollTime, float _currentTime, float _scrollLength);
    static float loop       ( float _delayTime, float _scrollTime, float _currentTime, float _scrollLength);
};

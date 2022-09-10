#pragma once

#include <cassert>

class Vector2f;
class Vector4f;

class Vector3f
{
  public:

             Vector3f() = default;
    explicit Vector3f(const float _f)                                 : mX(_f),            mY(_f),                      mZ(_f)                 { }
             Vector3f(const float _x, const float _y, const float _z) : mX(_x),            mY(_y),                      mZ(_z)                 { }
    explicit Vector3f(const Vector2f& _v)                             : mX(((Vector3f&)_v).mX), mY(((Vector3f&)_v).mY), mZ(0)                  { }
    explicit Vector3f(const Vector2f& _v, const float _z)             : mX(((Vector3f&)_v).mX), mY(((Vector3f&)_v).mY), mZ(_z)                 { }
    explicit Vector3f(const Vector4f& _v)                             : mX(((Vector3f&)_v).mX), mY(((Vector3f&)_v).mY), mZ(((Vector3f&)_v).mZ) { }

    bool      operator==(const Vector3f& _other) const { return ((mX == _other.mX) && (mY == _other.mY) && (mZ == _other.mZ)); }
    bool      operator!=(const Vector3f& _other) const { return ((mX != _other.mX) || (mY != _other.mY) || (mZ != _other.mZ)); }

    Vector3f  operator+ (const Vector3f& _other) const { return { mX + _other.mX, mY + _other.mY, mZ + _other.mZ }; }
    Vector3f  operator- (const Vector3f& _other) const { return { mX - _other.mX, mY - _other.mY, mZ - _other.mZ }; }
    Vector3f  operator* (const Vector3f& _other) const { return { mX * _other.mX, mY * _other.mY, mZ * _other.mZ }; }
    Vector3f  operator/ (const Vector3f& _other) const { return { mX / _other.mX, mY / _other.mY, mZ / _other.mZ }; }

    Vector3f  operator+ (const float& _other) const    { return { mX + _other, mY + _other, mZ + _other }; }
    Vector3f  operator- (const float& _other) const    { return { mX - _other, mY - _other, mZ - _other }; }
    Vector3f  operator* (const float& _other) const    { return { mX * _other, mY * _other, mZ * _other }; }
    Vector3f  operator/ (const float& _other) const    { return { mX / _other, mY / _other, mZ / _other }; }

    Vector3f  operator- () const                       { return { -mX , -mY, -mZ }; }

    Vector3f& operator+=(const Vector3f& _other)       { *this = *this + _other; return *this; }
    Vector3f& operator-=(const Vector3f& _other)       { *this = *this - _other; return *this; }
    Vector3f& operator*=(const Vector3f& _other)       { *this = *this * _other; return *this; }
    Vector3f& operator/=(const Vector3f& _other)       { *this = *this / _other; return *this; }

    Vector3f& operator+=(const float& _other)          { *this = *this + _other; return *this; }
    Vector3f& operator-=(const float& _other)          { *this = *this - _other; return *this; }
    Vector3f& operator*=(const float& _other)          { *this = *this * _other; return *this; }
    Vector3f& operator/=(const float& _other)          { *this = *this / _other; return *this; }

    float&    operator[](const int _index)             { assert(_index < 3 && "index out of range"); return (&mX)[_index]; }
    float     operator[](const int _index) const       { assert(_index < 3 && "index out of range"); return (&mX)[_index]; }

    inline float& x()       { return mX; }
    inline float& y()       { return mY; }
    inline float& z()       { return mZ; }
    inline float  x() const { return mX; }
    inline float  y() const { return mY; }
    inline float  z() const { return mZ; }

    inline       Vector2f& v2()       { return *(Vector2f*)this; }
    inline const Vector2f& v2() const { return *(Vector2f*)this; }

    inline void Set(float x, float y, float z) { mX = x; mY =y; mZ = z; }

    Vector3f& round();
    Vector3f& lerp (const Vector3f& _start, const Vector3f& _end, float _fraction);

    static Vector3f Zero () { return { 0, 0, 0 }; }
    static Vector3f UnitX() { return { 1, 0, 0 }; }
    static Vector3f UnitY() { return { 0, 1, 0 }; }
    static Vector3f UnitZ() { return { 0, 0, 1 }; }

    bool isZero() const { return mX == 0 && mY == 0 && mZ == 0; }

    const float* data() const { return &mX; }

  private:

    float mX;
    float mY;
	  float mZ;

}; // Vector3f


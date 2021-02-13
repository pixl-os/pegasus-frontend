#pragma once
#ifndef ES_CORE_MATH_VECTOR4F_H
#define ES_CORE_MATH_VECTOR4F_H

#include <cassert>

class Vector2f;
class Vector3f;

class Vector4f
{
  public:

             Vector4f() = default;
    explicit Vector4f(const float _f)                                                 : mX(_f),                 mY(_f),                 mZ(_f),                 mW(_f) { }
             Vector4f(const float _x, const float _y, const float _z, const float _w) : mX(_x),                 mY(_y),                 mZ(_z),                 mW(_w) { }
    explicit Vector4f(const Vector2f& _v)                                             : mX(((Vector4f&)_v).mX), mY(((Vector4f&)_v).mY), mZ(0),                  mW(0)  { }
    explicit Vector4f(const Vector2f& _v, const float _z)                             : mX(((Vector4f&)_v).mX), mY(((Vector4f&)_v).mY), mZ(_z),                 mW(0)  { }
    explicit Vector4f(const Vector2f& _v, const float _z, const float _w)             : mX(((Vector4f&)_v).mX), mY(((Vector4f&)_v).mY), mZ(_z),                 mW(_w) { }
    explicit Vector4f(const Vector3f& _v)                                             : mX(((Vector4f&)_v).mX), mY(((Vector4f&)_v).mY), mZ(((Vector4f&)_v).mZ), mW(0)  { }
    explicit Vector4f(const Vector3f& _v, const float _w)                             : mX(((Vector4f&)_v).mX), mY(((Vector4f&)_v).mY), mZ(((Vector4f&)_v).mZ), mW(_w) { }

    bool      operator==(const Vector4f& _other) const { return ((mX == _other.mX) && (mY == _other.mY) && (mZ == _other.mZ) && (mW == _other.mW)); }
    bool      operator!=(const Vector4f& _other) const { return ((mX != _other.mX) || (mY != _other.mY) || (mZ != _other.mZ) || (mW != _other.mW)); }

    Vector4f  operator+ (const Vector4f& _other) const { return { mX + _other.mX, mY + _other.mY, mZ + _other.mZ, mW + _other.mW }; }
    Vector4f  operator- (const Vector4f& _other) const { return { mX - _other.mX, mY - _other.mY, mZ - _other.mZ, mW - _other.mW }; }
    Vector4f  operator* (const Vector4f& _other) const { return { mX * _other.mX, mY * _other.mY, mZ * _other.mZ, mW * _other.mW }; }
    Vector4f  operator/ (const Vector4f& _other) const { return { mX / _other.mX, mY / _other.mY, mZ / _other.mZ, mW / _other.mW }; }

    Vector4f  operator+ (const float& _other) const    { return { mX + _other, mY + _other, mZ + _other, mW + _other }; }
    Vector4f  operator- (const float& _other) const    { return { mX - _other, mY - _other, mZ - _other, mW - _other }; }
    Vector4f  operator* (const float& _other) const    { return { mX * _other, mY * _other, mZ * _other, mW * _other }; }
    Vector4f  operator/ (const float& _other) const    { return { mX / _other, mY / _other, mZ / _other, mW / _other }; }

    Vector4f  operator- () const                       { return {-mX , -mY, -mZ, -mW }; }

    Vector4f& operator+=(const Vector4f& _other)       { *this = *this + _other; return *this; }
    Vector4f& operator-=(const Vector4f& _other)       { *this = *this - _other; return *this; }
    Vector4f& operator*=(const Vector4f& _other)       { *this = *this * _other; return *this; }
    Vector4f& operator/=(const Vector4f& _other)       { *this = *this / _other; return *this; }

    Vector4f& operator+=(const float& _other)          { *this = *this + _other; return *this; }
    Vector4f& operator-=(const float& _other)          { *this = *this - _other; return *this; }
    Vector4f& operator*=(const float& _other)          { *this = *this * _other; return *this; }
    Vector4f& operator/=(const float& _other)          { *this = *this / _other; return *this; }

    float&    operator[](const int _index)             { assert(_index < 4 && "index out of range"); return (&mX)[_index]; }
    float     operator[](const int _index) const       { assert(_index < 4 && "index out of range"); return (&mX)[_index]; }

    inline float& x()       { return mX; }
    inline float& y()       { return mY; }
    inline float& z()       { return mZ; }
    inline float& w()       { return mW; }
    inline float  x() const { return mX; }
    inline float  y() const { return mY; }
    inline float  z() const { return mZ; }
    inline float  w() const { return mW; }

    inline       Vector2f& v2()       { return *(Vector2f*)this; }
    inline const Vector2f& v2() const { return *(Vector2f*)this; }

    inline       Vector3f& v3()       { return *(Vector3f*)this; }
    inline const Vector3f& v3() const { return *(Vector3f*)this; }

    inline void Set(float x, float y, float z, float w) { mX = x; mY =y; mZ = z; mW = w; }

    Vector4f& round();
    Vector4f& lerp (const Vector4f& _start, const Vector4f& _end, float _fraction);

    static Vector4f Zero () { return { 0, 0, 0, 0 }; }
    static Vector4f UnitX() { return { 1, 0, 0, 0 }; }
    static Vector4f UnitY() { return { 0, 1, 0, 0 }; }
    static Vector4f UnitZ() { return { 0, 0, 1, 0 }; }
    static Vector4f UnitW() { return { 0, 0, 0, 1 }; }

    bool isZero() const { return mX == 0 && mY == 0 && mZ == 0 && mW == 0; }

    const float* data() const { return &mX; }

  private:

    float mX;
    float mY;
    float mZ;
    float mW;

}; // Vector4f

#endif // ES_CORE_MATH_VECTOR4F_H

#pragma once

#include <cassert>

class Vector2i;

class Vector4i
{
  public:

             Vector4i() = default;
    explicit Vector4i(const int _f)                                           : mX(_f),                 mY(_f),                 mZ(_f),                 mW(_f) { }
             Vector4i(const int _x, const int _y, const int _z, const int _w) : mX(_x),                 mY(_y),                 mZ(_z),                 mW(_w) { }
    explicit Vector4i(const Vector2i& _v)                                     : mX(((Vector4i&)_v).mX), mY(((Vector4i&)_v).mY), mZ(0),                  mW(0)  { }
    explicit Vector4i(const Vector2i& _v, const int _z)                       : mX(((Vector4i&)_v).mX), mY(((Vector4i&)_v).mY), mZ(_z),                 mW(0)  { }
    explicit Vector4i(const Vector2i& _v, const int _z, const int _w)         : mX(((Vector4i&)_v).mX), mY(((Vector4i&)_v).mY), mZ(_z),                 mW(_w) { }

    bool      operator==(const Vector4i& _other) const { return ((mX == _other.mX) && (mY == _other.mY) && (mZ == _other.mZ) && (mW == _other.mW)); }
    bool      operator!=(const Vector4i& _other) const { return ((mX != _other.mX) || (mY != _other.mY) || (mZ != _other.mZ) || (mW != _other.mW)); }

    Vector4i  operator+ (const Vector4i& _other) const { return { mX + _other.mX, mY + _other.mY, mZ + _other.mZ, mW + _other.mW }; }
    Vector4i  operator- (const Vector4i& _other) const { return { mX - _other.mX, mY - _other.mY, mZ - _other.mZ, mW - _other.mW }; }
    Vector4i  operator* (const Vector4i& _other) const { return { mX * _other.mX, mY * _other.mY, mZ * _other.mZ, mW * _other.mW }; }
    Vector4i  operator/ (const Vector4i& _other) const { return { mX / _other.mX, mY / _other.mY, mZ / _other.mZ, mW / _other.mW }; }

    Vector4i  operator+ (const int& _other) const    { return { mX + _other, mY + _other, mZ + _other, mW + _other }; }
    Vector4i  operator- (const int& _other) const    { return { mX - _other, mY - _other, mZ - _other, mW - _other }; }
    Vector4i  operator* (const int& _other) const    { return { mX * _other, mY * _other, mZ * _other, mW * _other }; }
    Vector4i  operator/ (const int& _other) const    { return { mX / _other, mY / _other, mZ / _other, mW / _other }; }

    Vector4i  operator- () const                       { return {-mX , -mY, -mZ, -mW }; }

    Vector4i& operator+=(const Vector4i& _other)       { *this = *this + _other; return *this; }
    Vector4i& operator-=(const Vector4i& _other)       { *this = *this - _other; return *this; }
    Vector4i& operator*=(const Vector4i& _other)       { *this = *this * _other; return *this; }
    Vector4i& operator/=(const Vector4i& _other)       { *this = *this / _other; return *this; }

    Vector4i& operator+=(const int& _other)          { *this = *this + _other; return *this; }
    Vector4i& operator-=(const int& _other)          { *this = *this - _other; return *this; }
    Vector4i& operator*=(const int& _other)          { *this = *this * _other; return *this; }
    Vector4i& operator/=(const int& _other)          { *this = *this / _other; return *this; }

    int&      operator[](const int _index)             { assert(_index < 4 && "index out of range"); return (&mX)[_index]; }
    int       operator[](const int _index) const       { assert(_index < 4 && "index out of range"); return (&mX)[_index]; }

    inline int& x()       { return mX; }
    inline int& y()       { return mY; }
    inline int& z()       { return mZ; }
    inline int& w()       { return mW; }
    inline int  x() const { return mX; }
    inline int  y() const { return mY; }
    inline int  z() const { return mZ; }
    inline int  w() const { return mW; }

    inline       Vector2i& v2()       { return *(Vector2i*)this; }
    inline const Vector2i& v2() const { return *(Vector2i*)this; }

    inline void Set(int x, int y, int z, int w) { mX = x; mY =y; mZ = z; mW = w; }

    static Vector4i Zero () { return { 0, 0, 0, 0 }; }
    static Vector4i UnitX() { return { 1, 0, 0, 0 }; }
    static Vector4i UnitY() { return { 0, 1, 0, 0 }; }
    static Vector4i UnitZ() { return { 0, 0, 1, 0 }; }
    static Vector4i UnitW() { return { 0, 0, 0, 1 }; }

    bool isZero() const { return mX == 0 && mY == 0 && mZ == 0 && mW == 0; }

    const int* data() const { return &mX; }

  private:

    int mX;
    int mY;
    int mZ;
    int mW;

};

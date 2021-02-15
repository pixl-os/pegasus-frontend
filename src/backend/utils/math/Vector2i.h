#pragma once

#include <cassert>

class Vector2f;

class Vector2i
{
  public:

             Vector2i() = default;
    explicit Vector2i(const int _i)               : mX(_i), mY(_i) { }
             Vector2i(const int _x, const int _y) : mX(_x), mY(_y) { }

    bool      operator==(const Vector2i& _other) const { return ((mX == _other.mX) && (mY == _other.mY)); }
    bool      operator!=(const Vector2i& _other) const { return ((mX != _other.mX) || (mY != _other.mY)); }

    Vector2i  operator+ (const Vector2i& _other) const { return { mX + _other.mX, mY + _other.mY }; }
    Vector2i  operator- (const Vector2i& _other) const { return { mX - _other.mX, mY - _other.mY }; }
    Vector2i  operator* (const Vector2i& _other) const { return { mX * _other.mX, mY * _other.mY }; }
    Vector2i  operator/ (const Vector2i& _other) const { return { mX / _other.mX, mY / _other.mY }; }

    Vector2i  operator+ (const int& _other) const      { return { mX + _other, mY + _other }; }
    Vector2i  operator- (const int& _other) const      { return { mX - _other, mY - _other }; }
    Vector2i  operator* (const int& _other) const      { return { mX * _other, mY * _other }; }
    Vector2i  operator/ (const int& _other) const      { return { mX / _other, mY / _other }; }

    Vector2i  operator- () const                       { return { -mX , -mY }; }

    Vector2i& operator+=(const Vector2i& _other)       { *this = *this + _other; return *this; }
    Vector2i& operator-=(const Vector2i& _other)       { *this = *this - _other; return *this; }
    Vector2i& operator*=(const Vector2i& _other)       { *this = *this * _other; return *this; }
    Vector2i& operator/=(const Vector2i& _other)       { *this = *this / _other; return *this; }

    Vector2i& operator+=(const int& _other)            { *this = *this + _other; return *this; }
    Vector2i& operator-=(const int& _other)            { *this = *this - _other; return *this; }
    Vector2i& operator*=(const int& _other)            { *this = *this * _other; return *this; }
    Vector2i& operator/=(const int& _other)            { *this = *this / _other; return *this; }

    int&      operator[](const int _index)             { assert(_index < 2 && "index out of range"); return (&mX)[_index]; }
    int       operator[](const int _index) const       { assert(_index < 2 && "index out of range"); return (&mX)[_index]; }

    inline void Set(int x, int y) { mX = x; mY =y; }

    inline int& x()       { return mX; }
    inline int& y()       { return mY; }
    inline int  x() const { return mX; }
    inline int  y() const { return mY; }

    static Vector2i Zero () { return { 0, 0 }; }
    static Vector2i UnitX() { return { 1, 0 }; }
    static Vector2i UnitY() { return { 0, 1 }; }

    Vector2f toFloat() const;

    const int* data() const { return &mX; }

  private:

    int mX;
    int mY;

}; // Vector2i

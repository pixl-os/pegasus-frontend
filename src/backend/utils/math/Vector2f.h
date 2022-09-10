#pragma once

#include <cassert>

class Vector2i;
class Vector3f;
class Vector4f;

class Vector2f
{
public:

	         Vector2f() = default;
	explicit Vector2f(const float _f)                 : mX(_f),                 mY(_f)                 { }
	         Vector2f(const float _x, const float _y) : mX(_x),                 mY(_y)                 { }
	explicit Vector2f(const Vector3f& _v)             : mX(((Vector2f&)_v).mX), mY(((Vector2f&)_v).mY) { }
	explicit Vector2f(const Vector4f& _v)             : mX(((Vector2f&)_v).mX), mY(((Vector2f&)_v).mY) { }

	bool      operator==(const Vector2f& _other) const { return ((mX == _other.mX) && (mY == _other.mY)); }
	bool      operator!=(const Vector2f& _other) const { return ((mX != _other.mX) || (mY != _other.mY)); }

	Vector2f  operator+ (const Vector2f& _other) const { return { mX + _other.mX, mY + _other.mY }; }
	Vector2f  operator- (const Vector2f& _other) const { return { mX - _other.mX, mY - _other.mY }; }
	Vector2f  operator* (const Vector2f& _other) const { return { mX * _other.mX, mY * _other.mY }; }
	Vector2f  operator/ (const Vector2f& _other) const { return { mX / _other.mX, mY / _other.mY }; }

	Vector2f  operator+ (const float& _other) const    { return { mX + _other, mY + _other }; }
	Vector2f  operator- (const float& _other) const    { return { mX - _other, mY - _other }; }
	Vector2f  operator* (const float& _other) const    { return { mX * _other, mY * _other }; }
	Vector2f  operator/ (const float& _other) const    { return { mX / _other, mY / _other }; }

	Vector2f  operator- () const                       { return { -mX , -mY }; }

	Vector2f& operator+=(const Vector2f& _other)       { *this = *this + _other; return *this; }
	Vector2f& operator-=(const Vector2f& _other)       { *this = *this - _other; return *this; }
	Vector2f& operator*=(const Vector2f& _other)       { *this = *this * _other; return *this; }
	Vector2f& operator/=(const Vector2f& _other)       { *this = *this / _other; return *this; }

	Vector2f& operator+=(const float& _other)          { *this = *this + _other; return *this; }
	Vector2f& operator-=(const float& _other)          { *this = *this - _other; return *this; }
	Vector2f& operator*=(const float& _other)          { *this = *this * _other; return *this; }
	Vector2f& operator/=(const float& _other)          { *this = *this / _other; return *this; }

	float&    operator[](const int _index)             { assert(_index < 2 && "index out of range"); return (&mX)[_index]; }
	float     operator[](const int _index) const       { assert(_index < 2 && "index out of range"); return (&mX)[_index]; }

	inline void Set(float x, float y) { mX = x; mY =y; }

	inline float& x()       { return mX; }
	inline float& y()       { return mY; }
	inline float  x() const { return mX; }
	inline float  y() const { return mY; }

	Vector2f& round();
	Vector2f& lerp (const Vector2f& _start, const Vector2f& _end, float _fraction);

	static Vector2f Zero () { return { 0, 0 }; }
	static Vector2f UnitX() { return { 1, 0 }; }
	static Vector2f UnitY() { return { 0, 1 }; }

	bool isZero() const { return mX == 0 && mY == 0; }

	const float* data() const { return &mX; }

  Vector2i toInt() const;

  private:

	float mX;
	float mY;

};

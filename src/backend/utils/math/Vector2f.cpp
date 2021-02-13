#include "Vector2f.h"
#include "Vector2i.h"
#include "Misc.h"

Vector2i Vector2f::toInt() const
{
  return { (int)mX, (int)mY };
}

Vector2f& Vector2f::round()
{
	mX = Math::round(mX);
	mY = Math::round(mY);

	return *this;

} // round

Vector2f& Vector2f::lerp(const Vector2f& _start, const Vector2f& _end, const float _fraction)
{
	mX = Math::lerp(_start.x(), _end.x(), _fraction);
	mY = Math::lerp(_start.y(), _end.y(), _fraction);

	return *this;

} // lerp

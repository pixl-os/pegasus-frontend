//
// Created by bkg2k on 09/08/2019.
//
#pragma once

// Bitflag operator for use on strongly-typed enums - Pass enum type and underlying cardinal type
#define DEFINE_BITFLAG_ENUM(enumtype, ut) \
inline enumtype operator  |  (enumtype lhs, enumtype rhs)  { return (enumtype)((ut)lhs | (ut)rhs); } \
inline enumtype operator  &  (enumtype lhs, enumtype rhs)  { return (enumtype)((ut)lhs & (ut)rhs); } \
inline enumtype operator  ^  (enumtype lhs, enumtype rhs)  { return (enumtype)((ut)lhs ^ (ut)rhs); } \
inline enumtype operator  ~  (enumtype lhs)                { return (enumtype)(~(ut)lhs); } \
inline enumtype& operator |= (enumtype& lhs, enumtype rhs) { lhs = (enumtype)((ut)lhs | (ut)rhs); return lhs; } \
inline enumtype& operator &= (enumtype& lhs, enumtype rhs) { lhs = (enumtype)((ut)lhs & (ut)rhs); return lhs; } \
inline enumtype& operator ^= (enumtype& lhs, enumtype rhs) { lhs = (enumtype)((ut)lhs ^ (ut)rhs); return lhs; } \
inline bool operator      == (enumtype lhs, ut rhs)        { return (ut)lhs == rhs; } \
inline bool operator      != (enumtype lhs, ut rhs)        { return (ut)lhs != rhs; } \
inline bool hasFlag          (enumtype lhs, enumtype rhs)  { return ((ut)lhs & (ut)rhs) != 0; } \
inline bool hasFlags         (enumtype lhs, enumtype rhs1, enumtype rhs2) { return ((ut)lhs & ((ut)rhs1 | (ut)rhs2)) == ((ut)rhs1 | (ut)rhs2); } \
inline bool hasFlags         (enumtype lhs, enumtype rhs1, enumtype rhs2, enumtype rhs3) { return ((ut)lhs & ((ut)rhs1 | (ut)rhs2 | (ut)rhs3)) == ((ut)rhs1 | (ut)rhs2 | (ut)rhs3); }

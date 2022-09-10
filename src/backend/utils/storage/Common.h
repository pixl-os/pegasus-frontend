#pragma once

#if __cplusplus >= 201103L
  #define __cplusplus11
#endif

#ifndef __PACKED__
  #define __PACKED__ __attribute__((packed))
#endif

#define LOG_AND_EXIT(m) do{ LOG(LogError) << "[FATAL]" << m; abort(); }while(0)
#define FORCEINLINE_ATTRIBUTE __attribute((always_inline))

#define long64 long long

#define ControlItemSize(item, size)    enum { item##_size_must_be_##__COUNTER__##_bytes = 1 / (int)(!!(sizeof(item) == size)) }
#define ControlItemMaxSize(item, size) enum { item##_size_must_be_##__COUNTER__##_bytes = 1 / (int)(!!(sizeof(item) <= size)) }

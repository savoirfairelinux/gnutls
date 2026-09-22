#pragma once
#ifndef _SMP_STDALIGN_H
#define _SMP_STDALIGN_H

#if defined(_MSC_VER)
# ifndef __builtin_alignof
#  define __builtin_alignof(t) 8
# endif
# ifndef alignof
#  define alignof(t) 8
# endif
# ifndef alignas
#  define alignas(a) __declspec(align(16))
# endif
# ifndef _NETTLE_ALIGN16
#  define _NETTLE_ALIGN16 __declspec(align(16))
# endif
# ifndef _INC_STDALIGN
#  define _INC_STDALIGN
# endif
# ifndef __STDALIGN_H
#  define __STDALIGN_H
# endif
# ifndef __alignas_is_defined
#  define __alignas_is_defined 1
# endif
# ifndef __alignof_is_defined
#  define __alignof_is_defined 1
# endif
#endif

#endif /* _SMP_STDALIGN_H */

#pragma once
#ifndef _GNUTLS_MSVC_FIXES_H
#define _GNUTLS_MSVC_FIXES_H

#if defined(_MSC_VER)
# ifndef __builtin_alignof
#  define __builtin_alignof(t) 8
# endif
# ifndef _NETTLE_ALIGN16
#  define _NETTLE_ALIGN16 __declspec(align(16))
# endif
# ifndef alignof
#  define alignof(t) 8
# endif
# ifndef alignas
#  define alignas(a) __declspec(align(a))
# endif
# ifndef _INC_STDALIGN
#  define _INC_STDALIGN
# endif
# ifndef __STDALIGN_H
#  define __STDALIGN_H
# endif
#endif

#endif /* _GNUTLS_MSVC_FIXES_H */

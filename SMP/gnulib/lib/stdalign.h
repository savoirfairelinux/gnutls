#pragma once
#ifndef _SMP_STDALIGN_H
#define _SMP_STDALIGN_H

#if !defined(__cplusplus)
# ifndef alignas
#  define alignas(a) __declspec(align(a))
# endif
# ifndef alignof
#  define alignof(t) __alignof(t)
# endif
#endif

#ifndef __alignas_is_defined
# define __alignas_is_defined 1
#endif
#ifndef __alignof_is_defined
# define __alignof_is_defined 1
#endif

#endif /* _SMP_STDALIGN_H */

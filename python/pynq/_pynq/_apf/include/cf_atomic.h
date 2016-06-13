#ifndef D_cf_atomic
#define D_cf_atomic

#ifdef __cplusplus
extern "C" {
#endif

#define CF_ATOMIC_FLAG_INIT 0

typedef int cf_atomic_flag_t;
typedef int cf_atomic_int_t;

#define cf_memory_order_relaxed 0
#define cf_memory_order_consume 1
#define cf_memory_order_acquire 2
#define cf_memory_order_release 3
#define cf_memory_order_acq_rel 4
#define cf_memory_order_seq_cst 5

#if defined(__arm__)
#define cf_atomic_thread_fence(ORDER)		\
	__asm__ __volatile__("dmb":::"memory")
#else
#define cf_atomic_thread_fence(ORDER)		\
	__asm__ __volatile__("mfence":::"memory")
#endif

#define cf_atomic_flag_test_and_set(FLAG)	\
	__sync_lock_test_and_set(&(FLAG), 1)

#define cf_atomic_flag_clear(FLAG)		\
	__sync_lock_release(&(FLAG))

#define cf_atomic_fetch_add(OBJ, VAL)		\
	__sync_fetch_and_add((OBJ), (VAL))

#define cf_atomic_fetch_sub(OBJ, VAL)		\
	__sync_fetch_and_sub((OBJ), (VAL))

#define cf_atomic_load(OBJ)			\
	(__sync_synchronize(), *(OBJ))

#define cf_atomic_store(OBJ, VAL)		\
	(*(OBJ) = (VAL), __sync_synchronize())

#define cf_atomic_exchange(OBJ, DES)					\
	({								\
		typeof(OBJ) obj = (OBJ);				\
		typeof(*obj) des = (DES);				\
		typeof(*obj) expval;					\
		typeof(*obj) oldval = cf_atomic_load(obj);		\
		do {							\
			expval = oldval;				\
			oldval = __sync_val_compare_and_swap(		\
				obj, expval, des);			\
		} while (oldval != expval);				\
		oldval;							\
	})

#define cf_atomic_compare_exchange_strong(OBJ, EXP, DES)		\
	({								\
		typeof(OBJ) obj = (OBJ);				\
		typeof(EXP) exp = (EXP);				\
		typeof(*obj) expval = *exp;				\
		typeof(*obj) oldval = __sync_val_compare_and_swap(	\
			obj, expval, (DES));				\
		*exp = oldval;						\
		oldval == expval;					\
	})

#ifdef __cplusplus
}
#endif

#endif /* D_cf_atomic */

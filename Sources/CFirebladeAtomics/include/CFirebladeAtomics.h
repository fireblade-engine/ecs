#ifndef CFIREBLADE_ATOMICS_H
#define CFIREBLADE_ATOMICS_H

#include <stdatomic.h>
#include <stdint.h>

/// Acquire-loads a word. Pairs with `frb_store_release`.
static inline uintptr_t frb_load_acquire(uintptr_t *_Nonnull word) {
    return atomic_load_explicit((_Atomic(uintptr_t) *)word, memory_order_acquire);
}

/// Release-stores a word. Everything written before it is visible to a thread that acquire-loads the stored value.
static inline void frb_store_release(uintptr_t *_Nonnull word, uintptr_t value) {
    atomic_store_explicit((_Atomic(uintptr_t) *)word, value, memory_order_release);
}

#endif

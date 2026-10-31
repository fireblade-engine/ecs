#ifndef CFIREBLADE_ATOMICS_H
#define CFIREBLADE_ATOMICS_H

#include <stdint.h>

// The `__atomic_*` builtins (clang and gcc) operate on plain objects, unlike casting to `_Atomic(T) *`,
// which is undefined for objects not declared atomic. Swift can only hand us plain `UInt` memory.

/// Acquire-loads a word. Pairs with `frb_store_release`.
static inline uintptr_t frb_load_acquire(uintptr_t *_Nonnull word) {
    return __atomic_load_n(word, __ATOMIC_ACQUIRE);
}

/// Release-stores a word. Everything written before it is visible to a thread that acquire-loads the stored value.
static inline void frb_store_release(uintptr_t *_Nonnull word, uintptr_t value) {
    __atomic_store_n(word, value, __ATOMIC_RELEASE);
}

#endif

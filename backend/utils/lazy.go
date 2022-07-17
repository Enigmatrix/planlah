package utils

import (
	"sync"
	"sync/atomic"
)

type Lazy[T any] struct {
	value       T
	initialized uint32
	lock        sync.Mutex
}

func NewLazy[T any]() Lazy[T] {
	return Lazy[T]{
		initialized: 0,
		lock:        sync.Mutex{},
	}
}

func LazyOf[T any](value T) Lazy[T] {
	return Lazy[T]{
		value:       value,
		initialized: 1,
		lock:        sync.Mutex{},
	}
}

func (lazy *Lazy[T]) LazyValue(generate func() T) T {
	if atomic.LoadUint32(&lazy.initialized) == 0 {
		lazy.lock.Lock()
		defer lazy.lock.Unlock()
		defer atomic.StoreUint32(&lazy.initialized, 1)

		lazy.value = generate()
	}
	return lazy.value
}

func (lazy *Lazy[T]) LazyFallibleValue(generate func() (*T, error)) (*T, error) {
	if atomic.LoadUint32(&lazy.initialized) == 0 {
		lazy.lock.Lock()
		defer lazy.lock.Unlock()

		value, err := generate()
		if err != nil {
			return nil, err
		}
		atomic.StoreUint32(&lazy.initialized, 1)
		lazy.value = *value
	}
	return &lazy.value, nil
}

func (lazy *Lazy[T]) Reset() {
	lazy.lock.Lock()
	defer lazy.lock.Unlock()

	atomic.StoreUint32(&lazy.initialized, 0)
}

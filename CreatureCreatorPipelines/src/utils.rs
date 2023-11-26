use std::ffi::c_void;
use std::mem::forget;

pub fn with_boxed<T, F, R>(ptr: *mut c_void, f: F) -> R
where
    F: FnOnce(&Box<T>) -> R
{
    let boxed_value = unsafe {
        Box::from_raw(ptr.cast::<T>())
    };

    let ret = f(&boxed_value);

    forget(boxed_value);

    ret
}

pub fn with_boxed_mut<T, F, R>(ptr: *mut c_void, f: F) -> R
    where
        F: FnOnce(&mut Box<T>) -> R
{
    let mut boxed_value = unsafe {
        Box::from_raw(ptr.cast::<T>())
    };

    let ret = f(&mut boxed_value);

    forget(boxed_value);

    ret
}

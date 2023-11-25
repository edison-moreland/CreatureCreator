
pub struct Counter {
    v1: u64,
    v2: u64,
}

impl Default for Counter {
    fn default() -> Self {
        Self { v1: 1, v2: 2 }
    }
}

impl Counter {
    pub fn increment(&mut self) -> u64 {
        let r = self.v1;
        self.v1 = self.v2;
        self.v2 = self.v1 + r;
        r
    }
}

pub mod ffi {
    use super::Counter;
    use std::ffi;

    #[no_mangle]
    pub extern "C" fn counter_make() -> *mut ffi::c_void {
        let counter = Box::new(Counter::default());
        Box::into_raw(counter).cast()
    }

    #[no_mangle]
    pub extern "C" fn counter_next(ptr: *mut ffi::c_void) -> u64 {
        let mut counter = unsafe { Box::from_raw(ptr.cast::<Counter>()) };

        let result = counter.increment();

        std::mem::forget(counter);

        result
    }

    #[no_mangle]
    pub extern "C" fn counter_free(ptr: *mut ffi::c_void) {
        let counter = unsafe { Box::from_raw(ptr.cast::<Counter>()) };
        drop(counter)
    }
}
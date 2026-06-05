mod api;
mod frb_generated;

use std::ffi::{c_char, CString};
use std::sync::OnceLock;

#[cfg(unix)]
use std::ffi::{c_void, CStr};

#[unsafe(no_mangle)]
pub extern "C" fn usvg_dart_library_path() -> *const c_char {
    static PATH: OnceLock<CString> = OnceLock::new();
    PATH.get_or_init(library_path).as_ptr()
}

#[cfg(unix)]
fn library_path() -> CString {
    let mut info = std::mem::MaybeUninit::<libc::Dl_info>::uninit();
    let address = usvg_dart_library_path as *const () as *const c_void;
    let result = unsafe { libc::dladdr(address, info.as_mut_ptr()) };
    assert_ne!(result, 0, "dladdr failed to locate the native asset");
    let info = unsafe { info.assume_init() };
    unsafe { CStr::from_ptr(info.dli_fname) }.to_owned()
}

#[cfg(windows)]
fn library_path() -> CString {
    use windows_sys::Win32::System::LibraryLoader::{
        GetModuleFileNameW, GetModuleHandleExW, GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,
        GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
    };

    let mut module = std::ptr::null_mut();
    let address = usvg_dart_library_path as *const () as *const u16;
    let flags =
        GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT;
    let result = unsafe { GetModuleHandleExW(flags, address, &mut module) };
    assert_ne!(
        result, 0,
        "GetModuleHandleExW failed to locate the native asset"
    );

    let mut buffer = vec![0_u16; 32_768];
    let length = unsafe { GetModuleFileNameW(module, buffer.as_mut_ptr(), buffer.len() as u32) };
    assert_ne!(
        length, 0,
        "GetModuleFileNameW failed to locate the native asset"
    );
    CString::new(String::from_utf16_lossy(&buffer[..length as usize])).unwrap()
}

#[cfg(target_family = "wasm")]
fn library_path() -> CString {
    CString::default()
}

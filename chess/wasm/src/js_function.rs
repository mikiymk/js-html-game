use std::marker::PhantomData;

use wasm_bindgen::JsValue;

pub struct JsFunction<'a, T> {
    js_function: &'a js_sys::Function,
    call_type: PhantomData<T>,
}

impl<'a, T> JsFunction<'a, T>
where
    T: serde::ser::Serialize,
{
    pub fn new(js_function: &'a js_sys::Function) -> Self {
        JsFunction {
            js_function,
            call_type: PhantomData,
        }
    }

    pub fn call(&self, value: T) -> Result<JsValue, JsValue> {
        self.js_function
            .call1(&JsValue::NULL, &serde_wasm_bindgen::to_value(&value)?)
    }
}

use nalgebra::{ArrayStorage, Matrix4};

#[repr(C)]
pub struct Transform {
    matrix: [[f32; 4]; 4],
    matrix_inverse: [[f32; 4]; 4],
}

impl Transform {
    pub fn matrix(&self) -> Matrix4<f32> {
        Matrix4::from_data(ArrayStorage(self.matrix))
    }

    pub fn matrix_inverse(&self) -> Matrix4<f32> {
        Matrix4::from_data(ArrayStorage(self.matrix_inverse))
    }
}

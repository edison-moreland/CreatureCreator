use std::f32::consts::PI;
use nalgebra::{Matrix4, Rotation3, Scale3, Translation3, vector};

#[repr(C)]
pub struct Transform {
    pub position: [f32; 3],
    pub rotation: [f32; 3],
    pub scale: [f32; 3],
}

impl Transform {
    pub fn matrix(&self) -> Matrix4<f32> {
        let translation = Translation3::new(
            self.position[0], self.position[1], self.position[2]
        ).to_homogeneous();

        let rotation = Rotation3::new(
            vector![self.rotation[0], self.rotation[1], self.rotation[2]] * (PI / 180.0)
        ).to_homogeneous();

        let scale = Scale3::new(
            self.scale[0], self.scale[1], self.scale[2]
        ).to_homogeneous();

        translation * rotation * scale
    }
}

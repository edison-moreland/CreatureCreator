use nalgebra::{point, Point3, vector, Vector3};

pub trait Surface {
    // sample should return the signed distance to the surface at the given point
    // < 0 == Inside; > = == Outside;
    fn sample(&self, at: Point3<f32>) -> f32;
}

pub fn seed<S: Surface>(surface: &S) -> Point3<f32> {
    let mut seed_point = point![rand::random(), rand::random(), rand::random()];

    for _ in 0..100 {
        let grad = gradient(surface, seed_point);

        let gdg = grad.dot(&grad);
        if gdg.is_nan() {
            panic!("NANANANANANA")
        }

        seed_point -= grad.scale(surface.sample(seed_point) / gdg);

        if on_surface(surface, seed_point) {
            return seed_point;
        }
    }

    if !on_surface(surface, seed_point) {
        dbg!(seed_point);
        panic!("could not find a seed point")
    }

    seed_point
}

pub fn gradient<S: Surface>(surface: &S, p: Point3<f32>) -> Vector3<f32> {
    let h = 0.0001;

    let sp = surface.sample(p);

    let dx = (surface.sample(point![p.x + h, p.y, p.z]) - sp) / h;
    let dy = (surface.sample(point![p.x, p.y + h, p.z]) - sp) / h;
    let dz = (surface.sample(point![p.x, p.y, p.z + h]) - sp) / h;

    vector![dx, dy, dz]
}

pub fn on_surface<S: Surface>(surface: &S, point: Point3<f32>) -> bool {
    surface.sample(point).abs() <= f32::EPSILON * 2.0
}

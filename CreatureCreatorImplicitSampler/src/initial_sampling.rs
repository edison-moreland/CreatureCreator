use std::f64::consts::PI;

use nalgebra::{point, Point3, vector, Vector3};
use crate::spatial_index::kd_indexer::KdContainer;
use crate::spatial_index::SpatialIndexer;
use crate::surface::{gradient, on_surface, seed, Surface};


pub fn sample<S: Surface>(surface: &S, repulsion_radius: f32) -> Vec<Point3<f32>> {
    let seed = seed(surface);

    let initial_siblings = sibling_points(surface, seed, repulsion_radius);

    let mut samples = KdContainer::new();
    samples.append(initial_siblings.clone());

    let mut untreated = initial_siblings;

    while let Some(next_seed) = untreated.pop() {
        for point in sibling_points(surface, next_seed, repulsion_radius) {
            if samples.any_items_in_radius(point, repulsion_radius * 1.9) {
                continue;
            }

            samples.push(point);
            untreated.push(point);
        }
    }

    samples.items
}

fn plane_basis_vectors(
    origin: Point3<f32>,
    normal: Vector3<f32>
) -> (Vector3<f32>, Vector3<f32>) {
    let mut cardinal = vector![0.0, 0.0, 0.0];
    cardinal[normal.imin()] = 1.0;

    let u = normal.cross(&cardinal).normalize();
    let v = u.cross(&normal).normalize();

    (u, v)
}

fn sibling_points<S: Surface>(
    surface: &S,
    parent: Point3<f32>,
    repulsion_radius: f32,
) -> Vec<Point3<f32>> {
    let normal = gradient(surface, parent).normalize();

    let (u, v) = plane_basis_vectors(parent, normal);

    let mut siblings = Vec::new();
    siblings.reserve(6);

    for i in 0..6 {
        let ipi3 = (i as f64 * PI) / 3.0;

        let point_guess = parent +
            (u * (ipi3.cos() as f32 * (repulsion_radius * 2.0))) +
            (v * (ipi3.sin() as f32 * (repulsion_radius * 2.0)));


        siblings.push(refine_point(surface, repulsion_radius, parent, point_guess))
    }

    siblings
}

fn refine_point<S: Surface>(
    surface: &S,
    radius: f32,
    parent: Point3<f32>,
    guess: Point3<f32>,
) -> Point3<f32> {
    let mut point = guess;

    for _ in 0..10 {
        let grad = gradient(surface, point);
        point -= grad.scale(surface.sample(point) / grad.dot(&grad));

        // Push point away from parent
        // The original paper did some fancy shit to rotate about the parent
        let mut away = point - parent;
        if away.magnitude() < (radius * 2.0) {
            away = away.scale((radius * 2.0) - away.magnitude());
            point += away;
        }

        if on_surface(surface, point) {
            break;
        }
    }

    point
}

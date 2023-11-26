
// We're going to be exposed a pretty limited interface to the underlying sampler
// Much more complex surfaces can be supported

// Samples are rendered as tiny spheres with full geometry
// At higher sampling resolutions this becomes wasteful
// Maybe little discs would be better?

use std::f32::consts::PI;
use std::mem::size_of;
use std::time::Instant;

use metal::{DeviceRef, MTLPixelFormat, MTLPrimitiveType, MTLVertexFormat, MTLVertexStepFunction, NSUInteger, RenderCommandEncoderRef, RenderPipelineDescriptor, RenderPipelineState, VertexAttributeDescriptor, VertexBufferLayoutDescriptor, VertexDescriptor};
use nalgebra::{Matrix4, Point3, vector, Vector3};

use creature_creator_implicit_sampler::{ImplicitSampler, Surface};

use crate::shared::Shared;
use crate::transform::Transform;

#[repr(C)]
pub struct Ellipsoid {
    size: [f32; 3]
}

pub struct RenderSurface {
    shapes: Vec<(Matrix4<f32>, Ellipsoid)>,
}

impl RenderSurface {
    fn new() -> Self {
        Self { shapes: vec![] }
    }
    fn push(&mut self, transform: Matrix4<f32>, shape: Ellipsoid) {
        self.shapes.push((transform, shape))
    }

    fn clear(&mut self) {
        self.shapes.clear()
    }

    fn is_empty(&self) -> bool {
        self.shapes.is_empty()
    }

    fn eval_shape(&self, index: usize, at: Point3<f32>) -> f32 {
        let (t, s) = &self.shapes[index];

        let tat = t.transform_point(&at);

        Self::eval_ellipsoid(&vector![s.size[0], s.size[1], s.size[2]], &tat)
    }

    fn eval_ellipsoid(s: &Vector3<f32>, p: &Point3<f32>) -> f32 {
        (p.x.powf(2.0) / s.x.powf(2.0))
            + (p.y.powf(2.0) / s.y.powf(2.0))
            + (p.z.powf(2.0) / s.z.powf(2.0))
            - 1.0
    }

    fn smooth_min(a: f32, b: f32, k: f32) -> f32 {
        let h = (k - (a - b).abs()).max(0.0);

        a.min(b) - (h * h * 0.25 / k)
    }
}

impl Surface for RenderSurface {
    fn sample(&self, at: Point3<f32>) -> f32 {
        match self.shapes.len() {
            0 => {
                panic!("No shapes! Nothing to sample.")
            }
            1 => self.eval_shape(0, at),
            2 => Self::smooth_min(self.eval_shape(0, at), self.eval_shape(1, at), 0.5),
            _ => {
                let mut min_1 = f32::MAX;
                let mut min_2 = f32::MAX;

                for i in 0..self.shapes.len() {
                    let t = self.eval_shape(i, at);

                    if t < min_1 {
                        min_2 = min_1;
                        min_1 = t;
                    }
                }

                Self::smooth_min(min_1, min_2, 0.5)
            }
        }
    }
}


pub mod ffi {
    use std::ffi::c_void;

    use metal::{DeviceRef, MTLDevice, RenderCommandEncoderRef};
    use metal::foreign_types::ForeignTypeRef;

    use crate::surfaces::{Ellipsoid, SurfacePipeline};
    use crate::transform::Transform;
    use crate::utils::{with_boxed, with_boxed_mut};

    #[no_mangle]
    pub extern "C" fn surface_pipeline_make(device_ptr: *mut c_void) -> *mut c_void {
        let device = unsafe {
            DeviceRef::from_ptr(device_ptr.cast::<MTLDevice>())
        };

        let pipeline = Box::new(SurfacePipeline::new(device));

        Box::into_raw(pipeline).cast()
    }

    #[no_mangle]
    pub extern "C" fn surface_pipeline_free(pipeline_ptr: *mut c_void) {
        let pipeline = unsafe {
            Box::from_raw(pipeline_ptr.cast::<SurfacePipeline>())
        };

        drop(pipeline)
    }

    #[no_mangle]
    pub extern "C" fn surface_pipeline_begin(pipeline_ptr: *mut c_void) {
        with_boxed_mut::<SurfacePipeline, _, _>(pipeline_ptr, |pipeline| {
            pipeline.begin()
        })
    }

    #[no_mangle]
    pub extern "C" fn surface_pipeline_end(pipeline_ptr: *mut c_void) {
        with_boxed_mut::<SurfacePipeline, _, _>(pipeline_ptr, |pipeline| {
            pipeline.end()
        })
    }

    #[no_mangle]
    pub extern "C" fn surface_pipeline_draw_ellipsoid(pipeline_ptr: *mut c_void, transform: Transform, ellipsoid: Ellipsoid) {
        with_boxed_mut::<SurfacePipeline, _, _>(pipeline_ptr, |pipeline| {
            pipeline.draw_ellipsoid(transform, ellipsoid)
        })
    }

    #[no_mangle]
    pub extern "C" fn surface_pipeline_encode(pipeline_ptr: *mut c_void, encoder_ptr: *mut c_void) {
        let encoder = unsafe {
            RenderCommandEncoderRef::from_ptr(encoder_ptr.cast())
        };

        with_boxed::<SurfacePipeline, _, _>(pipeline_ptr, |pipeline| {
            pipeline.encode(encoder)
        })
    }
}

// \/ Implementation below \/
const SPHERE_SLICES: f32 = 16.0 / 2.0;
const SPHERE_RINGS: f32 = 16.0 / 2.0;
const INSTANCE_VERTEX_COUNT: usize = (SPHERE_RINGS as usize + 2) * SPHERE_SLICES as usize * 6;
const MAX_INSTANCE_COUNT: usize = 100000;

const SHADER_LIBRARY: &[u8] = include_bytes!("surfaces.metallib");

const PIPELINE_DEPTH_FORMAT: MTLPixelFormat = MTLPixelFormat::Depth32Float;
const PIPELINE_PIXEL_FORMAT: MTLPixelFormat = MTLPixelFormat::RGBA8Unorm;

// buffer 0 is the uniform buffer
const PIPELINE_VERTEX_BUFFER: NSUInteger = 1;
const PIPELINE_INSTANCE_BUFFER: NSUInteger = 2;

#[repr(C)]
struct Instance {
    center: [f32; 3],
    normal: [f32; 3],
    radius: f32
}

type Vertex = [f32; 3];

type VertexBuffer = Shared<[Vertex; INSTANCE_VERTEX_COUNT]>;
type InstanceBuffer = Shared<[Instance; MAX_INSTANCE_COUNT]>;

struct SurfacePipeline {
    pipeline: RenderPipelineState,

    vertices: VertexBuffer,

    instances: InstanceBuffer,
    instance_count: usize,

    surface: RenderSurface,
    sampler: ImplicitSampler<MAX_INSTANCE_COUNT>,
    sample_resolution: f32
}

impl SurfacePipeline {
    fn attribute(buffer: NSUInteger, offset: NSUInteger, format: MTLVertexFormat) -> VertexAttributeDescriptor {
        let vad = VertexAttributeDescriptor::new();
        vad.set_buffer_index(buffer);
        vad.set_offset(offset);
        vad.set_format(format);

        vad
    }

    fn new_pipeline(device: &DeviceRef) -> RenderPipelineState {
        let library = device
            .new_library_with_data(SHADER_LIBRARY)
            .expect("shader should load without error");
        let vertex_function = library
            .get_function("vertex_main", None)
            .expect("function `vertex_main` to exist");
        let frag_function = library
            .get_function("fragment_main", None)
            .expect("function `fragment_main` to exist");

        let pipeline_descriptor = RenderPipelineDescriptor::new();
        pipeline_descriptor.set_vertex_function(Some(&vertex_function));
        pipeline_descriptor.set_fragment_function(Some(&frag_function));
        pipeline_descriptor.set_depth_attachment_pixel_format(PIPELINE_DEPTH_FORMAT);
        pipeline_descriptor
            .color_attachments()
            .object_at(0)
            .unwrap()
            .set_pixel_format(PIPELINE_PIXEL_FORMAT);

        let vertex_descriptor = VertexDescriptor::new();
        let attributes = vertex_descriptor.attributes();

        // Vertex attributes
        let vertex_offset: NSUInteger = 0;
        let mut instance_offset: NSUInteger = 0;
        let mut attribute_i: NSUInteger = 0;

        // position
        attributes.set_object_at(attribute_i, Some(&SurfacePipeline::attribute(
            PIPELINE_VERTEX_BUFFER, vertex_offset, MTLVertexFormat::Float3,
        )));
        // vertex_offset += size_of::<[f32; 3]>() as NSUInteger;
        attribute_i += 1;

        // center
        attributes.set_object_at(attribute_i, Some(&SurfacePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, instance_offset, MTLVertexFormat::Float3,
        )));
        instance_offset += size_of::<[f32; 3]>() as NSUInteger;
        attribute_i += 1;

        // color
        attributes.set_object_at(attribute_i, Some(&SurfacePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, instance_offset, MTLVertexFormat::Float3,
        )));
        instance_offset += size_of::<[f32; 3]>() as NSUInteger;
        attribute_i += 1;

        // radius
        attributes.set_object_at(attribute_i, Some(&SurfacePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, instance_offset, MTLVertexFormat::Float,
        )));
        // instance_offset += size_of::<[f32; 1]>() as NSUInteger;
        // attribute_i += 1;

        // Buffer layouts
        let vertex_buffer = VertexBufferLayoutDescriptor::new();
        vertex_buffer.set_stride(size_of::<Vertex>() as NSUInteger);
        vertex_buffer.set_step_function(MTLVertexStepFunction::PerVertex);
        vertex_buffer.set_step_rate(1);
        vertex_descriptor
            .layouts()
            .set_object_at(PIPELINE_VERTEX_BUFFER, Some(&vertex_buffer));

        let instance_buffer = VertexBufferLayoutDescriptor::new();
        instance_buffer.set_stride((size_of::<Instance>()) as NSUInteger);
        instance_buffer.set_step_function(MTLVertexStepFunction::PerInstance);
        instance_buffer.set_step_rate(1);
        vertex_descriptor
            .layouts()
            .set_object_at(PIPELINE_INSTANCE_BUFFER, Some(&instance_buffer));

        pipeline_descriptor.set_vertex_descriptor(Some(vertex_descriptor));

        device
            .new_render_pipeline_state(pipeline_descriptor.as_ref())
            .unwrap()
    }

    fn new_instance_buffer(device: &DeviceRef) -> InstanceBuffer {
        Shared::new_zeroed(device)
    }

    fn instance_vertices(rings: f32, slices: f32) -> [Vertex; INSTANCE_VERTEX_COUNT] {
        // This method of sphere vert generation was yoinked from raylib <3
        let mut data = [[0.0, 0.0, 0.0]; INSTANCE_VERTEX_COUNT];

        let deg2rad = PI / 180.0;

        for i in 0..(rings as i32 + 2) {
            for j in 0..slices as i32 {
                let fi = i as f32;
                let fj = j as f32;

                let vertex = |i: f32, j: f32| [
                    (deg2rad * (270.0 + (180.0 / (rings + 1.0)) * i)).cos()
                        * (deg2rad * (360.0 * j / slices)).sin(),
                    (deg2rad * (270.0 + (180.0 / (rings + 1.0)) * i)).sin(),
                    (deg2rad * (270.0 + (180.0 / (rings + 1.0)) * i)).cos()
                        * (deg2rad * (360.0 * j / slices)).cos(),
                ];

                let idx = ((slices as i32 * 6 * i) + (j * 6)) as usize;

                data[idx] = vertex(fi, fj);
                data[idx + 1] = vertex(fi + 1.0, fj + 1.0);
                data[idx + 2] = vertex(fi + 1.0, fj);
                data[idx + 3] = vertex(fi, fj);
                data[idx + 4] = vertex(fi, fj + 1.0);
                data[idx + 5] = vertex(fi + 1.0, fj + 1.0);
            }
        }

        data
    }

    fn new_vertices_buffer(device: &DeviceRef) -> VertexBuffer {
        // TODO: Static buffers like this shouldn't be using `Shared`
        Shared::new(device, Self::instance_vertices(SPHERE_RINGS, SPHERE_SLICES))
    }

    pub fn new(device: &DeviceRef) -> Self {
        Self {
            pipeline: Self::new_pipeline(device),
            vertices: Self::new_vertices_buffer(device),
            instances: Self::new_instance_buffer(device),
            instance_count: 0,

            surface: RenderSurface::new(),
            sampler: ImplicitSampler::new(),
            sample_resolution: 0.3,
        }
    }

    pub fn begin(&mut self) {
    //     Prepare for surface to be refreshed
        self.surface.clear();
        self.instance_count = 0
    }

    fn update_surface_samples(&mut self) {
        self.sampler.update(self.sample_resolution, &self.surface);

        let mut max_i = 0;
        for (i, (position, normal, radius)) in self.sampler.samples().enumerate() {
            self.instances[i] = Instance {
                center: position.coords.data.0[0],
                normal: normal.data.0[0],
                radius,
            };

            max_i = i
        }

        self.instance_count = max_i + 1;
        self.surface.clear();
    }

    pub fn end(&mut self) {
        assert!(!self.surface.is_empty(), "Nothing was drawn!");

        let start = Instant::now();
        self.update_surface_samples();
        let sampling_elapsed= start.elapsed();
        dbg!(sampling_elapsed);
    }

    pub fn draw_ellipsoid(&mut self, transform: Transform, ellipsoid: Ellipsoid) {
        self.surface.push(transform.matrix(), ellipsoid)
    }

    pub fn encode(&self, encoder: &RenderCommandEncoderRef) {
        if self.instance_count != 0 {
            encoder.set_render_pipeline_state(&self.pipeline);
            encoder.set_vertex_buffer(PIPELINE_VERTEX_BUFFER, Some(self.vertices.buffer()), 0);
            encoder.set_vertex_buffer(PIPELINE_INSTANCE_BUFFER, Some(self.instances.buffer()), 0);

            encoder.draw_primitives_instanced(
                MTLPrimitiveType::Triangle,
                0,
                INSTANCE_VERTEX_COUNT as NSUInteger,
                self.instance_count as NSUInteger,
            )
        }
    }
}
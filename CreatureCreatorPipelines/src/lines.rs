use std::mem::size_of;

use metal::{DeviceRef, MTLPixelFormat, MTLPrimitiveType, MTLVertexFormat, MTLVertexStepFunction, NSUInteger, RenderCommandEncoderRef, RenderPipelineDescriptor, RenderPipelineState, VertexAttributeDescriptor, VertexBufferLayoutDescriptor, VertexDescriptor};
use nalgebra::{point, Point3, vector};
use crate::plane::Plane;

use crate::shared::Shared;
use crate::transform::Transform;

//  Once we're comfortable with the c ffi code, we should switch to something like:
// https://github.com/mozilla/cbindgen

// Line pipeline interface
#[repr(u8)]
pub enum Style {
    None,
    Arrow,
    Circle,
}

#[repr(C)]
pub struct Line {
    style: Style,
    color: [f32; 3],
    size: f32,
    // length for None/Arrow, radius*2 for Circle
    thickness: f32,
    dash_size: f32, // 0 = no dashes
}

pub mod ffi {
    use std::ffi::c_void;
    use std::mem::forget;

    use metal::{DeviceRef, MTLDevice, RenderCommandEncoderRef};
    use metal::foreign_types::ForeignTypeRef;

    use crate::transform::Transform;

    use super::{Line, LinePipeline};

    #[no_mangle]
    pub extern "C" fn line_pipeline_make(device_ptr: *mut c_void) -> *mut c_void {
        let device = unsafe {
            DeviceRef::from_ptr(device_ptr.cast::<MTLDevice>())
        };

        let pipeline = Box::new(LinePipeline::new(device));

        Box::into_raw(pipeline).cast()
    }

    #[no_mangle]
    pub extern "C" fn line_pipeline_free(pipeline_ptr: *mut c_void) {
        let pipeline = unsafe {
            Box::from_raw(pipeline_ptr.cast::<LinePipeline>())
        };

        drop(pipeline)
    }

    #[no_mangle]
    pub extern "C" fn line_pipeline_draw(pipeline_ptr: *mut c_void, transform: Transform, line: Line) {
        let mut pipeline = unsafe {
            Box::from_raw(pipeline_ptr.cast::<LinePipeline>())
        };

        pipeline.draw(transform, line);

        forget(pipeline)
    }

    #[no_mangle]
    pub extern "C" fn line_pipeline_commit(pipeline_ptr: *mut c_void, encoder_ptr: *mut c_void) {
        let mut pipeline = unsafe {
            Box::from_raw(pipeline_ptr.cast::<LinePipeline>())
        };

        let encoder = unsafe {
            RenderCommandEncoderRef::from_ptr(encoder_ptr.cast())
        };

        pipeline.commit(encoder);

        forget(pipeline)
    }
}

// \/ Implementation below \/

// LineInstance is what is given to the shader
// A single line may be split into multiple instances

const INSTANCE_VERTEX_COUNT: usize = 4;
const INSTANCE_SHAPE_COUNT: usize = 2;
const MAX_INSTANCE_COUNT: usize = 1000;
const SHADER_LIBRARY: &[u8] = include_bytes!("lines.metallib");

const PIPELINE_DEPTH_FORMAT: MTLPixelFormat = MTLPixelFormat::Depth32Float;
const PIPELINE_PIXEL_FORMAT: MTLPixelFormat = MTLPixelFormat::RGBA8Unorm;

// buffer 0 is the uniform buffer
const PIPELINE_VERTEX_BUFFER: NSUInteger = 1;
const PIPELINE_INSTANCE_BUFFER: NSUInteger = 2;

#[repr(C)]
struct LineInstance {
    a: [f32; 3],
    b: [f32; 3],
    color: [f32; 3],
    thickness: f32,
    shape: u32,
    // 0 = rectangle, 1 = triangle
    dash_size: f32,
    // 0 = no dashes
    dash_offset: f32,
}

impl LineInstance {
    fn new(a: Point3<f32>, b: Point3<f32>, color: [f32; 3], thickness: f32, shape: u32, dash_size: f32, dash_offset: f32) -> LineInstance {
        LineInstance {
            a: a.coords.data.0[0],
            b: b.coords.data.0[0],
            color,
            thickness,
            shape,
            dash_size,
            dash_offset,
        }
    }
}

type VertexBuffer = Shared<[[f32; 2]; INSTANCE_VERTEX_COUNT * INSTANCE_SHAPE_COUNT]>;
type InstanceBuffer = Shared<[LineInstance; MAX_INSTANCE_COUNT]>;

struct LinePipeline {
    pipeline: RenderPipelineState,

    vertices: VertexBuffer,

    instances: InstanceBuffer,
    instance_count: usize,
}

impl LinePipeline {
    fn attribute(buffer: NSUInteger, offset: NSUInteger, format: MTLVertexFormat) -> VertexAttributeDescriptor {
        let vad = VertexAttributeDescriptor::new();
        vad.set_buffer_index(buffer);
        vad.set_offset(offset);
        vad.set_format(format);

        vad
    }
    fn new_pipeline(device: &DeviceRef) -> RenderPipelineState {
        let library = device.new_library_with_data(SHADER_LIBRARY).expect("sphere should load without error");
        let vertex_function = library.get_function("vertex_main", None).expect("function `vertex_main` to exist");
        let frag_function = library.get_function("fragment_main", None).expect("function `fragment_main` to exist");

        let pipeline_descriptor = RenderPipelineDescriptor::new();
        pipeline_descriptor.set_vertex_function(Some(&vertex_function));
        pipeline_descriptor.set_fragment_function(Some(&frag_function));
        pipeline_descriptor.set_depth_attachment_pixel_format(PIPELINE_DEPTH_FORMAT);

        let attachment = pipeline_descriptor.color_attachments().object_at(0).unwrap();

        attachment.set_pixel_format(PIPELINE_PIXEL_FORMAT);
        attachment.set_blending_enabled(true);
        attachment.set_rgb_blend_operation(metal::MTLBlendOperation::Add);
        attachment.set_alpha_blend_operation(metal::MTLBlendOperation::Add);
        attachment.set_source_rgb_blend_factor(metal::MTLBlendFactor::SourceAlpha);
        attachment.set_source_alpha_blend_factor(metal::MTLBlendFactor::SourceAlpha);
        attachment.set_destination_rgb_blend_factor(metal::MTLBlendFactor::OneMinusSourceAlpha);
        attachment.set_destination_alpha_blend_factor(metal::MTLBlendFactor::OneMinusSourceAlpha);

        let vertex_descriptor = VertexDescriptor::new();
        let attributes = vertex_descriptor.attributes();

        // Vertex attributes
        let mut offset: NSUInteger = 0;
        let mut attribute_i: NSUInteger = 0;

        // a
        attributes.set_object_at(attribute_i, Some(&LinePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, offset, MTLVertexFormat::Float3,
        )));
        offset += size_of::<[f32; 3]>() as NSUInteger;
        attribute_i += 1;

        // b
        attributes.set_object_at(attribute_i, Some(&LinePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, offset, MTLVertexFormat::Float3,
        )));
        offset += size_of::<[f32; 3]>() as NSUInteger;
        attribute_i += 1;

        // color
        attributes.set_object_at(attribute_i, Some(&LinePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, offset, MTLVertexFormat::Float3,
        )));
        offset += size_of::<[f32; 3]>() as NSUInteger;
        attribute_i += 1;

        // thickness
        attributes.set_object_at(attribute_i, Some(&LinePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, offset, MTLVertexFormat::Float,
        )));
        offset += size_of::<[f32; 1]>() as NSUInteger;
        attribute_i += 1;

        // shape
        attributes.set_object_at(attribute_i, Some(&LinePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, offset, MTLVertexFormat::UInt,
        )));
        offset += size_of::<[u32; 1]>() as NSUInteger;
        attribute_i += 1;

        // dash_size
        attributes.set_object_at(attribute_i, Some(&LinePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, offset, MTLVertexFormat::Float,
        )));
        offset += size_of::<[f32; 1]>() as NSUInteger;
        attribute_i += 1;

        // dash_offset
        attributes.set_object_at(attribute_i, Some(&LinePipeline::attribute(
            PIPELINE_INSTANCE_BUFFER, offset, MTLVertexFormat::Float,
        )));
        // offset += size_of::<[f32; 1]>() as NSUInteger;
        // attribute_i += 1;

        // Buffer layouts
        let instance_buffer_desc = VertexBufferLayoutDescriptor::new();
        instance_buffer_desc.set_stride(size_of::<LineInstance>() as NSUInteger);
        instance_buffer_desc.set_step_function(MTLVertexStepFunction::PerInstance);
        instance_buffer_desc.set_step_rate(1);
        vertex_descriptor.layouts().set_object_at(PIPELINE_INSTANCE_BUFFER, Some(&instance_buffer_desc));

        pipeline_descriptor.set_vertex_descriptor(Some(vertex_descriptor));

        device.new_render_pipeline_state(pipeline_descriptor.as_ref()).unwrap()
    }

    fn new_vertex_buffer(device: &DeviceRef) -> VertexBuffer {
        Shared::new(device, [
            // Regular line style
            [-1.0, -1.0],
            [-1.0, 1.0],
            [1.0, -1.0],
            [1.0, 1.0],
            // Arrow style
            [1.0, -1.0],
            [1.0, 0.0],
            [-1.0, 0.0],
            [1.0, 1.0],
        ])
    }

    fn new_instance_buffer(device: &DeviceRef) -> InstanceBuffer {
        Shared::new_zeroed(device)
    }

    pub fn new(device: &DeviceRef) -> Self {
        LinePipeline {
            pipeline: LinePipeline::new_pipeline(device),
            vertices: LinePipeline::new_vertex_buffer(device),
            instances: LinePipeline::new_instance_buffer(device),
            instance_count: 0,
        }
    }

    fn push_instance(&mut self, instance: LineInstance) {
        assert_ne!(self.instance_count + 1, MAX_INSTANCE_COUNT);

        self.instances[self.instance_count] = instance;
        self.instance_count += 1
    }

    pub fn draw(&mut self, transform: Transform, line: Line) {
        let matrix = transform.matrix();

        match line.style {
            Style::None => {
                let a = matrix.transform_point(&point![0.0, line.size / 2.0, 0.0]);
                let b = matrix.transform_point(&point![0.0, -(line.size / 2.0), 0.0]);

                self.push_instance(LineInstance::new(
                    a, b,
                    line.color,
                    line.thickness,
                    0,
                    line.dash_size,
                    0.0,
                ))
            }
            Style::Arrow => {
                let direction = matrix.transform_vector(&vector![0.0, 1.0, 0.0]).normalize();
                let origin = matrix.transform_point(&point![0.0, 0.0, 0.0]);

                let start = origin;
                let end = start + (direction * line.size);

                let stem_thickness = line.thickness;
                let arrow_thickness = stem_thickness * 4.0;
                let arrow_head_length = arrow_thickness * 1.5;

                if line.size <= arrow_head_length {
                    // Line is shorter than we want the head to be, so don't add a stem
                    self.push_instance(LineInstance::new(
                        start, end,
                        line.color,
                        arrow_thickness,
                        1,
                        0.0,
                        0.0,
                    ));
                } else {
                    let stem_length = line.size - arrow_head_length;
                    let stem_end = start + (direction * stem_length);

                    self.push_instance(LineInstance::new(
                        start, stem_end,
                        line.color,
                        stem_thickness,
                        0,
                        line.dash_size,
                        0.0,
                    ));
                    self.push_instance(LineInstance::new(
                        stem_end, end,
                        line.color,
                        arrow_thickness,
                        1,
                        0.0,
                        0.0
                    ));
                }
            }
            Style::Circle => {
                let segment_count = 24 * 2; // TODO: Scale segment_count based on final radius/dash size
                let points = Plane::from_origin_normal(point![0.0, 0.0, 0.0], vector![0.0, 1.0, 0.0])
                    .circle_points(segment_count, line.size / 2.0);

                let mut dash_offset = 0.0;
                for i in 0..segment_count {
                    let last_i = if i == 0 { segment_count - 1 } else { i - 1 };

                    let a = matrix.transform_point(&points[i]);
                    let b = matrix.transform_point(&points[last_i]);

                    self.push_instance(LineInstance::new(
                        a,
                        b,
                        line.color,
                        line.thickness,
                        0,
                        line.dash_size,
                        dash_offset,
                    ));

                    dash_offset += (a - b).magnitude();
                }
            }
        }
    }

    pub fn commit(&mut self, encoder: &RenderCommandEncoderRef) {
        encoder.set_render_pipeline_state(&self.pipeline);
        encoder.set_vertex_buffer(PIPELINE_VERTEX_BUFFER, Some(self.vertices.buffer()), 0);
        encoder.set_vertex_buffer(PIPELINE_INSTANCE_BUFFER, Some(self.instances.buffer()), 0);

        encoder.draw_primitives_instanced(
            MTLPrimitiveType::TriangleStrip,
            0,
            INSTANCE_VERTEX_COUNT as NSUInteger,
            self.instance_count as NSUInteger,
        );
        self.instance_count = 0;
    }
}
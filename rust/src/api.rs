use std::path::PathBuf;

use flutter_rust_bridge::frb;

#[derive(Clone, Debug)]
/// Options controlling how usvg parses and resolves an SVG document.
pub struct ParseOptions {
    /// Directory used to resolve relative resource paths.
    pub resources_dir: Option<String>,
    /// Resolution used to convert physical units into pixels.
    pub dpi: f32,
    /// Default font family used when an SVG does not specify one.
    pub font_family: String,
    /// Default font size used when an SVG does not specify one.
    pub font_size: f32,
    /// Preferred languages used to resolve conditional SVG content.
    pub languages: Vec<String>,
    /// Additional CSS applied while parsing the SVG.
    pub style_sheet: Option<String>,
}

impl Default for ParseOptions {
    fn default() -> Self {
        Self {
            resources_dir: None,
            dpi: 96.0,
            font_family: "Times New Roman".to_owned(),
            font_size: 12.0,
            languages: vec!["en".to_owned()],
            style_sheet: None,
        }
    }
}

#[derive(Clone, Copy, Debug)]
/// The intrinsic dimensions of a parsed SVG tree.
pub struct SvgSize {
    /// Width in SVG user units.
    pub width: f32,
    /// Height in SVG user units.
    pub height: f32,
}

#[frb(opaque)]
/// A parsed and normalized SVG document.
pub struct SvgTree {
    tree: usvg::Tree,
}

impl SvgTree {
    /// Parses SVG text into a normalized tree.
    pub fn parse(svg: String, options: Option<ParseOptions>) -> Result<Self, String> {
        Self::parse_bytes(svg.into_bytes(), options)
    }

    /// Parses SVG bytes into a normalized tree.
    pub fn parse_bytes(data: Vec<u8>, options: Option<ParseOptions>) -> Result<Self, String> {
        let options = to_usvg_options(options.unwrap_or_default());
        usvg::Tree::from_data(&data, &options)
            .map(|tree| Self { tree })
            .map_err(|error| error.to_string())
    }

    #[frb(sync, getter)]
    /// Returns the intrinsic size of the root SVG.
    pub fn size(&self) -> SvgSize {
        let size = self.tree.size();
        SvgSize {
            width: size.width(),
            height: size.height(),
        }
    }

    #[frb(sync, getter)]
    /// Returns whether the normalized tree contains no renderable nodes.
    pub fn is_empty(&self) -> bool {
        !self.tree.root().has_children()
    }

    /// Serializes the normalized tree as SVG text.
    pub fn to_svg_string(&self) -> String {
        self.tree.to_string(&usvg::WriteOptions::default())
    }
}

fn to_usvg_options(options: ParseOptions) -> usvg::Options<'static> {
    let mut result = usvg::Options::default();
    result.resources_dir = options.resources_dir.map(PathBuf::from);
    result.dpi = options.dpi;
    result.font_family = options.font_family;
    result.font_size = options.font_size;
    result.languages = options.languages;
    result.style_sheet = options.style_sheet;
    result
}

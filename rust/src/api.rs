use std::path::PathBuf;

use flutter_rust_bridge::frb;

#[derive(Clone, Debug)]
pub struct ParseOptions {
    pub resources_dir: Option<String>,
    pub dpi: f32,
    pub font_family: String,
    pub font_size: f32,
    pub languages: Vec<String>,
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
pub struct SvgSize {
    pub width: f32,
    pub height: f32,
}

#[frb(opaque)]
pub struct SvgTree {
    tree: usvg::Tree,
}

impl SvgTree {
    pub fn parse(svg: String, options: Option<ParseOptions>) -> Result<Self, String> {
        Self::parse_bytes(svg.into_bytes(), options)
    }

    pub fn parse_bytes(data: Vec<u8>, options: Option<ParseOptions>) -> Result<Self, String> {
        let options = to_usvg_options(options.unwrap_or_default());
        usvg::Tree::from_data(&data, &options)
            .map(|tree| Self { tree })
            .map_err(|error| error.to_string())
    }

    #[frb(sync, getter)]
    pub fn size(&self) -> SvgSize {
        let size = self.tree.size();
        SvgSize {
            width: size.width(),
            height: size.height(),
        }
    }

    #[frb(sync, getter)]
    pub fn is_empty(&self) -> bool {
        !self.tree.root().has_children()
    }

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

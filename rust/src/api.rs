use std::collections::HashSet;
use std::path::PathBuf;
use std::sync::{Arc, Mutex, OnceLock};

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
    /// Whether to load fonts installed on the host operating system.
    pub load_system_fonts: bool,
    /// Font files to load into usvg's in-memory font database.
    pub font_data: Vec<Vec<u8>>,
}

impl Default for ParseOptions {
    #[frb(sync)]
    fn default() -> Self {
        Self {
            resources_dir: None,
            dpi: 96.0,
            font_family: "Times New Roman".to_owned(),
            font_size: 12.0,
            languages: vec!["en".to_owned()],
            style_sheet: None,
            load_system_fonts: false,
            font_data: Vec::new(),
        }
    }
}

// TODO: [usvg::Options](https://docs.rs/usvg/latest/usvg/struct.Options.html)
// usvg::Options is not Send + Sync, so we can't expose it directly. We
// could consider implementing Send + Sync manually if we can guarantee that the
// font database is only mutated during parsing, but that would require more
// careful synchronization and testing. For now, we can expose the most commonly
// used options through our own ParseOptions struct and convert it to
// usvg::Options internally. We can always add more options later if needed.
// TODO: [usvg::WriteOptions](https://docs.rs/usvg/latest/usvg/struct.WriteOptions.html)
// TODO: [usvg::FontResolver](https://docs.rs/usvg/latest/usvg/struct.FontResolver.html)

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

#[derive(Debug)]
struct FontDatabaseState {
    database: usvg::fontdb::Database,
    keys: HashSet<String>,
}

#[frb(opaque)]
/// A persistent font database that can be shared across SVG parses.
/// [usvg::fontdb](https://docs.rs/usvg/latest/usvg/index.html#reexport.fontdb)
pub struct UsvgFontDatabase {
    state: Mutex<FontDatabaseState>,
}

impl UsvgFontDatabase {
    #[frb(sync)]
    /// Creates an empty database, optionally initialized with system fonts.
    pub fn new(load_system_fonts: bool) -> Self {
        let mut database = usvg::fontdb::Database::new();
        if load_system_fonts {
            database.load_system_fonts();
        }
        Self {
            state: Mutex::new(FontDatabaseState {
                database,
                keys: HashSet::new(),
            }),
        }
    }

    #[frb(sync)]
    /// Registers font bytes once for the supplied stable key.
    ///
    /// Returns the number of newly loaded font faces. Invalid font data
    /// returns zero and is not remembered, so callers may retry the key.
    pub fn register_font_data(&self, key: String, data: Vec<u8>) -> Result<u32, String> {
        let mut state = self.state.lock().map_err(|error| error.to_string())?;
        if state.keys.contains(&key) {
            return Ok(0);
        }

        let previous_count = state.database.len();
        state.database.load_font_data(data);
        let loaded_count = state.database.len() - previous_count;
        if loaded_count > 0 {
            state.keys.insert(key);
        }
        Ok(loaded_count as u32)
    }

    #[frb(sync, getter)]
    /// Returns the number of font faces currently available.
    pub fn face_count(&self) -> Result<u32, String> {
        self.state
            .lock()
            .map(|state| state.database.len() as u32)
            .map_err(|error| error.to_string())
    }

    #[frb(sync)]
    /// Returns unique characters not covered by any registered font face.
    pub fn missing_characters(&self, text: String) -> Result<String, String> {
        let state = self.state.lock().map_err(|error| error.to_string())?;
        Ok(missing_characters(&state.database, text, None))
    }

    #[frb(sync)]
    /// Returns unique characters not covered by any face in the named family.
    pub fn missing_characters_for_family(
        &self,
        family: String,
        text: String,
    ) -> Result<String, String> {
        let state = self.state.lock().map_err(|error| error.to_string())?;
        Ok(missing_characters(&state.database, text, Some(&family)))
    }

    #[frb(sync)]
    /// Returns whether at least one registered face belongs to the named family.
    pub fn has_family(&self, family: String) -> Result<bool, String> {
        let state = self.state.lock().map_err(|error| error.to_string())?;
        let found = state.database.faces().any(|face| {
            face.families
                .iter()
                .any(|candidate| candidate.0.eq_ignore_ascii_case(&family))
        });
        Ok(found)
    }

    #[frb(sync)]
    /// Returns the first registered family whose faces cover all characters.
    pub fn family_for_text(&self, text: String) -> Result<Option<String>, String> {
        let state = self.state.lock().map_err(|error| error.to_string())?;
        let mut seen = HashSet::new();
        for face in state.database.faces() {
            for family in &face.families {
                if seen.insert(family.0.clone())
                    && missing_characters(&state.database, text.clone(), Some(&family.0)).is_empty()
                {
                    return Ok(Some(family.0.clone()));
                }
            }
        }
        Ok(None)
    }

    #[frb(sync)]
    /// Parses SVG text using a snapshot of this database.
    pub fn parse(&self, svg: String, options: Option<ParseOptions>) -> Result<SvgTree, String> {
        self.parse_bytes(svg.into_bytes(), options)
    }

    #[frb(sync)]
    /// Parses SVG bytes using a snapshot of this database.
    pub fn parse_bytes(
        &self,
        data: Vec<u8>,
        options: Option<ParseOptions>,
    ) -> Result<SvgTree, String> {
        let database = self
            .state
            .lock()
            .map(|state| state.database.clone())
            .map_err(|error| error.to_string())?;
        parse_tree(data, options, Some(database))
    }
}

fn missing_characters(
    database: &usvg::fontdb::Database,
    text: String,
    family: Option<&str>,
) -> String {
    let face_ids: Vec<_> = database
        .faces()
        .filter(|face| {
            family.is_none_or(|name| {
                face.families
                    .iter()
                    .any(|candidate| candidate.0.eq_ignore_ascii_case(name))
            })
        })
        .map(|face| face.id)
        .collect();
    let mut seen = HashSet::new();

    text.chars()
        .filter(|character| seen.insert(*character))
        .filter(|character| {
            !face_ids.iter().any(|id| {
                database
                    .with_face_data(*id, |data, index| {
                        ttf_parser::Face::parse(data, index)
                            .ok()
                            .is_some_and(|face| face.glyph_index(*character).is_some())
                    })
                    .unwrap_or(false)
            })
        })
        .collect()
}

impl SvgTree {
    #[frb(sync)]
    /// Parses SVG text into a normalized tree.
    pub fn parse(svg: String, options: Option<ParseOptions>) -> Result<Self, String> {
        Self::parse_bytes(svg.into_bytes(), options)
    }

    #[frb(sync)]
    /// Parses SVG bytes into a normalized tree.
    pub fn parse_bytes(data: Vec<u8>, options: Option<ParseOptions>) -> Result<Self, String> {
        parse_tree(data, options, None)
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

    #[frb(sync)]
    /// Serializes the normalized tree as SVG text.
    ///
    /// When enabled, successfully parsed text is serialized as text elements
    /// instead of paths. Fonts are still required while parsing.
    pub fn to_svg_string(&self, #[frb(default = false)] preserve_text: bool) -> String {
        self.tree.to_string(&usvg::WriteOptions {
            preserve_text,
            ..usvg::WriteOptions::default()
        })
    }
}

fn parse_tree(
    data: Vec<u8>,
    options: Option<ParseOptions>,
    database: Option<usvg::fontdb::Database>,
) -> Result<SvgTree, String> {
    let options = to_usvg_options(options.unwrap_or_default(), database);
    usvg::Tree::from_data(&data, &options)
        .map(|tree| SvgTree { tree })
        .map_err(|error| error.to_string())
}

fn to_usvg_options(
    options: ParseOptions,
    database: Option<usvg::fontdb::Database>,
) -> usvg::Options<'static> {
    let mut result = usvg::Options::default();
    result.resources_dir = options.resources_dir.map(PathBuf::from);
    result.dpi = options.dpi;
    result.font_family = options.font_family;
    result.font_size = options.font_size;
    result.languages = options.languages;
    result.style_sheet = options.style_sheet;
    if let Some(database) = database {
        result.fontdb = Arc::new(database);
    } else if options.load_system_fonts {
        result.fontdb = system_font_database();
    }
    for font_data in options.font_data {
        result.fontdb_mut().load_font_data(font_data);
    }
    result
}

fn system_font_database() -> Arc<usvg::fontdb::Database> {
    static SYSTEM_FONTS: OnceLock<Arc<usvg::fontdb::Database>> = OnceLock::new();
    SYSTEM_FONTS
        .get_or_init(|| {
            let mut database = usvg::fontdb::Database::new();
            database.load_system_fonts();
            Arc::new(database)
        })
        .clone()
}

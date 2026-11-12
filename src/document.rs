use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

const FORMAT_VERSION: u32 = 1;

/// On-disk document format. It is intentionally simple JSON so that study
/// material can be inspected, version-controlled, or backed up easily.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StudyDocument {
    #[serde(default = "default_format_version")]
    pub format_version: u32,
    #[serde(default)]
    pub source_text: String,
    #[serde(default)]
    pub translations: HashMap<String, String>,
    #[serde(default, skip_serializing)]
    pub current_path: Option<PathBuf>,
}

fn default_format_version() -> u32 {
    FORMAT_VERSION
}

impl Default for StudyDocument {
    fn default() -> Self {
        Self {
            format_version: FORMAT_VERSION,
            source_text: String::new(),
            translations: HashMap::new(),
            current_path: None,
        }
    }
}

impl StudyDocument {
    pub fn set_source_text(&mut self, source_text: String) {
        if self.source_text == source_text {
            return;
        }
        self.source_text = source_text;
    }

    pub fn set_translation(&mut self, key: &str, translation: String) {
        if translation.trim().is_empty() {
            self.translations.remove(key);
        } else {
            self.translations.insert(key.to_owned(), translation);
        }
    }

    pub fn translation(&self, key: &str) -> &str {
        self.translations
            .get(key)
            .map(String::as_str)
            .unwrap_or_default()
    }

    pub fn save_to_path(&mut self, path: &Path) -> Result<(), String> {
        let json = serde_json::to_string_pretty(self)
            .map_err(|error| format!("保存データを準備できませんでした: {error}"))?;
        fs::write(path, json).map_err(|error| format!("保存できませんでした: {error}"))?;
        self.current_path = Some(path.to_path_buf());
        Ok(())
    }

    pub fn load_from_path(path: &Path) -> Result<Self, String> {
        let json =
            fs::read_to_string(path).map_err(|error| format!("読み込めませんでした: {error}"))?;
        let mut document: Self = serde_json::from_str(&json)
            .map_err(|error| format!("学習データを解釈できませんでした: {error}"))?;

        if document.format_version > FORMAT_VERSION {
            return Err("このファイルは新しいバージョンの形式で保存されています。".to_owned());
        }

        document.current_path = Some(path.to_path_buf());
        Ok(document)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_translation_is_removed() {
        let mut document = StudyDocument::default();
        document.set_translation("exam", "試験".to_owned());
        assert_eq!(document.translation("exam"), "試験");

        document.set_translation("exam", "  ".to_owned());
        assert_eq!(document.translation("exam"), "");
    }
}

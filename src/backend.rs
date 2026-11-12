use std::path::{Path, PathBuf};

use qtbridge::qobject;

use crate::document::StudyDocument;
use crate::tokens::tokenize_lines;

/// State exposed to QML. All study data is kept in Rust; QML only renders it
/// and forwards user actions.
#[derive(Default)]
pub struct StudyBackend {
    document: StudyDocument,
    source_text: String,
    translations_json: String,
    tokens_json: String,
    error_message: String,
    current_file: String,
    dirty: bool,
    translated_count: u32,
    total_count: u32,
}

#[qobject]
impl StudyBackend {
    qproperty!("sourceText", Member = source_text, Notify = source_changed);
    qproperty!(
        "translationsJson",
        Member = translations_json,
        Notify = translations_changed
    );
    qproperty!("tokensJson", Member = tokens_json, Notify = tokens_changed);
    qproperty!("dirty", Member = dirty, Notify = dirty_changed);
    qproperty!(
        "statusMessage",
        Member = error_message,
        Notify = status_changed
    );
    qproperty!(
        "currentFile",
        Member = current_file,
        Notify = document_loaded
    );
    qproperty!(
        "translatedCount",
        Member = translated_count,
        Notify = tokens_changed
    );
    qproperty!("totalCount", Member = total_count, Notify = tokens_changed);

    /// Update the English source text. Translations already entered are kept
    /// when a word remains in the text.
    #[qslot]
    fn set_source_text(&mut self, text: &String) {
        if self.document.source_text == *text {
            return;
        }

        self.document.set_source_text(text.clone());
        self.source_text = text.clone();
        self.dirty = true;
        self.rebuild_tokens();
        self.source_changed();
        self.dirty_changed();
    }

    /// Set or clear the Japanese translation for one occurrence-specific key.
    #[qslot]
    #[allow(clippy::ptr_arg)]
    fn set_translation(&mut self, key: &String, translation: &String) {
        if key.is_empty() {
            return;
        }

        self.document.set_translation(key, translation.clone());
        self.dirty = true;
        self.rebuild_tokens();
        self.translations_changed();
        self.tokens_changed();
        self.dirty_changed();
    }

    /// Remove a translation without changing the source text.
    #[qslot]
    #[allow(clippy::ptr_arg)]
    fn clear_translation(&mut self, key: &String) {
        if self.document.translations.remove(key).is_some() {
            self.dirty = true;
            self.rebuild_tokens();
            self.translations_changed();
            self.tokens_changed();
            self.dirty_changed();
        }
    }

    /// Start a new, empty study document.
    #[qslot]
    fn new_document(&mut self) {
        self.document = StudyDocument::default();
        self.source_text.clear();
        self.current_file.clear();
        self.dirty = false;
        self.rebuild_tokens();
        self.source_changed();
        self.translations_changed();
        self.tokens_changed();
        self.dirty_changed();
        self.document_loaded();
        self.error_message = "新しい学習データを作成しました".to_owned();
        self.status_changed();
    }

    /// Save the current document. The path is supplied by QML's native file
    /// dialog, so no path parsing or platform-specific dialog code is needed.
    #[qslot]
    fn save_document(&mut self, path: &String) {
        if path.trim().is_empty() {
            self.error_message = "保存先を指定してください".to_owned();
            self.status_changed();
            self.save_succeeded(false);
            return;
        }

        let path = PathBuf::from(path);
        match self.document.save_to_path(&path) {
            Ok(()) => {
                self.current_file = path.to_string_lossy().into_owned();
                self.dirty = false;
                self.error_message = format!("保存しました: {}", self.current_file);
                self.dirty_changed();
                self.document_loaded();
                self.status_changed();
                self.save_succeeded(true);
            }
            Err(error) => {
                self.error_message = error;
                self.status_changed();
                self.save_succeeded(false);
            }
        }
    }

    /// Load a document selected through QML's native file dialog.
    #[qslot]
    fn open_document(&mut self, path: &String) {
        if path.trim().is_empty() {
            return;
        }

        match StudyDocument::load_from_path(Path::new(path)) {
            Ok(document) => {
                self.document = document;
                self.source_text = self.document.source_text.clone();
                self.current_file = path.clone();
                self.dirty = false;
                self.rebuild_tokens();
                self.source_changed();
                self.translations_changed();
                self.tokens_changed();
                self.dirty_changed();
                self.document_loaded();
                self.error_message = format!("読み込みました: {path}");
                self.status_changed();
                self.open_succeeded(true);
            }
            Err(error) => {
                self.error_message = error;
                self.status_changed();
                self.open_succeeded(false);
            }
        }
    }

    /// Return the JSON representation consumed by QML. Keeping this small
    /// bridge JSON-based avoids duplicating the complete document model in
    /// generated Qt binding types.
    #[qslot]
    fn document_json(&self) -> String {
        serde_json::to_string(&self.document).unwrap_or_else(|_| "{}".to_owned())
    }

    fn rebuild_tokens(&mut self) {
        let lines = tokenize_lines(&self.document.source_text);
        let mut total = 0u32;
        let mut translated = 0u32;
        let mut payload_lines = Vec::with_capacity(lines.len());

        for line in lines {
            let mut payload_tokens = Vec::with_capacity(line.len());
            for token in line {
                let translation = self.document.translation(&token.key).to_owned();
                let is_translated = !translation.trim().is_empty();

                if token.is_word {
                    total += 1;
                    if is_translated {
                        translated += 1;
                    }
                }

                payload_tokens.push(TokenPayload {
                    key: token.key.clone(),
                    text: token.text.clone(),
                    is_word: token.is_word,
                    translation,
                    translated: is_translated,
                });
            }
            payload_lines.push(payload_tokens);
        }

        self.total_count = total;
        self.translated_count = translated;
        self.tokens_json =
            serde_json::to_string(&payload_lines).unwrap_or_else(|_| "[]".to_owned());
        self.translations_json =
            serde_json::to_string(&self.document.translations).unwrap_or_else(|_| "{}".to_owned());
    }

    #[qsignal]
    fn source_changed(&mut self);

    #[qsignal]
    fn translations_changed(&mut self);

    #[qsignal]
    fn tokens_changed(&mut self);

    #[qsignal]
    fn dirty_changed(&mut self);

    #[qsignal]
    fn status_changed(&mut self);

    #[qsignal]
    fn document_loaded(&mut self);

    #[qsignal]
    fn save_succeeded(&mut self, success: bool);

    #[qsignal]
    fn open_succeeded(&mut self, success: bool);
}

#[derive(Debug, serde::Serialize)]
struct TokenPayload {
    key: String,
    text: String,
    is_word: bool,
    translation: String,
    translated: bool,
}

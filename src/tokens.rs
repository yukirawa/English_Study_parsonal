use std::collections::HashMap;

use serde::{Deserialize, Serialize};

/// A token in the English source text.
///
/// Word tokens receive an occurrence-specific key such as `exam#2`, so the
/// same spelling can be translated differently in two places. Non-word tokens
/// (punctuation and whitespace) have an empty key.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WordToken {
    pub key: String,
    pub text: String,
    pub is_word: bool,
}

/// Split each source line into tokens while keeping one global occurrence
/// counter per spelling. This lets the UI preserve line structure while every
/// repeated word still gets its own translation key.
pub fn tokenize_lines(source: &str) -> Vec<Vec<WordToken>> {
    let mut counts = HashMap::new();
    source
        .lines()
        .map(|line| tokenize_with_counts(line, &mut counts))
        .collect()
}

fn tokenize_with_counts(
    source: &str,
    occurrence_counts: &mut HashMap<String, usize>,
) -> Vec<WordToken> {
    let mut tokens = Vec::new();
    let chars: Vec<char> = source.chars().collect();
    let mut index = 0;

    while index < chars.len() {
        let ch = chars[index];
        if is_word_start(ch) {
            let start = index;
            index += 1;

            while index < chars.len() {
                let current = chars[index];
                if is_word_continue(current) {
                    index += 1;
                    continue;
                }

                // Keep apostrophes and hyphens only when a letter follows.
                if is_word_joinable(current)
                    && index + 1 < chars.len()
                    && is_word_start(chars[index + 1])
                {
                    index += 2;
                    continue;
                }
                break;
            }

            let text: String = chars[start..index].iter().collect();
            let base_key = normalize_key(&text);
            let occurrence = occurrence_counts.entry(base_key.clone()).or_insert(0);
            *occurrence += 1;
            tokens.push(WordToken {
                key: format!("{base_key}#{occurrence}"),
                text,
                is_word: true,
            });
        } else {
            let start = index;
            index += 1;
            let text: String = chars[start..index].iter().collect();
            tokens.push(WordToken {
                key: String::new(),
                text,
                is_word: false,
            });
        }
    }

    tokens
}

/// Normalize the spelling part of a token. Occurrence numbers are added by
/// the tokenizer, so translation keys remain stable within one document.
fn normalize_key(text: &str) -> String {
    text.to_lowercase()
}

fn is_word_start(ch: char) -> bool {
    ch.is_alphabetic()
}

fn is_word_continue(ch: char) -> bool {
    ch.is_alphanumeric() || ch == '\''
}

fn is_word_joinable(ch: char) -> bool {
    ch == '\'' || ch == '\u{2019}' || ch == '-'
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tokenizes_words_and_preserves_text() {
        let source = "Don't stop, well-known tests!";
        let tokens = tokenize_lines(source)
            .into_iter()
            .flatten()
            .collect::<Vec<_>>();
        let reconstructed: String = tokens.iter().map(|token| token.text.as_str()).collect();

        assert_eq!(reconstructed, source);
        assert_eq!(tokens[0].text, "Don't");
        assert_eq!(tokens[0].key, "don't#1");
        assert_eq!(tokens[5].text, "well-known");
        assert_eq!(tokens[5].key, "well-known#1");
    }

    #[test]
    fn gives_each_occurrence_its_own_translation_key() {
        let tokens = tokenize_lines("Exam exam EXAM.")
            .into_iter()
            .flatten()
            .collect::<Vec<_>>();

        assert_eq!(tokens[0].key, "exam#1");
        assert_eq!(tokens[2].key, "exam#2");
        assert_eq!(tokens[4].key, "exam#3");
        assert!(!tokens[5].is_word);
        assert_eq!(tokens[5].key, "");
    }
}

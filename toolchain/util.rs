//! Small shared I/O and binary representation helpers.
use anyhow::{Context, Result, ensure};
pub fn unhex(text: &str) -> Result<Vec<u8>> {
    ensure!(text.len().is_multiple_of(2), "Odd hexadecimal byte string");
    let digit = |c: u8| {
        (c as char)
            .to_digit(16)
            .with_context(|| format!("Invalid hexadecimal byte string {text:?}"))
    };
    text.as_bytes()
        .chunks(2)
        .map(|pair| Ok((digit(pair[0])? * 16 + digit(pair[1])?) as u8))
        .collect()
}

pub fn write_changed(path: &std::path::Path, bytes: &[u8]) -> Result<()> {
    if !std::fs::read(path).is_ok_and(|old| old == bytes) {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(path, bytes)?;
    }
    Ok(())
}
pub fn trash(paths: impl IntoIterator<Item = std::path::PathBuf>) -> Result<()> {
    let paths: Vec<_> = paths.into_iter().filter(|p| p.exists()).collect();
    if !paths.is_empty() {
        ensure!(
            std::process::Command::new("trash")
                .args(paths)
                .status()?
                .success(),
            "Could not trash obsolete files"
        );
    }
    Ok(())
}

pub(crate) fn array<'a>(value: &'a serde_json::Value, key: &str) -> &'a [serde_json::Value] {
    value
        .get(key)
        .and_then(serde_json::Value::as_array)
        .map_or(&[], |a| a)
}
pub(crate) fn string<'a>(value: &'a serde_json::Value, key: &str) -> &'a str {
    value
        .get(key)
        .and_then(serde_json::Value::as_str)
        .unwrap_or("")
}
pub(crate) fn yes(value: &serde_json::Value, key: &str) -> bool {
    value
        .get(key)
        .and_then(serde_json::Value::as_bool)
        .unwrap_or(false)
}
pub(crate) fn integer(value: &serde_json::Value, key: &str) -> Result<i64> {
    value
        .get(key)
        .and_then(serde_json::Value::as_i64)
        .with_context(|| format!("missing integer {key}"))
}

#[cfg(test)]
mod tests {
    use super::unhex;

    #[test]
    fn unhex_rejects_non_ascii_without_panicking() {
        assert_eq!(unhex("0aFf").unwrap(), [0x0a, 0xff]);
        assert!(unhex("zz").is_err());
        assert!(unhex("0\u{20ac}").is_err());
    }
}

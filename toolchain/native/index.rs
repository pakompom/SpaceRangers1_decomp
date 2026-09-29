//! Explicit native inventory refreshed by `decomp index`; matching never contacts IDA.
use crate::{
    inspect::ida,
    util::{array, string, write_changed},
};
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::{fs, path::Path};

#[derive(Serialize, Deserialize)]
pub struct NativeIndex {
    pub ranges: Value,
    pub snapshot: Value,
}
impl NativeIndex {
    /// Reads the local refresh when present, otherwise the bundled reference.
    pub fn read(root: &Path, cache: &Path) -> Result<Self> {
        let local = cache.join("native_ranges.json");
        let path = if local.exists() {
            local
        } else {
            root.join("reference/native_ranges.json")
        };
        let bytes = fs::read(&path).context("Native index missing; run ./decomp index")?;
        serde_json::from_slice(&bytes).context("Native index needs refreshing; run ./decomp index")
    }
    pub fn refresh(root: &Path, db: &Path, cache: &Path) -> Result<usize> {
        let snapshot = ida::run(root, db, "coverage", json!({"chunks":true}))?;
        let functions = array(&snapshot, "functions");
        let ranges: serde_json::Map<String, Value> = functions
            .iter()
            .map(|f| {
                let chunks = array(f, "chunks")
                    .iter()
                    .map(|c| json!({"start":c[0],"end":c[1]}))
                    .collect::<Vec<_>>();
                (
                    f["ea"].to_string(),
                    json!({"name":string(f,"name"),"chunks":chunks}),
                )
            })
            .collect();
        let count = ranges.len();
        write_changed(
            &cache.join("native_ranges.json"),
            &serde_json::to_vec(&Self {
                ranges: Value::Object(ranges),
                snapshot,
            })?,
        )?;
        Ok(count)
    }
}

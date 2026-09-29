//! DCC32 detailed MAP files: public symbols and linker unit contributions.

use anyhow::{Context, Result, ensure};
use serde::Serialize;
use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::Path,
};

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Serialize)]
pub struct Symbol {
    pub address: u32,
    pub name: String,
    pub section: u16,
}

#[derive(Debug, Serialize)]
pub struct Contribution {
    pub unit: String,
    pub class: String,
    pub section: String,
    pub address: u32,
    pub end: u32,
}
#[derive(Debug, Serialize)]
pub struct MapFile {
    pub symbols: Vec<Symbol>,
    pub contributions: Vec<(u32, u32, String)>,
    pub storage: Vec<Contribution>,
}

impl MapFile {
    pub fn parse(text: &str) -> Result<Self> {
        Self::parse_bases(text, &BTreeMap::new())
    }

    pub fn read(path: &Path) -> Result<Self> {
        let text = fs::read_to_string(path)?;
        for extension in ["exe", "dll", "bpl"] {
            let binary = path.with_extension(extension);
            if binary.is_file() {
                return Self::parse_image(&text, &fs::read(binary)?);
            }
        }
        Self::parse(&text)
    }

    pub fn parse_image(text: &str, bytes: &[u8]) -> Result<Self> {
        let pe = goblin::pe::PE::parse(bytes)?;
        let mut sections = BTreeMap::new();
        for section in &pe.sections {
            let name = section.name()?.to_ascii_lowercase();
            let name = match name.as_str() {
                "code" => ".text",
                "data" => ".data",
                "bss" => ".bss",
                _ => &name,
            };
            sections.insert(
                name.to_owned(),
                pe.image_base as u32 + section.virtual_address,
            );
        }
        Self::parse_bases(text, &sections)
    }

    fn parse_bases(text: &str, sections: &BTreeMap<String, u32>) -> Result<Self> {
        let mut bases = BTreeMap::new();
        let mut symbols = BTreeSet::new();
        let mut contributions = Vec::new();
        let mut storage = Vec::new();
        let mut owners = Vec::new();
        let mut legacy = false;
        for line in text.lines() {
            let fields: Vec<_> = line.split_whitespace().collect();
            let Some((segment, offset)) = fields.first().and_then(|f| f.split_once(':')) else {
                continue;
            };
            if segment.len() != 4 || offset.len() != 8 {
                continue;
            }
            let (Ok(segment), Ok(offset)) = (
                u16::from_str_radix(segment, 16),
                u32::from_str_radix(offset, 16),
            ) else {
                continue;
            };
            if fields.len() >= 4 && fields[1].ends_with('H') && fields[2].starts_with('.') {
                if fields[2] == ".text" {
                    legacy = offset == 0;
                }
                // Delphi 7 combines DATA/BSS into one segment. The first row
                // establishes its base; the BSS row must not replace it.
                if let std::collections::btree_map::Entry::Vacant(e) = bases.entry(segment) {
                    let base = if legacy {
                        sections
                            .get(fields[2])
                            .copied()
                            .context("Delphi 7 MAP requires its linked PE image")?
                            .checked_sub(offset)
                            .context("Invalid legacy MAP section offset")?
                    } else {
                        offset
                    };
                    e.insert(base);
                }
            } else if let Some(base) = bases.get(&segment) {
                if fields.len() >= 3 {
                    let attrs: BTreeMap<_, _> = fields[2..]
                        .iter()
                        .filter_map(|p| p.split_once('='))
                        .collect();
                    if let Some(unit) = attrs.get("M") {
                        let low = base + offset;
                        let high = low
                            .checked_add(u32::from_str_radix(fields[1], 16)?)
                            .ok_or_else(|| anyhow::anyhow!("MAP contribution overflows Win32"))?;
                        owners.push((segment, low, high, (*unit).to_owned()));
                        storage.push(Contribution {
                            unit: (*unit).into(),
                            class: attrs.get("C").copied().unwrap_or("").into(),
                            section: attrs.get("S").copied().unwrap_or("").into(),
                            address: low,
                            end: high,
                        });
                        if attrs.get("C") == Some(&"CODE") && attrs.get("S") == Some(&".text") {
                            contributions.push((low, high, (*unit).to_owned()));
                        }
                    }
                } else if fields.len() == 2
                    && fields[1]
                        .chars()
                        .all(|c| c.is_alphanumeric() || "_.@$".contains(c))
                {
                    symbols.insert(Symbol {
                        address: base + offset,
                        name: fields[1].into(),
                        section: segment,
                    });
                }
            }
        }
        ensure!(!symbols.is_empty(), "No linked symbols in MAP");
        let mut symbols = symbols.into_iter().collect::<Vec<_>>();
        if legacy {
            for symbol in &mut symbols {
                let units = owners
                    .iter()
                    .filter(|(segment, low, high, _)| {
                        *segment == symbol.section
                            && *low <= symbol.address
                            && symbol.address < *high
                    })
                    .map(|(_, _, _, unit)| unit)
                    .collect::<BTreeSet<_>>();
                if units.len() == 1 {
                    symbol.name = format!("{}.{}", units.first().unwrap(), symbol.name);
                }
            }
        }
        Ok(Self {
            symbols,
            contributions,
            storage,
        })
    }

    pub fn unit_at(&self, address: u32) -> Option<&str> {
        self.contributions
            .iter()
            .find(|(low, high, _)| *low <= address && address < *high)
            .map(|(_, _, name)| name.as_str())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn delphi7_relative_and_unqualified_map() -> Result<()> {
        let text = "0001:00000000 00000200H .text CODE\n0002:00000000 000000A0H .data DATA\n0002:000000A0 00000100H .bss BSS\n0001:00000010 00000020 C=CODE S=.text M=Alpha\n0002:00001000 00000020 C=BSS S=.bss M=Alpha\n0001:00000010 Work\n0002:00001004 State\n";
        let map = MapFile::parse_bases(
            text,
            &BTreeMap::from([(".text".into(), 0x401000), (".data".into(), 0x404000)]),
        )?;
        assert_eq!(map.symbols[0].name, "Alpha.Work");
        assert_eq!(map.symbols[0].address, 0x401010);
        assert_eq!(map.symbols[1].address, 0x405004);
        assert_eq!(map.unit_at(0x401010), Some("Alpha"));
        assert!(MapFile::parse(text).is_err());
        Ok(())
    }
    #[test]
    fn duplicate_publics_and_contributions() -> Result<()> {
        let map = MapFile::parse(
            "0001:00401000 00000200H .text CODE\n0001:00000010 00000020 C=CODE S=.text M=Alpha\n0001:00000010 Alpha.Work\n0001:00000010 Alpha.Work\n0001:00000010 Alpha.Alias\n",
        )?;
        assert_eq!(map.symbols.len(), 2);
        assert_eq!(map.unit_at(0x40102f), Some("Alpha"));
        assert_eq!(map.unit_at(0x401030), None);
        Ok(())
    }
}

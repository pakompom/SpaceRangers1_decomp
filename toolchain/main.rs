use anyhow::Result;
use std::path::Path;

fn main() -> Result<()> {
    let args: Vec<_> = std::env::args().collect();
    if args.get(1).map(String::as_str) == Some("worker-serve") && args.len() == 4 {
        return sr1_decomp::compiler::worker::serve(sr1_decomp::compiler::worker::Toolchain::load(
            Path::new(&args[2]),
            Some(&args[3]),
        )?);
    }
    let status = sr1_decomp::cli::run(&std::env::current_dir()?, &args[1..])?;
    std::process::exit(status);
}

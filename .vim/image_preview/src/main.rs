use image::RgbImage;
use std::env;
use std::fmt::Write;
use std::io::{self, Write as IoWrite};
use std::path::Path;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: image_preview <image_file> [width_chars]");
        std::process::exit(1);
    }

    let path = &args[1];
    let width: u32 = args.get(2).and_then(|w| w.parse().ok()).unwrap_or(100);

    let img = match image::open(Path::new(path)) {
        Ok(img) => img,
        Err(e) => {
            eprintln!("Cannot open image: {}", e);
            std::process::exit(1);
        }
    };

    let rgb = img.to_rgb();
    let (orig_w, orig_h) = rgb.dimensions();

    // Terminal chars are ~2x taller than wide, so shrink height for correct aspect
    let aspect = orig_h as f64 / orig_w as f64;
    let new_h = ((width as f64) * aspect * 0.5).max(1.0) as u32;

    // Resize using nearest neighbor for speed
    let resized: RgbImage = image::imageops::resize(&rgb, width, new_h, image::imageops::FilterType::Nearest);

    let mut out = io::stdout();
    let mut line = String::with_capacity((width as usize) * 20);

    for y in 0..new_h {
        line.clear();
        for x in 0..width {
            let pixel = resized.get_pixel(x, y);
            let _ = write!(line, "\x1b[48;2;{};{};{}m  \x1b[0m", pixel[0], pixel[1], pixel[2]);
        }
        let _ = writeln!(out, "{}", line);
    }
    let _ = out.flush();
}

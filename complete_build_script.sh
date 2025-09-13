#!/usr/bin/env bash

# xqi's Wallpaper Gallery Build Script
# Generates HTML with GitHub button and dark/light mode toggle

set -e  # Exit on error

echo "Starting Wallpaper Gallery Build..."

generate_thumbnails() {
  echo "Generating thumbnails..."
  
  if ! command -v convert &> /dev/null; then
    echo "ImageMagick 'convert' not found!"
    echo "Please install ImageMagick first:"
    echo "  - macOS: brew install imagemagick"
    echo "  - Ubuntu: sudo apt install imagemagick"
    echo "  - Windows: Download from imagemagick.org"
    exit 1
  fi
  
  mkdir -p thumbnails
  rm -rf thumbnails/*
  
  total_images=$(find ./wallpapers -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | wc -l)
  current_image=0
  
  if [ "$total_images" -eq 0 ]; then
    echo "No images found in ./wallpapers/ directory!"
    echo "Please add wallpapers to ./wallpapers/{section}/ folders"
    exit 1
  fi
  
  for section_dir in ./wallpapers/*; do
    [ -d "$section_dir" ] || continue
    section_name="${section_dir##*/}"
    mkdir -p "thumbnails/$section_name"
    
    # Process main images
    for img in "$section_dir"/*; do
      [ -f "$img" ] || continue
      case "$img" in
        *.jpg|*.jpeg|*.png|*.webp|*.JPG|*.JPEG|*.PNG|*.WEBP) ;;
        *) continue ;;
      esac
      
      current_image=$((current_image + 1))
      local img_filename="${img##*/}"
      local thumbnail="thumbnails/$section_name/$img_filename"
      echo "  ($current_image/$total_images): $img_filename"
      convert "$img" -resize 400x300^ -gravity center -extent 400x300 "$thumbnail" 2>/dev/null || {
        echo "    Failed to process $img"
        continue
      }
    done
  done
  
  echo "Thumbnail generation complete: $total_images images processed"
}

create_section_data() {
  local section=$1
  local subdir=$2
  local maxPerPage=10  # Fewer images per page for 2-column layout
  
  echo "Creating data for section: $section"
  
  local data_file="${section}_data.js"
  
  cat > "$data_file" << EOF
window.sectionData = window.sectionData || {};
window.sectionData['$section'] = {
  maxPerPage: $maxPerPage,
  dark: [
EOF

  # Generate dark images data
  local dark_count=0
  for wallpaper in "$subdir"/*; do
    [ -f "$wallpaper" ] || continue
    case "$wallpaper" in
      *.jpg|*.jpeg|*.png|*.webp|*.JPG|*.JPEG|*.PNG|*.WEBP) ;;
      *) continue ;;
    esac
    
    local img_path="${wallpaper#./}"
    local img_filename="${wallpaper##*/}"
    local img_basename="${img_filename%.*}"
    local thumbnail_path="thumbnails/$section/$img_filename"
    echo "    { src: '$img_path', thumb: '$thumbnail_path', alt: '$img_basename', title: '$(echo "$img_basename" | tr '_' ' ')' }," >> "$data_file"
    dark_count=$((dark_count + 1))
  done

  echo "  ]" >> "$data_file"
  echo "};" >> "$data_file"
  echo "    🌙 Images: $dark_count"
}

create_main_html() {
  cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>xqi's wallpaper</title>
    <style>
        /* Catppuccin theme system with proper light/dark mode */
        :root {
            /* Catppuccin Macchiato (Dark) colors */
            --ctp-rosewater: #f4dbd6;
            --ctp-flamingo: #f0c6c6;
            --ctp-pink: #f5bde6;
            --ctp-mauve: #c6a0f6;
            --ctp-red: #ed8796;
            --ctp-maroon: #ee99a0;
            --ctp-peach: #f5a97f;
            --ctp-yellow: #eed49f;
            --ctp-green: #a6da95;
            --ctp-teal: #8bd5ca;
            --ctp-sky: #91d7e3;
            --ctp-sapphire: #7dc4e4;
            --ctp-blue: #8aadf4;
            --ctp-lavender: #b7bdf8;
            --ctp-text: #cad3f5;
            --ctp-subtext1: #b8c0e0;
            --ctp-subtext0: #a5adcb;
            --ctp-overlay2: #939ab7;
            --ctp-overlay1: #8087a2;
            --ctp-overlay0: #6e738d;
            --ctp-surface2: #5b6078;
            --ctp-surface1: #494d64;
            --ctp-surface0: #363a4f;
            --ctp-base: #24273a;
            --ctp-mantle: #1e2030;
            --ctp-crust: #181926;

            /* Catppuccin Latte (Light) colors */
            --ctp-light-rosewater: #dc8a78;
            --ctp-light-flamingo: #dd7878;
            --ctp-light-pink: #ea76cb;
            --ctp-light-mauve: #8839ef;
            --ctp-light-red: #d20f39;
            --ctp-light-maroon: #e64553;
            --ctp-light-peach: #fe640b;
            --ctp-light-yellow: #df8e1d;
            --ctp-light-green: #40a02b;
            --ctp-light-teal: #179299;
            --ctp-light-sky: #04a5e5;
            --ctp-light-sapphire: #209fb5;
            --ctp-light-blue: #1e66f5;
            --ctp-light-lavender: #7287fd;
            --ctp-light-text: #4c4f69;
            --ctp-light-subtext1: #5c5f77;
            --ctp-light-subtext0: #6c6f85;
            --ctp-light-overlay2: #7c7f93;
            --ctp-light-overlay1: #8c8fa1;
            --ctp-light-overlay0: #9ca0b0;
            --ctp-light-surface2: #acb0be;
            --ctp-light-surface1: #bcc0cc;
            --ctp-light-surface0: #ccd0da;
            --ctp-light-base: #eff1f5;
            --ctp-light-mantle: #e6e9ef;
            --ctp-light-crust: #dce0e8;
        }

        /* Theme variables for dark mode (default) */
        [data-theme="dark"] {
            --bg: var(--ctp-base);
            --fg: var(--ctp-text);
            --fg-muted: var(--ctp-subtext1);
            --fg-subtle: var(--ctp-subtext0);
            --border: var(--ctp-surface1);
            --surface: var(--ctp-surface0);
            --surface-elevated: var(--ctp-mantle);
            --link: var(--ctp-blue);
            --link-hover: var(--ctp-sapphire);
            --accent: var(--ctp-mauve);
            --success: var(--ctp-green);
            --warning: var(--ctp-yellow);
            --error: var(--ctp-red);
            --pink: var(--ctp-pink);
            --peach: var(--ctp-peach);
        }

        /* Theme variables for light mode */
        [data-theme="light"] {
            --bg: var(--ctp-light-base);
            --fg: var(--ctp-light-text);
            --fg-muted: var(--ctp-light-subtext1);
            --fg-subtle: var(--ctp-light-subtext0);
            --border: var(--ctp-light-surface1);
            --surface: var(--ctp-light-surface0);
            --surface-elevated: var(--ctp-light-mantle);
            --link: var(--ctp-light-blue);
            --link-hover: var(--ctp-light-sapphire);
            --accent: var(--ctp-light-mauve);
            --success: var(--ctp-light-green);
            --warning: var(--ctp-light-yellow);
            --error: var(--ctp-light-red);
            --pink: var(--ctp-light-pink);
            --peach: var(--ctp-light-peach);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            background: var(--bg);
            color: var(--fg);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            min-height: 100vh;
            transition: background-color 0.3s ease, color 0.3s ease;
        }

        /* Fixed action buttons - top right corner */
        .action-buttons {
            position: fixed;
            top: 20px;
            right: 20px;
            display: flex;
            gap: 12px;
            z-index: 1000;
        }

        .action-btn {
            width: 48px;
            height: 48px;
            background: var(--surface-elevated);
            border: 1px solid var(--border);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s ease;
            backdrop-filter: blur(10px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
            text-decoration: none;
            color: var(--fg);
        }

        .action-btn:hover {
            background: linear-gradient(135deg, var(--accent), var(--link));
            color: var(--bg);
            transform: translateY(-2px) scale(1.05);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
        }

        .github-btn:hover {
            background: linear-gradient(135deg, var(--fg), var(--fg-muted));
        }

        .theme-toggle .sun-icon {
            display: none;
        }

        .theme-toggle .moon-icon {
            display: block;
            transition: transform 0.3s ease;
        }

        [data-theme="light"] .theme-toggle .sun-icon {
            display: block;
        }

        [data-theme="light"] .theme-toggle .moon-icon {
            display: none;
        }

        .theme-toggle:hover .sun-icon,
        .theme-toggle:hover .moon-icon {
            transform: rotate(180deg);
        }

        /* Header matching the artifact exactly */
        .header {
            background: var(--surface-elevated);
            padding: 20px 0;
            position: sticky;
            top: 0;
            z-index: 100;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
            transition: background-color 0.3s ease;
        }

        .header-content {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 20px;
            padding: 0 20px;
        }

        .header-top {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 100%;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .logo-icon {
            width: 60px;
            height: 60px;
            background: conic-gradient(from 0deg, var(--error), var(--peach), var(--warning), var(--success), var(--link), var(--accent), var(--pink), var(--error));
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
        }

        .logo h1 {
            font-family: "Pacifico", cursive;
            font-size: 1.8rem;
            color: var(--fg);
            font-weight: normal;
        }

        /* Main content */
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }

        .warning-box {
            background: linear-gradient(135deg, rgba(238, 212, 159, 0.1), rgba(238, 212, 159, 0.05));
            border: 1px solid var(--warning);
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 30px;
            color: var(--fg-subtle);
        }

        .warning-box strong {
            color: var(--warning);
        }

        .warning-box a {
            color: var(--link);
            text-decoration: underline;
            font-style: italic;
        }

        .intro {
            margin-bottom: 40px;
            color: var(--fg-muted);
        }

        .intro p {
            margin-bottom: 8px;
        }

        .intro .note {
            color: var(--fg-subtle);
            font-style: italic;
            margin-top: 16px;
        }

        .intro .note strong {
            color: var(--fg);
        }

        /* Section headers */
        .section-header {
            font-size: 1.5em;
            font-weight: 600;
            margin: 32px 0 16px 0;
            padding-bottom: 8px;
            border-bottom: 2px solid var(--border);
            cursor: pointer;
            color: var(--fg);
            transition: color 0.2s ease;
            text-transform: capitalize;
        }

        .section-header:hover {
            color: var(--accent);
        }

        .section {
            display: none;
            margin: 24px 0;
        }

        .section.active {
            display: block;
            animation: fadeIn 0.3s ease-in-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Image grid - exactly 2 columns like the artifact */
        .image-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 32px;
            margin-top: 40px;
        }

        .image-item {
            position: relative;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid var(--border);
            transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
            background: var(--surface);
        }

        .image-item:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
            border-color: var(--accent);
        }

        .image-item img {
            width: 100%;
            height: auto;
            display: block;
            transition: filter 0.2s ease;
        }

        .image-item:hover img {
            filter: brightness(1.05);
        }

        .image-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            background: linear-gradient(135deg, rgba(54, 58, 79, 0.9), rgba(54, 58, 79, 0.7));
            padding: 16px;
            transform: translateY(-100%);
            transition: transform 0.3s ease;
            backdrop-filter: blur(10px);
        }

        .image-item:hover .image-overlay {
            transform: translateY(0);
        }

        .image-title {
            color: var(--fg);
            font-weight: 600;
            font-size: 1rem;
            margin-bottom: 4px;
        }

        .image-author {
            color: var(--fg-muted);
            font-size: 0.875rem;
        }

        .download-btn {
            position: absolute;
            bottom: 16px;
            right: 16px;
            background: linear-gradient(135deg, var(--accent), var(--link));
            color: white;
            border: none;
            width: 44px;
            height: 44px;
            border-radius: 50%;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            transition: all 0.3s ease;
            opacity: 0;
            transform: scale(0.8);
            backdrop-filter: blur(10px);
        }

        .image-item:hover .download-btn {
            opacity: 1;
            transform: scale(1);
        }

        .download-btn:hover {
            transform: scale(1.1);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.3);
        }

        /* Pagination */
        .pagination {
            margin: 32px 0;
            text-align: center;
            display: flex;
            justify-content: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .pagination button {
            background: var(--surface);
            border: 1px solid var(--border);
            color: var(--fg);
            padding: 8px 12px;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            min-width: 40px;
        }

        .pagination button.active {
            background: linear-gradient(135deg, var(--accent), var(--link));
            color: var(--bg);
            border-color: var(--accent);
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        .pagination button:hover:not(.active) {
            background: var(--border);
            transform: translateY(-1px);
        }

        /* Loading state */
        .loading {
            color: var(--fg-subtle);
            font-style: italic;
            text-align: center;
            padding: 40px;
            position: relative;
        }

        .loading::after {
            content: '';
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            width: 30px;
            height: 3px;
            background: linear-gradient(90deg, var(--accent), var(--link), var(--accent));
            border-radius: 2px;
            animation: loading 2s ease-in-out infinite;
        }

        @keyframes loading {
            0%, 100% { transform: translateX(-50%) scaleX(0.5); opacity: 0.5; }
            50% { transform: translateX(-50%) scaleX(1); opacity: 1; }
        }

        /* Responsive design */
        @media (max-width: 768px) {
            .action-buttons {
                top: 16px;
                right: 16px;
                gap: 8px;
            }

            .action-btn {
                width: 40px;
                height: 40px;
            }

            .header-top {
                flex-direction: column;
                gap: 16px;
            }

            .logo h1 {
                font-size: 1.4rem;
                text-align: center;
            }

            .image-grid {
                grid-template-columns: 1fr;
                gap: 24px;
            }

            .container {
                padding: 20px 16px;
            }
        }

        @media (max-width: 480px) {
            .action-buttons {
                top: 12px;
                right: 12px;
            }

            .logo-icon {
                width: 50px;
                height: 50px;
                font-size: 20px;
            }

            .logo h1 {
                font-size: 1.2rem;
            }

            .image-grid {
                gap: 20px;
            }
        }

        /* Hidden utility */
        .hidden {
            display: none;
        }

        /* Custom scrollbar */
        ::-webkit-scrollbar {
            width: 12px;
        }

        ::-webkit-scrollbar-track {
            background: var(--surface-elevated);
        }

        ::-webkit-scrollbar-thumb {
            background: linear-gradient(135deg, var(--accent), var(--link));
            border-radius: 6px;
        }

        ::-webkit-scrollbar-thumb:hover {
            background: linear-gradient(135deg, var(--link), var(--accent));
        }
    </style>
    <!-- Google Fonts for Pacifico -->
    <link href="https://fonts.googleapis.com/css2?family=Pacifico&display=swap" rel="stylesheet">
</head>
<body>
    <!-- Fixed action buttons -->
    <div class="action-buttons">
        <a href="https://github.com/xqi1337/personal-wallpapers" class="action-btn github-btn" target="_blank" title="View on GitHub">
            <svg width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
                <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.012 8.012 0 0 0 16 8c0-4.42-3.58-8-8-8z"/>
            </svg>
        </a>
        
        <button class="action-btn theme-toggle" onclick="toggleTheme()" title="Toggle theme">
            <svg class="sun-icon" width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
                <path d="M8 11a3 3 0 1 1 0-6 3 3 0 0 1 0 6zm0 1a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM8 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 0zm0 13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 13zm8-5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2a.5.5 0 0 1 .5.5zM3 8a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 3 8zm10.657-5.657a.5.5 0 0 1 0 .707l-1.414 1.415a.5.5 0 1 1-.707-.708l1.414-1.414a.5.5 0 0 1 .707 0zm-9.193 9.193a.5.5 0 0 1 0 .707L3.05 13.657a.5.5 0 0 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0zm9.193 2.121a.5.5 0 0 1-.707 0l-1.414-1.414a.5.5 0 0 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .707zM4.464 4.465a.5.5 0 0 1-.707 0L2.343 3.05a.5.5 0 1 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .708z"/>
            </svg>
            <svg class="moon-icon" width="20" height="20" fill="currentColor" viewBox="0 0 16 16">
                <path d="M6 .278a.768.768 0 0 1 .08.858 7.208 7.208 0 0 0-.878 3.46c0 4.021 3.278 7.277 7.318 7.277.527 0 1.04-.055 1.533-.16a.787.787 0 0 1 .81.316.733.733 0 0 1-.031.893A8.349 8.349 0 0 1 8.344 16C3.734 16 0 12.286 0 7.71 0 4.266 2.114 1.312 5.124.06A.752.752 0 0 1 6 .278z"/>
            </svg>
        </button>
    </div>

    <!-- Header matching the artifact exactly (without theme selector) -->
    <header class="header">
        <div class="header-content">
            <div class="header-top">
                <div class="logo">
                    <div class="logo-icon">❄️</div>
                    <h1>xqi's wallpaper dump</h1>
                </div>
            </div>
        </div>
    </header>

    <!-- Main content -->
    <main class="container">
        <!-- Warning box -->
        <div class="warning-box">
            <p>
                <strong>warning:</strong>
                this site is still a work in progress, you may have a better experience previewing the wallpapers 
                <a href="https://github.com/xqi1337/personal-wallpapers" target="_blank">here</a> in the meantime
            </p>
        </div>

        <!-- Intro text -->
        <div class="intro">
            <p>hii, welcome to my wallpaper dump!</p>
            <p>remember to credit original authors and enjoy your stay ^-^</p>
            <div class="note">
                <strong>note:</strong> the reason the wallpapers are compressed is to speed up your viewing experience, if you hover over the wallpaper you will find a download button
            </div>
        </div>
EOF

  # Add sections dynamically
  declare -a sections
  sections_created=0

  for subdir in ./wallpapers/*; do
    [ -d "$subdir" ] || continue
    section="${subdir##*/}"
    sections+=("$section")
    sections_created=$((sections_created + 1))
    
    # Add section header
    section_display=$(echo "$section" | tr '_' ' ')
    echo "        <h2 class=\"section-header\" onclick=\"toggleSection('$section')\">$section_display</h2>" >> index.html
    echo "        <div class=\"section\" id=\"$section\">" >> index.html
    echo "            <div class=\"loading\" id=\"$section-loading\">loading...</div>" >> index.html
    echo "            <div class=\"image-grid hidden\" id=\"$section-grid\"></div>" >> index.html
    echo "            <div class=\"pagination hidden\" id=\"$section-pagination\"></div>" >> index.html
    echo "        </div>" >> index.html
  done

  # Add JavaScript
  cat >> index.html << 'EOF'
    </main>

    <script>
        let activeSection = null;
        let sectionStates = {};

        // Theme toggle functionality
        function toggleTheme() {
            const html = document.documentElement;
            const currentTheme = html.getAttribute('data-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            html.setAttribute('data-theme', newTheme);
            
            // Save preference
            localStorage.setItem('theme', newTheme);
            
            console.log('Switched to theme:', newTheme);
        }

        // Initialize theme from localStorage or system preference
        function initTheme() {
            const savedTheme = localStorage.getItem('theme');
            if (savedTheme) {
                document.documentElement.setAttribute('data-theme', savedTheme);
            } else if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) {
                document.documentElement.setAttribute('data-theme', 'light');
            }
        }

        // Initialize section state
        function initSection(section) {
            if (!sectionStates[section]) {
                sectionStates[section] = {
                    page: 1,
                    loaded: false
                };
            }
        }

        // Toggle section visibility
        function toggleSection(section) {
            const sectionEl = document.getElementById(section);
            const isActive = sectionEl.classList.contains('active');
            
            // Hide all sections
            document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
            
            if (!isActive) {
                sectionEl.classList.add('active');
                activeSection = section;
                initSection(section);
                
                if (!sectionStates[section].loaded) {
                    loadSection(section);
                }
            } else {
                activeSection = null;
            }
        }

        // Load section content
        function loadSection(section) {
            const data = window.sectionData[section];
            if (!data) {
                console.error('No data found for section:', section);
                return;
            }

            const grid = document.getElementById(`${section}-grid`);
            const loading = document.getElementById(`${section}-loading`);
            const pagination = document.getElementById(`${section}-pagination`);
            
            const images = data.dark || [];
            
            if (images.length === 0) {
                grid.innerHTML = '<div style="text-align: center; padding: 40px; color: var(--fg-subtle);">No images found</div>';
                loading.classList.add('hidden');
                grid.classList.remove('hidden');
                pagination.classList.add('hidden');
                return;
            }
            
            const itemsPerPage = data.maxPerPage;
            const totalPages = Math.ceil(images.length / itemsPerPage);
            const currentPage = sectionStates[section].page;
            
            // Generate image grid with exactly 2 columns layout
            const startIdx = (currentPage - 1) * itemsPerPage;
            const endIdx = Math.min(startIdx + itemsPerPage, images.length);
            const pageImages = images.slice(startIdx, endIdx);
            
            grid.innerHTML = pageImages.map(img => `
                <div class="image-item">
                    <img src="${img.thumb}" alt="${img.alt}" loading="lazy" 
                         onerror="this.parentNode.style.display='none'">
                    <div class="image-overlay">
                        <div class="image-title">${img.title}</div>
                        <div class="image-author">by kurzgesagt</div>
                    </div>
                    <button class="download-btn" onclick="window.open('${img.src}', '_blank')" title="Download">↓</button>
                </div>
            `).join('');
            
            // Generate pagination
            if (totalPages > 1) {
                pagination.innerHTML = Array.from({length: totalPages}, (_, i) => {
                    const page = i + 1;
                    const active = page === currentPage ? ' active' : '';
                    return `<button class="${active}" onclick="goToPage('${section}', ${page})">${page}</button>`;
                }).join('');
                pagination.classList.remove('hidden');
            } else {
                pagination.classList.add('hidden');
            }
            
            loading.classList.add('hidden');
            grid.classList.remove('hidden');
            sectionStates[section].loaded = true;
        }

        // Go to specific page
        function goToPage(section, page) {
            if (!sectionStates[section]) return;
            sectionStates[section].page = page;
            loadSection(section);
        }
        
        function downloadImage(filename) {
            console.log('Downloading:', filename);
            // This would trigger the actual download in a real implementation
        }
        
        // Initialize everything
        document.addEventListener('DOMContentLoaded', () => {
            initTheme();
            
            // Auto-open first section if available
            const firstSection = Object.keys(window.sectionData || {})[0];
            if (firstSection) {
                setTimeout(() => toggleSection(firstSection), 100);
            }
        });

        // Listen for system theme changes
        if (window.matchMedia) {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                if (!localStorage.getItem('theme')) {
                    document.documentElement.setAttribute('data-theme', e.matches ? 'dark' : 'light');
                }
            });
        }
    </script>
EOF

  # Add section data scripts
  for section in "${sections[@]}"; do
    echo "    <script src=\"${section}_data.js\"></script>" >> index.html
  done

  echo "</body>" >> index.html
  echo "</html>" >> index.html
  
  echo "HTML structure created with $sections_created sections"
}

# Main build process
echo "Cleaning up old files..."
rm -f *.html *_data.js

echo "🔍 Checking for wallpapers..."
if [ ! -d "./wallpapers" ]; then
  echo "./wallpapers directory not found!"
  echo "Please create the wallpapers directory and add your images"
  exit 1
fi

generate_thumbnails

# Generate sections data
declare -a sections
sections_created=0

for subdir in ./wallpapers/*; do
  [ -d "$subdir" ] || continue
  section="${subdir##*/}"
  sections+=("$section")
  
  create_section_data "$section" "$subdir"
  sections_created=$((sections_created + 1))
done

if [ "$sections_created" -eq 0 ]; then
  echo "No sections created! No wallpapers in ./wallpapers/ subdirectories"
  exit 1
fi

# Create the main HTML file
create_main_html

echo ""
echo "Wallpaper Gallery Build Complete!"
echo "Created $sections_created sections: ${sections[*]}"

echo ""
echo "Generated Files:"
echo "  - index.html (main gallery page with GitHub button & theme toggle)"
echo "  - thumbnails/ (compressed images)"
for section in "${sections[@]}"; do
  echo "  - ${section}_data.js (image data)"
done

echo "Done"

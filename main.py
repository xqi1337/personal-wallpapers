from email.mime import image
import os

# Automatisch alle Ordner im aktuellen Verzeichnis finden
image_folders = []
for item in os.listdir("."):
    if os.path.isdir(item) and not item.startswith("."):  # Versteckte Ordner ausschließen
        image_folders.append(item)

image_folders.sort()
print(image_folders)

pre = """# welcome to my personal wallpapers

A curated list of awesome wallpapers related to anime, comics, games & more.

Sharing, suggestions and contributions are always welcome!

## previews
Categorized wallpaper previews. two pictures per category.

<hr>
<p align="center">

"""

post = """
## Sources

Following are roughly the sources from where I scraped these images from.

- <https://www.pixiv.net/en/>
- <https://wallpapercave.com/>
- <https://www.freepik.com/>
- <https://in.pinterest.com/>
- <https://pixabay.com/>
- <https://unsplash.com/>
- <https://wallhaven.cc/>
- <https://wallhere.com/>
- <https://deviantart.com/>
- <https://artstation.com/>
- <https://reddit.com/r/kustom/>
- <https://www.reddit.com/r/WallpaperRequests/>
- <https://www.reddit.com/r/wallpaperdump/>
- <https://www.reddit.com/r/wallpaper/>
- <https://www.reddit.com/r/Verticalwallpapers/>
- <https://www.reddit.com/r/unixporn/>
- <https://www.reddit.com/r/Rainmeter/>
- <https://www.reddit.com/r/nordtheme/>
- <https://www.reddit.com/r/manga/>
- <https://www.reddit.com/r/chillhop/>
- <https://www.reddit.com/r/awesomewm/>
- <https://www.reddit.com/r/AnimeWallpaperGif/>
- <https://www.reddit.com/r/Animewallpaper/>
- <https://www.reddit.com/r/animegifs/>
- <https://www.pxfuel.com/>
- <https://de.vecteezy.com/>
- <https://stock.adobe.com/de/search>
- <https://www.deviantart.com/>
- <https://www.wallpaperflare.com/>
- <https://www.reddit.com/r/kurzgesagt/comments/15pvf7h/kurzgesagt_4k_wallpapers_3840x2160/>
- <https://imgur.com/gallery/SELjK>
- <https://42willow.github.io/wallpapers/>

## Tools

- <https://farbenfroh.io/>
- <https://github.com/lighttigerXIV/catppuccinifier>
- <https://www.tineye.com/>
- <https://github.com/nekowinston/faerber>
- <https://github.com/ozwaldorf/lutgen-rs)>
- <https://github.com/Astropulse/pixeldetector>

## Ending Note

You may use [download-directory](https://download-directory.github.io) for downloading a specific directory.
</p>


<p align="center">
	<img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/footers/gray0_ctp_on_line.svg?sanitize=true" />
</p>

"""

# readme
with open("./readme.md", "w") as f:
    f.write(pre)


def image_embed_main(title, folder, img):
    return f"""<a href="./{folder}/{img}"><img alt="{title}" src="./{folder}/{img}"></a><br/><br/>\n\n"""


def image_embed_category(title, img):
    return f"""<a href="{img}"><img alt="{title}" src="{img}"></a>\n\n"""


def get_image_files(folder):
    """sort all"""
    image_files = []
    try:
        for file in os.listdir(folder):
            if file.endswith((".jpg", ".jpeg", ".png", ".gif", ".webp", ".webm", ".mp4")):
                image_files.append(file)
    except PermissionError:
        pass
    return sorted(image_files)


# Mainreadme
with open("./readme.md", "a") as readme:
    for folder in image_folders:
        image_files = get_image_files(folder)

        if image_files:
            readme.write(f"\n## {folder}\n\n")

            # max 2
            for i, file in enumerate(image_files[:2]):
                title = file[:-4]
                readme.write(image_embed_main(title, folder, file))

            readme.write(f"[Browse](./{folder}/README.md)\n\n")

            # Separates README für jeden Ordner erstellen
            category_readme_path = os.path.join(folder, "README.md")
            with open(category_readme_path, "w") as category_readme:
                category_readme.write(f"# {folder}\n\n")

                for file in image_files:
                    title = file[:-4]
                    category_readme.write(image_embed_category(title, file))

    readme.write(post)

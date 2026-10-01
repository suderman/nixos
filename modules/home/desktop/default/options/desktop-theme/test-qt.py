"""Check prepared Qt configuration without launching a GUI."""

import configparser
import re
import sys
from pathlib import Path

assets = Path(sys.argv[1])
previous = None
for mode in ["dark", "light"]:
    qt = assets / mode / "qt"
    for version in [5, 6]:
        settings = configparser.ConfigParser()
        settings.read(qt / f"qt{version}ct.conf")
        appearance = settings["Appearance"]
        assert appearance["style"] == "kvantum"
        assert appearance.getboolean("custom_palette")
        assert appearance["icon_theme"]
        assert settings["Fonts"]["fixed"] and settings["Fonts"]["general"]
        palette = configparser.ConfigParser()
        palette.read(appearance["color_scheme_path"])
        for group in ["active_colors", "inactive_colors", "disabled_colors"]:
            colors = palette["ColorScheme"][group].split(", ")
            assert len(colors) == 21
            assert all(re.fullmatch(r"#[0-9a-fA-F]{6}", color) for color in colors)
        if version == 5:
            current = palette["ColorScheme"]["active_colors"]
            assert current != previous
            previous = current
    selector = configparser.ConfigParser()
    selector.read(qt / "kvantum.kvconfig")
    assert selector["General"]["theme"] == f"Desktop-{mode}"
    theme = qt / "Kvantum" / f"Desktop-{mode}"
    config = theme / f"Desktop-{mode}.kvconfig"
    svg = theme / f"Desktop-{mode}.svg"
    assert "{{" not in config.read_text() and "{{" not in svg.read_text()
    assert "<svg" in svg.read_text() and "</svg>" in svg.read_text()
print("Qt5/Qt6 palettes, fonts, icons and rendered Kvantum themes: passed")

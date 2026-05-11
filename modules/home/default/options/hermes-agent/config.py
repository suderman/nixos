import os
import sys
import tempfile
import yaml


def load_yaml(path: str) -> dict:
    if not os.path.exists(path):
        return {}

    with open(path, "r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)

    if data is None:
        return {}
    if not isinstance(data, dict):
        raise TypeError(f"{path} must contain a YAML mapping")
    return data


def merge(base, override):
    result = dict(base)
    for key, value in override.items():
        if isinstance(result.get(key), dict) and isinstance(value, dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = value
    return result


def write_yaml(path: str, data: dict) -> None:
    parent = os.path.dirname(path) or "."
    fd, tmp_path = tempfile.mkstemp(prefix=f"{os.path.basename(path)}.tmp.", dir=parent)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        yaml.safe_dump(
            data,
            fh,
            default_flow_style=False,
            sort_keys=False,
            allow_unicode=True,
            width=1000,
        )
    os.replace(tmp_path, path)


def replace_mode(target: str, layer_path: str) -> int:
    backup = f"{target}.bak"
    parent = os.path.dirname(target) or "."
    os.makedirs(parent, exist_ok=True)

    base = load_yaml(target)
    layer = load_yaml(layer_path)
    merged = merge(base, layer)

    if os.path.exists(target):
        os.replace(target, backup)

    write_yaml(target, merged)
    return 0


def fill_mode(target: str, defaults_path: str) -> int:
    parent = os.path.dirname(target) or "."
    os.makedirs(parent, exist_ok=True)

    existing = load_yaml(target)
    defaults = load_yaml(defaults_path)
    merged = merge(defaults, existing)
    write_yaml(target, merged)
    return 0


def main() -> int:
    mode, target, layer_path = sys.argv[1:4]
    if mode == "replace":
        return replace_mode(target, layer_path)
    if mode == "fill":
        return fill_mode(target, layer_path)
    raise ValueError(f"unknown mode: {mode}")


if __name__ == "__main__":
    raise SystemExit(main())

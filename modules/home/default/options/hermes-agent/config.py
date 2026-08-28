import os
import shutil
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


def merge(base, override, top_level=False):
    result = dict(base)
    for key, value in override.items():
        if top_level and key in {"model", "fallback_providers", "auxiliary"}:
            result[key] = value
        elif isinstance(result.get(key), dict) and isinstance(value, dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = value
    return result


def write_yaml(path: str, data: dict) -> None:
    parent = os.path.dirname(path) or "."
    fd, tmp_path = tempfile.mkstemp(prefix=f"{os.path.basename(path)}.tmp.", dir=parent)
    try:
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
    except Exception:
        try:
            os.unlink(tmp_path)
        except FileNotFoundError:
            pass
        raise


def replace_mode(target: str, layer_path: str) -> int:
    backup = f"{target}.bak"
    parent = os.path.dirname(target) or "."
    os.makedirs(parent, exist_ok=True)

    base = load_yaml(target)
    layer = load_yaml(layer_path)
    merged = merge(base, layer, top_level=True)

    if os.path.exists(target):
        shutil.copy2(target, backup)

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
    if sys.argv[1:] == ["--self-test"]:
        with tempfile.TemporaryDirectory() as directory:
            target = os.path.join(directory, "config.yaml")
            layer = os.path.join(directory, "layer.yaml")
            with open(target, "w", encoding="utf-8") as fh:
                yaml.safe_dump({"model": {"default": "old"}, "runtime": True}, fh)
            with open(layer, "w", encoding="utf-8") as fh:
                yaml.safe_dump({"model": {"default": "new"}}, fh)
            replace_mode(target, layer)
            assert load_yaml(target) == {"model": {"default": "new"}, "runtime": True}
            assert load_yaml(f"{target}.bak") == {
                "model": {"default": "old"},
                "runtime": True,
            }
        print("self-test passed")
        return 0

    mode, target, layer_path = sys.argv[1:4]
    if mode == "replace":
        return replace_mode(target, layer_path)
    if mode == "fill":
        return fill_mode(target, layer_path)
    raise ValueError(f"unknown mode: {mode}")


if __name__ == "__main__":
    raise SystemExit(main())

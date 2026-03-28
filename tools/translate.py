#!/usr/bin/env python3
"""
translate_arb_with_translategemma.py

Translates ARB/JSON localization files using TranslateGemma via Ollama.
Preserves placeholders like {deviceName} and ICU plural/select formats.

Usage:
  # Translate all strings:
  python translate.py --in lib/l10n/app_en.arb --out lib/l10n/app_es.arb --to-locale es

  # Translate only missing strings:
  python translate.py --in lib/l10n/app_en.arb --out lib/l10n/app_es.arb --to-locale es --missing-only

  # Translate all locales (missing strings only):
  python translate.py --in lib/l10n/app_en.arb --l10n-dir lib/l10n --missing-only

  # New locales copied from app_en.arb still match English → --missing-only skips them.
  # Translate every key that still equals the template (e.g. hu, ja, ko):
  python translate.py --in lib/l10n/app_en.arb --l10n-dir lib/l10n --copy-of-template --only-locales hu,ja,ko
"""

import argparse
import json
import os
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from typing import Any, Dict, List, Tuple, Optional
from urllib import request


# Placeholder patterns
SIMPLE_PLACEHOLDER_RE = re.compile(r"\{(\w+)\}")
ICU_VAR_RE = re.compile(r"\{(\w+)\s*,\s*(?:plural|select|selectordinal)\s*,", re.IGNORECASE)


@dataclass
class OllamaConfig:
    host: str
    model: str
    timeout_s: float
    temperature: float


# Language mapping (locale_code -> (language_name, translategemma_code))
LOCALE_MAP = {
    "es": ("Spanish", "es"),
    "fr": ("French", "fr"),
    "de": ("German", "de"),
    "it": ("Italian", "it"),
    "pt": ("Portuguese", "pt"),
    "pt-BR": ("Brazilian Portuguese", "pt"),
    "ja": ("Japanese", "ja"),
    "ko": ("Korean", "ko"),
    "zh": ("Chinese", "zh-Hans"),
    "zh-Hant": ("Chinese", "zh-Hant"),
    "ru": ("Russian", "ru"),
    "uk": ("Ukrainian", "uk"),
    "ar": ("Arabic", "ar"),
    "hi": ("Hindi", "hi"),
    "tr": ("Turkish", "tr"),
    "nl": ("Dutch", "nl"),
    "sv": ("Swedish", "sv"),
    "no": ("Norwegian", "no"),
    "da": ("Danish", "da"),
    "fi": ("Finnish", "fi"),
    "pl": ("Polish", "pl"),
    "cs": ("Czech", "cs"),
    "sk": ("Slovak", "sk"),
    "sl": ("Slovenian", "sl"),
    "bg": ("Bulgarian", "bg"),
    "hu": ("Hungarian", "hu"),
    "el": ("Greek", "el"),
    "he": ("Hebrew", "he"),
    "th": ("Thai", "th"),
    "vi": ("Vietnamese", "vi"),
    "id": ("Indonesian", "id"),
}

# Keys to skip translation
SKIP_KEYS = {"appTitle"}

# Manual translations for complex strings
MANUAL_TRANSLATIONS: Dict[str, Dict[str, str]] = {
    "repeater_daysHoursMinsSecs": {
        "es": "{days} días {hours}h {minutes}m {seconds}s",
        "fr": "{days} jours {hours}h {minutes}m {seconds}s",
        "de": "{days} Tage {hours}h {minutes}m {seconds}s",
        "it": "{days} giorni {hours}h {minutes}m {seconds}s",
        "pt": "{days} dias {hours}h {minutes}m {seconds}s",
        "pl": "{days} dni {hours}h {minutes}m {seconds}s",
        "sk": "{days} dní {hours}h {minutes}m {seconds}s",
        "sl": "{days} dni {hours}h {minutes}m {seconds}s",
        "cs": "{days} dní {hours}h {minutes}m {seconds}s",
        "ja": "{days}日 {hours}時間 {minutes}分 {seconds}秒",
        "ko": "{days}일 {hours}시간 {minutes}분 {seconds}초",
        "zh": "{days}天 {hours}小时 {minutes}分 {seconds}秒",
        "ru": "{days} дней {hours}ч {minutes}м {seconds}с",
        "bg": "{days} дни {hours}ч {minutes}м {seconds}с",
        "nl": "{days} dagen {hours}u {minutes}m {seconds}s",
        "sv": "{days} dagar {hours}t {minutes}m {seconds}s",
    },
}


def http_post_json(url: str, payload: Dict[str, Any], timeout_s: float) -> Dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
    with request.urlopen(req, timeout=timeout_s) as resp:
        return json.loads(resp.read().decode("utf-8"))


def ollama_generate(cfg: OllamaConfig, prompt: str) -> str:
    url = cfg.host.rstrip("/") + "/api/generate"
    payload = {
        "model": cfg.model,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": cfg.temperature},
    }
    resp = http_post_json(url, payload, cfg.timeout_s)
    return resp.get("response", "").strip()


def extract_placeholder_names(s: str) -> List[str]:
    """Extract placeholder variable names from string."""
    names = set()

    # Get ICU variable names
    for m in ICU_VAR_RE.finditer(s):
        names.add(m.group(1))

    # Get simple placeholders (excluding ICU text forms)
    for m in SIMPLE_PLACEHOLDER_RE.finditer(s):
        name = m.group(1)
        pos = m.start()
        rest = s[pos:]

        # Skip if this is part of an ICU block
        if re.match(r"\{\w+\s*,\s*(?:plural|select|selectordinal)", rest, re.IGNORECASE):
            continue

        # Skip if this is a text form inside ICU (preceded by =X{ or other{)
        before = s[:pos]
        if re.search(r"(?:=\d+|zero|one|two|few|many|other)\s*$", before, re.IGNORECASE):
            continue

        names.add(name)

    return sorted(names)


def has_icu_block(s: str) -> bool:
    """Check if string contains ICU plural/select block."""
    return bool(ICU_VAR_RE.search(s))


def build_prompt(text: str, target_lang: str, target_code: str, placeholder_names: List[str], has_icu: bool) -> str:
    """Build TranslateGemma-compatible prompt with placeholder preservation instructions."""
    # Build instructions for placeholder preservation
    instructions = []
    if placeholder_names:
        placeholders = ', '.join(f'{{{t}}}' for t in placeholder_names)
        instructions.append(f"CRITICAL: Keep these placeholders EXACTLY as they appear: {placeholders}")
    if has_icu:
        instructions.append("CRITICAL: Preserve ICU message format structure (plural, select, =0, =1, other, etc.). Only translate the text inside the forms.")

    # Add instructions to the system prompt, not to the text itself
    instruction_text = "\n".join(instructions) if instructions else ""
    separator = "\n" if instruction_text else ""

    # TranslateGemma expects this exact format (note the two blank lines before text)
    return f"""You are a professional English (en) to {target_lang} ({target_code}) translator. Your goal is to accurately convey the meaning and nuances of the original English text while adhering to {target_lang} grammar, vocabulary, and cultural sensitivities.
Produce only the {target_lang} translation, without any additional explanations or commentary.{separator}{instruction_text}
Please translate the following English text into {target_lang}:


{text}"""


def validate_preserved_tokens(src: str, out: str) -> Tuple[bool, Optional[str]]:
    """Validate that placeholder names are preserved."""
    src_names = extract_placeholder_names(src)

    for name in src_names:
        pattern = r"\{" + re.escape(name) + r"(?:\}|\s*,)"
        if not re.search(pattern, out):
            return False, f"Missing placeholder: {{{name}}}"

    if has_icu_block(src) and not has_icu_block(out):
        return False, "ICU plural/select block missing"

    return True, None


def translate_one(
    key: str,
    text: str,
    target_lang: str,
    target_code: str,
    cfg: OllamaConfig,
    retries: int,
    backoff_s: float,
    fallback_cfg: Optional[OllamaConfig] = None,
) -> Tuple[str, str, Optional[str], bool]:
    """Translate a single string. Returns (key, translated_text, error_or_none, used_fallback)."""
    placeholder_names = extract_placeholder_names(text)
    text_has_icu = has_icu_block(text)
    prompt = build_prompt(text, target_lang, target_code, placeholder_names, text_has_icu)

    last_err: Optional[str] = None
    for attempt in range(retries + 1):
        try:
            out = ollama_generate(cfg, prompt)

            # Validate placeholders
            ok, why = validate_preserved_tokens(text, out)
            if not ok:
                last_err = f"Validation failed: {why}"
                if attempt < retries:
                    time.sleep(backoff_s * (attempt + 1))
                    continue
                raise ValueError(last_err)

            return key, out, None, False

        except Exception as e:
            last_err = str(e)
            if attempt < retries:
                time.sleep(backoff_s * (attempt + 1))
                continue

    # Try fallback model if available
    if fallback_cfg:
        try:
            fallback_prompt = build_prompt(text, target_lang, target_code, placeholder_names, text_has_icu)
            fallback_out = ollama_generate(fallback_cfg, fallback_prompt)
            fallback_ok, _ = validate_preserved_tokens(text, fallback_out)
            if fallback_ok:
                return key, fallback_out, None, True
        except Exception:
            pass

    # Fallback to original
    return key, text, last_err, False


def is_translatable_entry(key: str, value: Any) -> bool:
    """Check if an entry should be translated."""
    if key == "@@locale" or key.startswith("@") or key in SKIP_KEYS:
        return False
    return isinstance(value, str) and value.strip() != ""


def find_missing_keys(source_data: Dict[str, Any], target_data: Dict[str, Any]) -> List[str]:
    """Find keys that are missing or empty in target."""
    missing = []
    for key in source_data:
        if key == "@@locale" or key.startswith("@"):
            continue
        if key not in target_data or (isinstance(target_data.get(key), str) and target_data[key].strip() == ""):
            missing.append(key)
    return missing


def find_keys_still_template_copy(source_data: Dict[str, Any], target_data: Dict[str, Any]) -> List[str]:
    """Keys whose value is still exactly the same as the template (typical after cp app_en.arb → app_xx.arb)."""
    out: List[str] = []
    for key in source_data:
        if key == "@@locale" or key.startswith("@"):
            continue
        src = source_data.get(key)
        if not is_translatable_entry(key, src):
            continue
        if not isinstance(src, str):
            continue
        tgt = target_data.get(key)
        if not isinstance(tgt, str) or tgt.strip() == "":
            out.append(key)
        elif tgt == src:
            out.append(key)
    return out


def get_all_locale_files(l10n_dir: str, template_file: str) -> List[Tuple[str, str]]:
    """Find all locale .arb files excluding template. Returns [(locale_code, file_path)]."""
    locales = []
    template_basename = os.path.basename(template_file)

    for filename in os.listdir(l10n_dir):
        if filename.endswith('.arb') and filename != template_basename:
            if filename.startswith('app_'):
                locale = filename[4:-4]  # app_es.arb -> es
                locales.append((locale, os.path.join(l10n_dir, filename)))

    return sorted(locales)


def fmt_duration(seconds: float) -> str:
    """Format duration as human-readable string."""
    if seconds < 60:
        return f"{seconds:.1f}s"
    m = int(seconds // 60)
    s = seconds - 60 * m
    if m < 60:
        return f"{m}m {s:.0f}s"
    h = m // 60
    m2 = m % 60
    return f"{h}h {m2}m"


def translate_locale(
    source_data: Dict[str, Any],
    target_data: Dict[str, Any],
    target_locale: str,
    target_lang: str,
    target_code: str,
    out_path: str,
    args,
    missing_keys: Optional[List[str]] = None,
) -> int:
    """Translate a single locale. Returns number of strings translated."""

    cfg = OllamaConfig(
        host=args.host,
        model=args.model,
        timeout_s=args.timeout,
        temperature=args.temperature,
    )

    fallback_cfg = None
    if args.fallback_model:
        fallback_cfg = OllamaConfig(
            host=args.host,
            model=args.fallback_model,
            timeout_s=args.timeout,
            temperature=args.temperature,
        )

    # Start with target data or source data
    out_data: Dict[str, Any] = dict(target_data) if target_data else dict(source_data)
    out_data["@@locale"] = target_locale

    # Build list of items to translate
    if missing_keys is not None:
        items: List[Tuple[str, str]] = [
            (k, source_data[k]) for k in missing_keys
            if is_translatable_entry(k, source_data.get(k))
        ]
        # Copy metadata for missing items
        for key in missing_keys:
            meta_key = f"@{key}"
            if meta_key in source_data:
                out_data[meta_key] = source_data[meta_key]
    else:
        items: List[Tuple[str, str]] = [(k, v) for k, v in source_data.items() if is_translatable_entry(k, v)]

    # Apply manual translations
    manual_count = 0
    items_to_translate: List[Tuple[str, str]] = []
    for k, v in items:
        if k in MANUAL_TRANSLATIONS and target_locale in MANUAL_TRANSLATIONS[k]:
            out_data[k] = MANUAL_TRANSLATIONS[k][target_locale]
            manual_count += 1
        else:
            items_to_translate.append((k, v))

    if manual_count > 0:
        print(f"Applied {manual_count} manual translation(s)")

    total = len(items_to_translate)
    if total == 0:
        if manual_count > 0:
            print("All strings handled by manual translations.")
        return manual_count

    fallback_info = f" (fallback: {args.fallback_model})" if args.fallback_model else ""
    print(f"Translating {total} strings -> {target_lang} using {cfg.model}{fallback_info} (concurrency={args.concurrency})")

    start = time.time()
    failures: List[Tuple[str, str]] = []
    translated_ok = manual_count
    fallback_used = 0
    completed = 0

    with ThreadPoolExecutor(max_workers=max(1, args.concurrency)) as ex:
        future_to_key = {
            ex.submit(
                translate_one,
                key=k,
                text=v,
                target_lang=target_lang,
                target_code=target_code,
                cfg=cfg,
                retries=args.retries,
                backoff_s=args.backoff,
                fallback_cfg=fallback_cfg,
            ): k
            for (k, v) in items_to_translate
        }

        for fut in as_completed(future_to_key):
            k, translated, err, used_fallback = fut.result()
            out_data[k] = translated

            completed += 1
            if err:
                failures.append((k, err))
                status = "FAIL"
            else:
                translated_ok += 1
                if used_fallback:
                    fallback_used += 1
                    status = "OK*"
                else:
                    status = "OK"

            if completed % args.progress_every == 0 or completed == total:
                elapsed = time.time() - start
                rate = completed / elapsed if elapsed > 0 else 0.0
                remaining = (total - completed) / rate if rate > 0 else 0.0
                print(f"[{completed:>4}/{total}] {status:<4} {k} | elapsed {fmt_duration(elapsed)} | ETA {fmt_duration(remaining)}")

    elapsed = time.time() - start
    fallback_msg = f", fallback_used={fallback_used}" if fallback_used > 0 else ""
    print(f"Done in {fmt_duration(elapsed)}. OK={translated_ok}{fallback_msg}, errors={len(failures)}")

    if failures:
        print(f"{len(failures)} translation(s) kept original English:")
        for k, err in failures[:20]:
            print(f" - {k}: {err}")
        if len(failures) > 20:
            print(f" ... and {len(failures) - 20} more")

    if args.dry_run:
        print("Dry run: not writing output file.")
        return translated_ok

    try:
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(out_data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    except Exception as e:
        print(f"Failed to write output: {e}", file=sys.stderr)
        return -1

    print(f"Wrote: {out_path}")
    return translated_ok


def main() -> int:
    ap = argparse.ArgumentParser(description="Translate ARB files using TranslateGemma")
    ap.add_argument("--in", dest="in_path", required=True, help="Input .arb file (source/template)")
    ap.add_argument("--out", dest="out_path", help="Output .arb file (required unless using --l10n-dir)")
    ap.add_argument("--to-locale", help="Target locale code (es, fr, de, etc.)")
    ap.add_argument("--l10n-dir", help="Directory with locale files (translates all locales)")
    ap.add_argument("--missing-only", action="store_true", help="Only translate missing keys")
    ap.add_argument(
        "--copy-of-template",
        action="store_true",
        help="Only translate keys whose target text still equals app_en (use for new locales copied from English)",
    )
    ap.add_argument(
        "--only-locales",
        help="Comma-separated locale codes to process with --l10n-dir (e.g. hu,ja,ko)",
    )
    ap.add_argument("--model", default="translategemma:latest", help="Ollama model (translategemma:latest or specific versions)")
    ap.add_argument("--fallback-model", help="Fallback model for failed translations (e.g., translategemma:27b)")
    ap.add_argument("--host", default="http://localhost:11434", help="Ollama host")
    ap.add_argument("--timeout", type=float, default=120.0, help="HTTP timeout seconds")
    ap.add_argument("--temperature", type=float, default=0.0, help="Model temperature (0.0 for deterministic)")
    ap.add_argument("--concurrency", type=int, default=4, help="Parallel requests")
    ap.add_argument("--retries", type=int, default=2, help="Retries per string")
    ap.add_argument("--backoff", type=float, default=0.6, help="Backoff seconds base")
    ap.add_argument("--dry-run", action="store_true", help="Don't write output")
    ap.add_argument("--progress-every", type=int, default=1, help="Print progress every N strings")
    args = ap.parse_args()

    # Read source file
    try:
        with open(args.in_path, "r", encoding="utf-8") as f:
            source_data = json.load(f)
    except Exception as e:
        print(f"Failed to read input: {e}", file=sys.stderr)
        return 2

    if not isinstance(source_data, dict):
        print("Input JSON must be an object at top-level.", file=sys.stderr)
        return 2

    if args.missing_only and args.copy_of_template:
        print("Use only one of --missing-only or --copy-of-template", file=sys.stderr)
        return 2

    only_locales: Optional[set] = None
    if args.only_locales:
        only_locales = {x.strip() for x in args.only_locales.split(",") if x.strip()}

    # Process all locales if --l10n-dir is provided
    if args.l10n_dir:
        locales = get_all_locale_files(args.l10n_dir, args.in_path)
        if not locales:
            print(f"No locale files found in {args.l10n_dir}", file=sys.stderr)
            return 1

        if only_locales is not None:
            locales = [(c, p) for c, p in locales if c in only_locales]
            missing = only_locales - {c for c, _ in locales}
            if missing:
                print(f"Warning: no app_*.arb for locale code(s): {', '.join(sorted(missing))}", file=sys.stderr)

        print(f"Found {len(locales)} locale file(s) to process")

        total_translated = 0
        for locale_code, locale_path in locales:
            lang_name, lang_code = LOCALE_MAP.get(locale_code, (locale_code, locale_code))

            try:
                with open(locale_path, "r", encoding="utf-8") as f:
                    target_data = json.load(f)
            except Exception as e:
                print(f"  [{locale_code}] Failed to read {locale_path}: {e}")
                continue

            missing_keys: Optional[List[str]]
            if args.copy_of_template:
                missing_keys = find_keys_still_template_copy(source_data, target_data)
                if not missing_keys:
                    print(f"  [{locale_code}] No keys still matching template")
                    continue
                print(f"  [{locale_code}] {len(missing_keys)} key(s) still same as template")
            elif args.missing_only:
                missing_keys = find_missing_keys(source_data, target_data)
                if not missing_keys:
                    print(f"  [{locale_code}] No missing keys")
                    continue
                print(f"  [{locale_code}] {len(missing_keys)} missing key(s)")
            else:
                missing_keys = None

            result = translate_locale(
                source_data=source_data,
                target_data=target_data,
                target_locale=locale_code,
                target_lang=lang_name,
                target_code=lang_code,
                out_path=locale_path,
                args=args,
                missing_keys=missing_keys,
            )
            total_translated += result

        print(f"\nTotal: {total_translated} string(s) translated across {len(locales)} locale(s)")
        return 0

    # Single locale mode
    if not args.out_path or not args.to_locale:
        print("--out and --to-locale are required when not using --l10n-dir", file=sys.stderr)
        return 1

    lang_name, lang_code = LOCALE_MAP.get(args.to_locale, (args.to_locale, args.to_locale))

    # Read existing target file if --missing-only or --copy-of-template
    target_data: Dict[str, Any] = {}
    missing_keys: Optional[List[str]] = None
    if (args.missing_only or args.copy_of_template) and os.path.exists(args.out_path):
        try:
            with open(args.out_path, "r", encoding="utf-8") as f:
                target_data = json.load(f)
            if args.copy_of_template:
                missing_keys = find_keys_still_template_copy(source_data, target_data)
                label = "still matching template"
            else:
                missing_keys = find_missing_keys(source_data, target_data)
                label = "missing"
            if not missing_keys:
                print(f"No {label} keys in {args.out_path}")
                return 0
            print(f"Found {len(missing_keys)} {label} key(s) to translate")
        except Exception as e:
            print(f"Failed to read target file: {e}", file=sys.stderr)
            return 2

    result = translate_locale(
        source_data=source_data,
        target_data=target_data,
        target_locale=args.to_locale,
        target_lang=lang_name,
        target_code=lang_code,
        out_path=args.out_path,
        args=args,
        missing_keys=missing_keys,
    )
    return 0 if result >= 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())

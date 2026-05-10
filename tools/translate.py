#!/usr/bin/env python3
"""
translate_arb_with_ollama.py

Translates ARB/JSON localization values using a local Ollama model, while:
- preserving keys
- skipping "@@locale" and all "@key" metadata blocks
- preserving placeholders like {deviceName}, {count, plural, ...}
- writing a new file with updated @@locale
- printing progress as it runs

Usage:
  # Translate all strings:
  python translate.py \
    --in ../lib/l10n/app_en.arb \
    --out ../lib/l10n/app_es.arb \
    --to-locale es \
    --model ministral-3:latest \
    --temperature 0 \
    --concurrency 4

  # Translate only missing/untranslated strings:
  python translate.py \
    --in ../lib/l10n/app_en.arb \
    --out ../lib/l10n/app_es.arb \
    --to-locale es \
    --missing-only \
    --model ministral-3:latest

  # Translate all locales (missing strings only):
  python translate.py \
    --in ../lib/l10n/app_en.arb \
    --l10n-dir ../lib/l10n \
    --missing-only \
    --model ministral-3:latest

  # Translate using Groq (very fast):
    python translate.py \
    --in ../lib/l10n/app_en.arb 
    --l10n-dir ../lib/l10n \
    --missing-only \
    --backend groq --model llama-3.3-70b-versatile \
    --temperature 0.1 --concurrency 12

    # Translate using local OpenAI-compatible server (LM Studio/llama.cpp/vLLM):
    python translate.py \
        --in ../lib/l10n/app_en.arb \
        --l10n-dir ../lib/l10n \
        --missing-only \
        --backend openai \
        --openai-base-url http://localhost:1234/v1 \
        --model local-model-name
"""

from __future__ import annotations
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

try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

# Simple placeholder like {name}, {count}, {deviceName}
SIMPLE_PLACEHOLDER_RE = re.compile(r"\{(\w+)\}")
# ICU plural/select variable name extraction: {count, plural, ...} or {gender, select, ...}
ICU_VAR_RE = re.compile(r"\{(\w+)\s*,\s*(?:plural|select|selectordinal)\s*,", re.IGNORECASE)


@dataclass
class OllamaConfig:
    host: str
    model: str
    timeout_s: float
    temperature: float
    num_ctx: int
    num_predict: int
    top_p: float

@dataclass
class GroqConfig:
    client: Groq
    model: str
    temperature: float
    max_tokens: int          # Groq calls it max_tokens (not num_predict)
    top_p: float


@dataclass
class OpenAIConfig:
    client: OpenAI
    model: str
    temperature: float
    max_tokens: int
    top_p: float

def http_post_json(url: str, payload: Dict[str, Any], timeout_s: float) -> Dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with request.urlopen(req, timeout=timeout_s) as resp:
        body = resp.read().decode("utf-8")
        return json.loads(body)


def strip_markdown(s: str) -> str:
    """Remove common markdown formatting from output."""
    # Remove bold/italic markers
    s = re.sub(r'\*\*(.+?)\*\*', r'\1', s)
    s = re.sub(r'\*(.+?)\*', r'\1', s)
    s = re.sub(r'__(.+?)__', r'\1', s)
    s = re.sub(r'_(.+?)_', r'\1', s)
    # Remove stray asterisks
    s = re.sub(r'\*+', '', s)
    return s.strip()


def ollama_generate(cfg: OllamaConfig, prompt: str) -> str:
    url = cfg.host.rstrip("/") + "/api/generate"
    payload = {
        "model": cfg.model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": cfg.temperature,
            "num_ctx": cfg.num_ctx,
            "num_predict": cfg.num_predict,
            "top_p": cfg.top_p,
        },
    }
    resp = http_post_json(url, payload, cfg.timeout_s)
    out = resp.get("response", "")
    # Clean up common LLM artifacts
    out = strip_markdown(out)
    return out.strip()

def groq_generate(cfg: GroqConfig, prompt: str) -> str:
    try:
        response = cfg.client.chat.completions.create(
            model=cfg.model,
            messages=[
                {"role": "user", "content": prompt},
            ],
            temperature=cfg.temperature,
            max_tokens=cfg.max_tokens,
            top_p=cfg.top_p,
            stream=False,
        )
        out = response.choices[0].message.content or ""
        out = strip_markdown(out)
        return out.strip()

    except Exception as e:
        raise RuntimeError(f"Groq API error: {str(e)}") from e


def openai_generate(cfg: OpenAIConfig, prompt: str) -> str:
    def _call_openai(prompt_text: str, no_thinking: bool = False):
        kwargs = {
            "model": cfg.model,
            "messages": [
                {"role": "user", "content": prompt_text},
            ],
            "temperature": cfg.temperature,
            "max_tokens": cfg.max_tokens,
            "top_p": cfg.top_p,
            "stream": False,
        }
        # Local OpenAI-compatible servers (vLLM/llama.cpp/LM Studio) may support this.
        if no_thinking:
            kwargs["extra_body"] = {"chat_template_kwargs": {"enable_thinking": False}}
        return cfg.client.chat.completions.create(**kwargs)

    try:
        response = _call_openai(prompt)
        try:
            print(f"[openai-debug] response json:\n{response.model_dump_json(indent=2)}", file=sys.stderr)
        except Exception:
            print(f"[openai-debug] response object: {response}", file=sys.stderr)

        choice = response.choices[0]
        message = choice.message
        out = (message.content or "").strip()

        # Some reasoning models put everything in reasoning_content and leave content empty.
        if not out and getattr(message, "reasoning_content", None):
            print(
                "[openai-debug] Empty content with reasoning_content detected; retrying with no-thinking hint.",
                file=sys.stderr,
            )
            force_final_prompt = (
                prompt
                + "\n\nFINAL INSTRUCTION: Output ONLY the final translated string. "
                  "No analysis. No reasoning. No extra lines."
            )
            second_response = _call_openai(force_final_prompt, no_thinking=True)
            try:
                print(
                    f"[openai-debug] second response json:\n{second_response.model_dump_json(indent=2)}",
                    file=sys.stderr,
                )
            except Exception:
                print(f"[openai-debug] second response object: {second_response}", file=sys.stderr)
            out = (second_response.choices[0].message.content or "").strip()

        if not out:
            raise RuntimeError("OpenAI response content is empty")

        out = strip_markdown(out)
        return out.strip()
    except Exception as e:
        raise RuntimeError(f"OpenAI API error: {str(e)}") from e


def extract_placeholder_names(s: str) -> List[str]:
    """Extract placeholder variable names (not the full braced expression).

    For '{name}' returns ['name']
    For '{count} {count, plural, =1{hop} other{hops}}' returns ['count']
    """
    names = set()
    # Get ICU variable names first
    for m in ICU_VAR_RE.finditer(s):
        names.add(m.group(1))
    # Get simple placeholders, but skip if they're inside ICU blocks (text forms like {hop})
    # We do this by checking if the name is also an ICU variable - if not, it's a simple placeholder
    # unless it looks like a word (ICU text forms are usually short words)
    for m in SIMPLE_PLACEHOLDER_RE.finditer(s):
        name = m.group(1)
        # Check if this appears as a simple {name} placeholder (not inside ICU)
        # by looking at what comes after it
        full_match = m.group(0)
        pos = m.start()
        # Look for pattern like {name, plural/select - if found, skip (handled by ICU_VAR_RE)
        rest = s[pos:]
        if re.match(r"\{\w+\s*,\s*(?:plural|select|selectordinal)", rest, re.IGNORECASE):
            continue
        # Check if this is likely a text form inside ICU (preceded by =X{ or other{)
        before = s[:pos]
        if re.search(r"(?:=\d+|zero|one|two|few|many|other)\s*$", before, re.IGNORECASE):
            continue  # This is a text form like "=1{hop}", skip it
        names.add(name)
    return sorted(names)


def build_prompt(text: str, target_lang: str, placeholder_names: List[str], has_icu: bool, ask_confidence: bool = False) -> str:
    preserve_list = "\n".join(f"- {{{t}}}" for t in placeholder_names) if placeholder_names else "- (none)"
    
    icu_note = ""
    if has_icu:
        icu_note = (
            "ICU FORMAT RULES:\n"
            f"- This text uses ICU plural/select format: {{var, plural, =1{{singular}} other{{plural}}}}\n"
            "- Keep structure keywords EXACTLY: plural, select, =0, =1, =2, zero, one, two, few, many, other\n"
            f"- TRANSLATE the words inside each form to {target_lang}\n"
            "- Example: =1{item} other{items} -> translate 'item'/'items' but keep =1{{ }} other{{ }} structure\n\n"
        )
    
    if ask_confidence:
        return (
            f"Translate this UI string to {target_lang}.\n\n"
            "RULES:\n"
            "- Placeholders like {name}, {count} must appear EXACTLY unchanged.\n"
            "- Use infinitive verb forms for buttons (Save, Delete, etc.).\n"
            f"- Use natural {target_lang} word order.\n"
            "- Keep brand names and technical terms unchanged.\n\n"
            f"{icu_note}"
            f"Placeholders: {', '.join(f'{{{t}}}' for t in placeholder_names) if placeholder_names else 'none'}\n\n"
            f"English: {text}\n\n"
            "Respond with EXACTLY two lines:\n"
            "1. The translation (no quotes)\n"
            "2. Confidence score 1-5 (5=certain, 1=unsure)\n\n"
            "Example response:\n"
            "Guardar archivo\n"
            "5"
        )
    else:
        return (
            f"Translate this UI string to {target_lang}. Return ONLY the translation.\n\n"
            "RULES:\n"
            "- Output the translated text ONLY. No markdown, no quotes, no explanations.\n"
            "- Placeholders like {name}, {count} must appear EXACTLY unchanged.\n"
            "- Use infinitive verb forms for buttons (Save, Delete, etc.).\n"
            f"- Use natural {target_lang} word order.\n"
            "- Keep brand names and technical terms unchanged.\n"
            "- Translation length should be similar to the original.\n\n"
            f"{icu_note}"
            f"Placeholders: {', '.join(f'{{{t}}}' for t in placeholder_names) if placeholder_names else 'none'}\n\n"
            f"English: {text}\n"
            f"{target_lang}:"
        )


def parse_confidence_response(response: str) -> Tuple[str, int]:
    """Parse response with translation and confidence score.
    
    Returns (translation, confidence) where confidence is 1-5, or 0 if unparseable.
    """
    lines = response.strip().split('\n')
    if len(lines) >= 2:
        translation = '\n'.join(lines[:-1]).strip()  # All but last line
        try:
            # Try to extract number from last line
            last_line = lines[-1].strip()
            # Handle formats like "5", "5/5", "Confidence: 5"
            match = re.search(r'\b([1-5])\b', last_line)
            if match:
                confidence = int(match.group(1))
                return translation, confidence
        except ValueError:
            pass
    # Fallback: treat whole response as translation with unknown confidence
    return strip_markdown(response), 0


def looks_like_translation_failed(src: str, out: str) -> bool:
    if not out:
        return True
    if src.strip() == out.strip() and len(src.strip()) > 8:
        return True
    # Detect hallucination: output much longer than input (3x+ for short strings, 2x for longer)
    src_len = len(src.strip())
    out_len = len(out.strip())
    if src_len < 50 and out_len > src_len * 3:
        return True
    if src_len >= 50 and out_len > src_len * 2:
        return True
    return False


def has_icu_block(s: str) -> bool:
    """Check if string contains ICU plural/select block."""
    return bool(ICU_VAR_RE.search(s))


def validate_preserved_tokens(src: str, out: str) -> Tuple[bool, Optional[str]]:
    """Validate that placeholder names are preserved in translation."""
    src_names = extract_placeholder_names(src)
    
    # Check each placeholder name appears in output
    for name in src_names:
        # Look for {name} or {name, plural/select...}
        pattern = r"\{" + re.escape(name) + r"(?:\}|\s*,)"
        if not re.search(pattern, out):
            return False, f"Missing placeholder: {{{name}}}"
    
    # If source has ICU block, output should too
    if has_icu_block(src) and not has_icu_block(out):
        return False, "ICU plural/select block missing in output"
    
    return True, None


def compute_confidence(src: str, out: str) -> Tuple[float, List[str]]:
    """
    Compute confidence score (0.0 to 1.0) for a translation.
    Returns (score, list of issues).
    """
    issues = []
    score = 1.0
    
    src_len = len(src.strip())
    out_len = len(out.strip())
    
    # Length ratio check
    if src_len > 0:
        ratio = out_len / src_len
        if ratio < 0.3:  # Way too short
            score -= 0.4
            issues.append("too_short")
        elif ratio < 0.5:
            score -= 0.2
            issues.append("short")
        elif ratio > 2.5:  # Way too long
            score -= 0.4
            issues.append("too_long")
        elif ratio > 1.8:
            score -= 0.2
            issues.append("long")
    
    # Contains question mark when source doesn't (model asking questions)
    if '?' in out and '?' not in src:
        score -= 0.3
        issues.append("added_question")
    
    # Contains common LLM artifacts
    artifacts = ['```', '**', 'translation:', 'here is', 'certainly', 'i can', 'i\'ll']
    out_lower = out.lower()
    for artifact in artifacts:
        if artifact in out_lower:
            score -= 0.3
            issues.append(f"artifact:{artifact}")
            break
    
    # Output looks like it's in English still (common words)
    english_indicators = ['the ', ' is ', ' are ', ' was ', ' were ', ' have ', ' has ', 'you ', ' your ']
    english_count = sum(1 for ind in english_indicators if ind in out_lower)
    if english_count >= 3 and src_len > 20:
        score -= 0.3
        issues.append("likely_english")
    
    # Contains newlines when source doesn't
    if '\n' in out and '\n' not in src:
        score -= 0.2
        issues.append("added_newlines")
    
    # ICU/placeholder validation
    ok, _ = validate_preserved_tokens(src, out)
    if not ok:
        score -= 0.3
        issues.append("placeholder_error")
    
    return max(0.0, score), issues


# Keys to skip translation (brand names)
SKIP_KEYS = {
    "appTitle",
}

# Manual translations for problematic strings (key -> {locale: translation})
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


def is_translatable_entry(key: str, value: Any) -> bool:
    if key == "@@locale":
        return False
    if key in SKIP_KEYS:
        return False
    if key.startswith("@"):
        return False
    if not isinstance(value, str):
        return False
    if value.strip() == "":
        return False
    return True


def translate_one(
    key: str,
    text: str,
    target_lang: str,
    generate_fn,                # ← new: callable that takes config & prompt → str
    config,                     # ← either OllamaConfig or GroqConfig
    retries: int,
    backoff_s: float,
    fallback_generate_fn=None,
    fallback_config=None,
    confidence_threshold: float = 0.7,
    model_confidence_threshold: int = 4,
    ask_model_confidence: bool = True,
) -> Tuple[str, str, Optional[str], bool]:
    """
    Translate a single string.
    Returns (key, translated_text, error_or_none, used_fallback_model).
    """
    placeholder_names = extract_placeholder_names(text)
    text_has_icu = has_icu_block(text)
    
    # Ask for confidence if we have a fallback model
    should_ask_confidence = ask_model_confidence and fallback_config and fallback_config.model != config.model
    prompt = build_prompt(text, target_lang, placeholder_names, text_has_icu, ask_confidence=should_ask_confidence)
    used_fallback = False

    last_err: Optional[str] = None
    for attempt in range(retries + 1):
        try:
            raw_out = generate_fn(config, prompt)
            
            # Parse confidence if we asked for it
            if should_ask_confidence:
                out, model_confidence = parse_confidence_response(raw_out)
            else:
                out = raw_out
                model_confidence = 5  # Assume high confidence if not asked
            
            ok, why = validate_preserved_tokens(text, out)
            if not ok:
                last_err = f"Validation failed: {why}"
                # Retry without confidence format for simpler response
                prompt = build_prompt(text, target_lang, placeholder_names, text_has_icu, ask_confidence=False)
                prompt = (
                    prompt
                    + "\n\nIMPORTANT: You MUST keep every {...} segment exactly unchanged. "
                      "If you cannot, return the original text unchanged."
                )
                raise ValueError(last_err)

            if looks_like_translation_failed(text, out) and attempt < retries:
                last_err = "Output identical/suspicious; retrying"
                time.sleep(backoff_s * (attempt + 1))
                continue

            # Check if model reported low confidence - use fallback
            if model_confidence > 0 and model_confidence < model_confidence_threshold and fallback_config:
                fallback_prompt = build_prompt(text, target_lang, placeholder_names, text_has_icu, ask_confidence=False)
                fallback_out = generate_fn(fallback_config, fallback_prompt)
                fallback_ok, _ = validate_preserved_tokens(text, fallback_out)
                if fallback_ok and not looks_like_translation_failed(text, fallback_out):
                    return key, fallback_out, None, True

            # Also check computed confidence and use fallback model if needed
            confidence, issues = compute_confidence(text, out)
            if confidence < confidence_threshold and fallback_config and fallback_config.model != config.model:
                # Low confidence - try with bigger model
                fallback_prompt = build_prompt(text, target_lang, placeholder_names, text_has_icu)
                fallback_out = generate_fn(fallback_config, fallback_prompt)
                fallback_ok, _ = validate_preserved_tokens(text, fallback_out)
                fallback_conf, _ = compute_confidence(text, fallback_out)
                
                if fallback_ok and fallback_conf > confidence:
                    # Fallback is better
                    return key, fallback_out, None, True
                elif fallback_ok and not ok:
                    # Original failed validation but fallback passed
                    return key, fallback_out, None, True
            
            return key, out, None, used_fallback

        except Exception as e:
            last_err = str(e)
            if attempt < retries:
                time.sleep(backoff_s * (attempt + 1))
                continue

    # Last resort: try fallback model
    if fallback_config and fallback_config.model != config.model:
        try:
            fallback_prompt = build_prompt(text, target_lang, placeholder_names, text_has_icu)
            fallback_out = generate_fn(fallback_config, fallback_prompt)
            fallback_ok, _ = validate_preserved_tokens(text, fallback_out)
            if fallback_ok and not looks_like_translation_failed(text, fallback_out):
                return key, fallback_out, None, True
        except Exception:
            pass

    return key, text, last_err, False  # fallback to original on failure


def fmt_duration(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.1f}s"
    m = int(seconds // 60)
    s = seconds - 60 * m
    if m < 60:
        return f"{m}m {s:.0f}s"
    h = m // 60
    m2 = m % 60
    return f"{h}h {m2}m"


def find_missing_keys(source_data: Dict[str, Any], target_data: Dict[str, Any]) -> List[str]:
    """Find keys that are in source but not in target, or have empty values (excluding metadata keys)."""
    missing = []
    for key in source_data:
        if key == "@@locale":
            continue
        if key.startswith("@"):
            continue
        if key not in target_data:
            missing.append(key)
        elif isinstance(target_data.get(key), str) and target_data[key].strip() == "":
            # Also include keys with empty string values
            missing.append(key)
    return missing


def get_all_locale_files(l10n_dir: str, template_file: str) -> List[Tuple[str, str]]:
    """Find all locale .arb files in the directory, excluding the template.
    
    Returns list of (locale_code, file_path) tuples.
    """
    locales = []
    template_basename = os.path.basename(template_file)
    
    for filename in os.listdir(l10n_dir):
        if not filename.endswith('.arb'):
            continue
        if filename == template_basename:
            continue
        # Extract locale from filename like app_es.arb -> es
        if filename.startswith('app_') and filename.endswith('.arb'):
            locale = filename[4:-4]  # Remove 'app_' prefix and '.arb' suffix
            filepath = os.path.join(l10n_dir, filename)
            locales.append((locale, filepath))
    
    return sorted(locales)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="in_path", required=True, help="Input .arb/.json file path (source/template)")
    ap.add_argument("--out", dest="out_path", default=None, help="Output .arb/.json file path (required unless using --l10n-dir)")
    ap.add_argument("--to-locale", default=None, help="Target locale code, e.g. es, fr, de (required unless using --l10n-dir)")
    ap.add_argument("--l10n-dir", default=None, help="Directory containing locale .arb files. When set, translates all locales.")
    ap.add_argument("--missing-only", action="store_true", help="Only translate keys missing from target file")
    ap.add_argument("--target-lang", default=None, help="Target language name for the model, e.g. Spanish (defaults from locale)")
    ap.add_argument("--model", default="gemma3:4b", help="Model name for selected backend")
    ap.add_argument("--backend", choices=["ollama", "groq", "openai"], default="ollama",
                    help="Inference backend to use")
    ap.add_argument("--groq-api-key", default=None,
                    help="Groq API key (can also be set via GROQ_API_KEY env var)")
    ap.add_argument("--openai-api-key", default=None,
                    help="OpenAI API key (for local servers this can often be omitted)")
    ap.add_argument("--openai-base-url", default="http://localhost:1234/v1",
                    help="OpenAI-compatible base URL for local LLM server")
    ap.add_argument("--fallback-model", default=None, help="Larger model to use for low-confidence translations")
    ap.add_argument("--confidence-threshold", type=float, default=0.7, help="Computed confidence threshold to trigger fallback (0.0-1.0)")
    ap.add_argument("--model-confidence-threshold", type=int, default=4, help="Model self-reported confidence threshold (1-5, use fallback if below)")
    ap.add_argument("--retry-model", default=None, help="Model to use for end-of-run retries")
    ap.add_argument("--host", default="http://localhost:11434", help="Ollama host")
    ap.add_argument("--timeout", type=float, default=120.0, help="HTTP timeout seconds")
    ap.add_argument("--temperature", type=float, default=0.2, help="Model temperature")
    ap.add_argument("--num-ctx", type=int, default=4096, help="Context size")
    ap.add_argument("--num-predict", type=int, default=256, help="Max tokens to generate")
    ap.add_argument("--top-p", type=float, default=0.9, help="Top-p")
    ap.add_argument("--concurrency", type=int, default=4, help="Parallel requests")
    ap.add_argument("--retries", type=int, default=2, help="Retries per string")
    ap.add_argument("--backoff", type=float, default=0.6, help="Backoff seconds base")
    ap.add_argument("--dry-run", action="store_true", help="Do not write file; just print summary")
    ap.add_argument("--progress-every", type=int, default=1, help="Print progress every N completed strings (default: 1)")
    args = ap.parse_args()

    locale_map = {
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "pt-BR": "Brazilian Portuguese",
        "ja": "Japanese",
        "ko": "Korean",
        "zh": "Chinese (Simplified)",
        "zh-Hant": "Chinese (Traditional)",
        "ru": "Russian",
        "uk": "Ukrainian",
        "ar": "Arabic",
        "hi": "Hindi",
        "tr": "Turkish",
        "nl": "Dutch",
        "sv": "Swedish",
        "no": "Norwegian",
        "da": "Danish",
        "fi": "Finnish",
        "pl": "Polish",
        "cs": "Czech",
        "sk": "Slovak",
        "sl": "Slovenian",
        "bg": "Bulgarian",
        "el": "Greek",
        "he": "Hebrew",
        "th": "Thai",
        "vi": "Vietnamese",
        "id": "Indonesian",
    }

    # Read source/template file
    try:
        with open(args.in_path, "r", encoding="utf-8") as f:
            source_data = json.load(f)
    except Exception as e:
        print(f"Failed to read input: {e}", file=sys.stderr)
        return 2

    if not isinstance(source_data, dict):
        print("Input JSON must be an object at top-level.", file=sys.stderr)
        return 2

    # If --l10n-dir is provided, process all locale files
    if args.l10n_dir:
        locales = get_all_locale_files(args.l10n_dir, args.in_path)
        if not locales:
            print(f"No locale files found in {args.l10n_dir}", file=sys.stderr)
            return 1
        
        print(f"Found {len(locales)} locale file(s) to process")
        
        total_translated = 0
        for locale_code, locale_path in locales:
            target_lang = locale_map.get(locale_code, locale_code)
            
            # Read existing target file
            try:
                with open(locale_path, "r", encoding="utf-8") as f:
                    target_data = json.load(f)
            except Exception as e:
                print(f"  [{locale_code}] Failed to read {locale_path}: {e}")
                continue
            
            if args.missing_only:
                missing_keys = find_missing_keys(source_data, target_data)
                if not missing_keys:
                    print(f"  [{locale_code}] No missing keys")
                    continue
                print(f"  [{locale_code}] {len(missing_keys)} missing key(s): {', '.join(missing_keys[:5])}{'...' if len(missing_keys) > 5 else ''}")
            else:
                missing_keys = None
            
            # Run translation for this locale
            result = translate_locale(
                source_data=source_data,
                target_data=target_data,
                target_locale=locale_code,
                target_lang=target_lang,
                out_path=locale_path,
                args=args,
                locale_map=locale_map,
                missing_keys=missing_keys,
            )
            total_translated += result
        
        print(f"\nTotal: {total_translated} string(s) translated across {len(locales)} locale(s)")
        return 0
    
    # Single locale mode - validate required args
    if not args.out_path:
        print("--out is required when not using --l10n-dir", file=sys.stderr)
        return 1
    if not args.to_locale:
        print("--to-locale is required when not using --l10n-dir", file=sys.stderr)
        return 1
    
    target_lang = args.target_lang or locale_map.get(args.to_locale, args.to_locale)

    # Read existing target file if --missing-only and file exists
    target_data: Dict[str, Any] = {}
    missing_keys: Optional[List[str]] = None
    if args.missing_only:
        if os.path.exists(args.out_path):
            try:
                with open(args.out_path, "r", encoding="utf-8") as f:
                    target_data = json.load(f)
                missing_keys = find_missing_keys(source_data, target_data)
                if not missing_keys:
                    print(f"No missing keys in {args.out_path}")
                    return 0
                print(f"Found {len(missing_keys)} missing key(s) to translate")
            except Exception as e:
                print(f"Failed to read target file: {e}", file=sys.stderr)
                return 2
        else:
            print(f"Target file {args.out_path} does not exist. Will translate all strings.")

    result = translate_locale(
        source_data=source_data,
        target_data=target_data,
        target_locale=args.to_locale,
        target_lang=target_lang,
        out_path=args.out_path,
        args=args,
        locale_map=locale_map,
        missing_keys=missing_keys,
    )
    return 0 if result >= 0 else 1


def translate_locale(
    source_data: Dict[str, Any],
    target_data: Dict[str, Any],
    target_locale: str,
    target_lang: str,
    out_path: str,
    args,
    locale_map: Dict[str, str],
    missing_keys: Optional[List[str]] = None,
) -> int:
    """Translate a single locale. Returns number of strings translated."""

    if args.backend == "groq":
        if not GROQ_AVAILABLE:
            print("Error: Groq backend requested but 'groq' package is not installed.", file=sys.stderr)
            print("Run:  pip install groq", file=sys.stderr)
            return -1

        api_key = args.groq_api_key or os.environ.get("GROQ_API_KEY")
        if not api_key:
            print("Error: --groq-api-key or GROQ_API_KEY environment variable is required", file=sys.stderr)
            return 1

        client = Groq(api_key=api_key)

        cfg = GroqConfig(
            client=client,
            model=args.model,
            temperature=args.temperature,
            max_tokens=args.num_predict,       # reusing the same flag
            top_p=args.top_p,
        )
        generate_fn = groq_generate

        fallback_cfg = None
        fallback_generate_fn = None
        if args.fallback_model:
            print("Warning: --fallback-model not yet supported with Groq backend", file=sys.stderr)

    elif args.backend == "openai":
        if not OPENAI_AVAILABLE:
            print("Error: OpenAI backend requested but 'openai' package is not installed.", file=sys.stderr)
            print("Run:  pip install openai", file=sys.stderr)
            return -1

        # Local OpenAI-compatible servers often accept any non-empty API key.
        api_key = args.openai_api_key or os.environ.get("OPENAI_API_KEY") or "local"
        client = OpenAI(api_key=api_key, base_url=args.openai_base_url)

        cfg = OpenAIConfig(
            client=client,
            model=args.model,
            temperature=args.temperature,
            max_tokens=args.num_predict,
            top_p=args.top_p,
        )
        generate_fn = openai_generate

        fallback_cfg = None
        fallback_generate_fn = None
        if args.fallback_model:
            fallback_cfg = OpenAIConfig(
                client=client,
                model=args.fallback_model,
                temperature=args.temperature,
                max_tokens=args.num_predict,
                top_p=args.top_p,
            )
            fallback_generate_fn = openai_generate

    else:  # ollama
        cfg = OllamaConfig(
            host=args.host,
            model=args.model,
            timeout_s=args.timeout,
            temperature=args.temperature,
            num_ctx=args.num_ctx,
            num_predict=args.num_predict,
            top_p=args.top_p,
        )
        generate_fn = ollama_generate

        fallback_cfg = None
        fallback_generate_fn = None
        if args.fallback_model:
            fallback_cfg = OllamaConfig(
                host=args.host,
                model=args.fallback_model,
                timeout_s=args.timeout,
                temperature=args.temperature,
                num_ctx=args.num_ctx,
                num_predict=args.num_predict,
                top_p=args.top_p,
            )
            fallback_generate_fn = ollama_generate

    # Start with target data (preserves existing translations) or source data
    if target_data:
        out_data: Dict[str, Any] = dict(target_data)
    else:
        out_data: Dict[str, Any] = dict(source_data)
    out_data["@@locale"] = target_locale

    # Build list of items to translate
    if missing_keys is not None:
        # Only translate missing keys
        items: List[Tuple[str, str]] = [
            (k, source_data[k]) for k in missing_keys 
            if is_translatable_entry(k, source_data.get(k))
        ]
        # Also copy over any metadata keys for missing items
        for key in missing_keys:
            meta_key = f"@{key}"
            if meta_key in source_data:
                out_data[meta_key] = source_data[meta_key]
    else:
        items: List[Tuple[str, str]] = [(k, v) for k, v in source_data.items() if is_translatable_entry(k, v)]
    
    # Apply manual translations first
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
    if total == 0 and manual_count == 0:
        print("No translatable string entries found (excluding @@locale and @metadata).")
        return 0
    
    if total == 0:
        print("All strings handled by manual translations.")
    else:
        fallback_info = f" (fallback: {args.fallback_model})" if args.fallback_model else ""
        print(f"Translating {total} strings -> {target_lang} using {cfg.model}{fallback_info} (concurrency={args.concurrency})")
    
    start = time.time()

    failures: List[Tuple[str, str]] = []
    translated_ok = manual_count  # Count manual translations as OK
    fallback_used = 0
    completed = 0

    # Build a lookup for original text by key
    items_dict: Dict[str, str] = dict(items_to_translate)

    # Submit all tasks up front
    if total > 0:
        with ThreadPoolExecutor(max_workers=max(1, args.concurrency)) as ex:
            future_to_key = {
            ex.submit(
                    translate_one,
                    key=k,
                    text=v,
                    target_lang=target_lang,
                    generate_fn=generate_fn,
                    config=cfg,
                    retries=args.retries,
                    backoff_s=args.backoff,
                    fallback_generate_fn=fallback_generate_fn,
                    fallback_config=fallback_cfg,
                    confidence_threshold=args.confidence_threshold,
                    model_confidence_threshold=args.model_confidence_threshold,
                    ask_model_confidence=bool(args.fallback_model),
                ): k
                for (k, v) in items_to_translate
            }
            print(f"Submitted {len(future_to_key)} translation tasks...")
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
                        status = "OK*"  # asterisk indicates fallback model was used
                    else:
                        status = "OK"

                if args.progress_every > 0 and (completed % args.progress_every == 0 or completed == total):
                    elapsed = time.time() - start
                    rate = completed / elapsed if elapsed > 0 else 0.0
                    remaining = (total - completed) / rate if rate > 0 else 0.0
                    # Keep it single-line friendly but readable.
                    print(
                        f"[{completed:>4}/{total}] {status:<4} {k} | "
                        f"elapsed {fmt_duration(elapsed)} | ETA {fmt_duration(remaining)}"
                    )

    elapsed = time.time() - start
    fallback_msg = f", used_fallback_model={fallback_used}" if fallback_used > 0 else ""
    print(f"Done in {fmt_duration(elapsed)}. OK={translated_ok}{fallback_msg}, errors={len(failures)}: {translated}")

    # Retry failed translations at the end with increasing temperature
    retry_round = 1
    max_end_retries = 3
    retry_model = args.retry_model or args.model

    while failures and retry_round <= max_end_retries:
        # Increase temperature for each retry round
        retry_temp = min(cfg.temperature + (0.2 * retry_round), 1.0)
        print(f"\n--- Retry round {retry_round}/{max_end_retries} for {len(failures)} failed key(s) (model={retry_model}, temp={retry_temp:.1f}) ---")
        retry_items = [(k, items_dict[k]) for k, _ in failures]
        failures = []
        retry_completed = 0
        retry_total = len(retry_items)
        retry_start = time.time()
        if args.backend == "groq":
            retry_cfg = GroqConfig(
                client=cfg.client,
                model=retry_model,
                temperature=retry_temp,
                max_tokens=cfg.max_tokens,
                top_p=cfg.top_p,
            )
            retry_generate_fn = groq_generate
        elif args.backend == "openai":
            retry_cfg = OpenAIConfig(
                client=cfg.client,
                model=retry_model,
                temperature=retry_temp,
                max_tokens=cfg.max_tokens,
                top_p=cfg.top_p,
            )
            retry_generate_fn = openai_generate
        else:
            retry_cfg = OllamaConfig(
                host=cfg.host,
                model=retry_model,
                timeout_s=cfg.timeout_s,
                temperature=retry_temp,
                num_ctx=cfg.num_ctx,
                num_predict=cfg.num_predict,
                top_p=cfg.top_p,
            )
            retry_generate_fn = ollama_generate 
        with ThreadPoolExecutor(max_workers=max(1, args.concurrency)) as ex:
            future_to_key = {
                ex.submit(
                    translate_one,
                    key=k,
                    text=v,
                    target_lang=target_lang,
                    config=retry_cfg,
                    generate_fn=retry_generate_fn,
                    retries=args.retries,
                    backoff_s=args.backoff,
                ): k
                for (k, v) in retry_items
            }

            for fut in as_completed(future_to_key):
                k, translated, err, used_fb = fut.result()
                out_data[k] = translated

                retry_completed += 1
                if err:
                    failures.append((k, err))
                    status = "FAIL"
                else:
                    translated_ok += 1
                    status = "OK"

                if args.progress_every > 0 and (retry_completed % args.progress_every == 0 or retry_completed == retry_total):
                    elapsed = time.time() - retry_start
                    rate = retry_completed / elapsed if elapsed > 0 else 0.0
                    remaining = (retry_total - retry_completed) / rate if rate > 0 else 0.0
                    print(
                        f"[{retry_completed:>4}/{retry_total}] {status:<4} {k} | "
                        f"elapsed {fmt_duration(elapsed)} | ETA {fmt_duration(remaining)}"
                    )

        retry_elapsed = time.time() - retry_start
        print(f"Retry round {retry_round} done in {fmt_duration(retry_elapsed)}. Remaining failures: {len(failures)}")
        retry_round += 1

    total_elapsed = time.time() - start
    print(f"\nTotal time: {fmt_duration(total_elapsed)}. OK={translated_ok}, final fallback={len(failures)}")

    if failures:
        print("Fallback keys (kept original English due to errors):")
        for k, err in failures[:60]:
            print(f" - {k}: {err}")
        if len(failures) > 60:
            print(f" ... and {len(failures) - 60} more")

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


if __name__ == "__main__":
    raise SystemExit(main())
#!/usr/bin/env python3
"""Generate CareAttend logo concepts with Gemini or OpenAI.

Usage:
  cd tools/logo_generator
  cp config.example.env .env
  # edit .env and add API key
  python generate_logo.py --provider gemini --prompt best --count 4
  python generate_logo.py --provider openai --prompt app_icon --count 4

Notes:
  - Do not use the official NHS logo.
  - Generated images should be reviewed manually before submission or publication.
"""

from __future__ import annotations

import argparse
import base64
import os
from pathlib import Path
from textwrap import dedent

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover
    load_dotenv = None

PROMPTS = {
    "best": dedent("""
        Create a professional vector logo for "CareAttend", a UK healthcare AI app
        that helps GP practices reduce missed appointments for vulnerable patients.
        Combine three ideas: compassionate care, appointment attendance, and responsible AI.
        Use a clean icon with a calendar/checkmark subtly integrated with a protective care symbol.
        NHS-inspired blue (#003087), teal accent (#00A499), white background.
        Minimal, modern, accessible, trustworthy, clinical, scalable app icon.
        Include separate icon and wordmark. No official NHS logo. No photorealism.
        No mockup. Flat vector style.
    """).strip(),
    "app_icon": dedent("""
        Design a mobile app icon for "CareAttend". Icon should show a calendar page
        with a gentle checkmark and small human care motif, suggesting patients attending appointments.
        Use NHS-inspired blue background (#003087), white calendar, teal checkmark.
        Rounded square icon, clear at small size, modern healthcare SaaS style.
        No text inside icon. No official NHS logo. Flat vector, high contrast, accessible.
    """).strip(),
    "ai_ethics": dedent("""
        Create a healthcare AI logo for "CareAttend" showing a simple shield/care shape
        with small connected nodes and a checkmark, symbolising safe explainable AI for appointment attendance.
        Use NHS-inspired blue, teal, and white. Professional UK healthtech brand, trustworthy,
        ethical, minimal vector mark with wordmark. Avoid robots, brains, stethoscopes,
        and official NHS branding.
    """).strip(),
    "patient_support": dedent("""
        Create a warm but professional logo for "CareAttend", a health app supporting elderly
        and vulnerable patients to attend appointments. Icon concept: two abstract people inside
        a calendar outline with a checkmark. NHS-inspired blue and teal, clean sans-serif wordmark,
        accessible, calm, reliable. Flat vector logo, white background, no official NHS logo.
    """).strip(),
}

NEGATIVE_PROMPT = (
    "Do not use the official NHS logo, government crest, stock medical cross alone, ambulance, "
    "emergency red, complex gradients, photorealistic mockups, tiny unreadable text, cartoon mascot, "
    "overly futuristic robot, busy background, or fake hospital branding."
)


def load_env() -> None:
    if load_dotenv:
        load_dotenv()


def write_image(output_dir: Path, filename: str, image_bytes: bytes) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    path = output_dir / filename
    path.write_bytes(image_bytes)
    return path


def generate_with_openai(prompt: str, count: int, output_dir: Path) -> list[Path]:
    from openai import OpenAI

    client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
    paths = []
    for index in range(count):
        result = client.images.generate(
            model="gpt-image-1",
            prompt=f"{prompt}\n\nNegative guidance: {NEGATIVE_PROMPT}",
            size="1024x1024",
            quality="high",
        )
        image_base64 = result.data[0].b64_json
        image_bytes = base64.b64decode(image_base64)
        paths.append(write_image(output_dir, f"careattend_openai_{index + 1}.png", image_bytes))
    return paths


def generate_with_gemini(prompt: str, count: int, output_dir: Path) -> list[Path]:
    """Gemini image generation adapter.

    Google has changed image-generation SDK surfaces several times. This uses the
    current google-genai style. If your installed SDK differs, keep the prompt and
    provider wrapper, then adapt the API call only.
    """
    from google import genai
    from google.genai import types

    client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
    paths = []
    for index in range(count):
        response = client.models.generate_content(
            model="gemini-2.0-flash-preview-image-generation",
            contents=f"{prompt}\n\nNegative guidance: {NEGATIVE_PROMPT}",
            config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
        )
        saved = False
        for part in response.candidates[0].content.parts:
            if getattr(part, "inline_data", None):
                image_bytes = part.inline_data.data
                paths.append(write_image(output_dir, f"careattend_gemini_{index + 1}.png", image_bytes))
                saved = True
                break
        if not saved:
            raise RuntimeError("Gemini response did not include image data.")
    return paths


def main() -> None:
    load_env()
    parser = argparse.ArgumentParser(description="Generate CareAttend logo concepts.")
    parser.add_argument("--provider", choices=["gemini", "openai"], default=os.getenv("LOGO_PROVIDER", "gemini"))
    parser.add_argument("--prompt", choices=sorted(PROMPTS), default="best")
    parser.add_argument("--count", type=int, default=4)
    parser.add_argument("--output-dir", default=os.getenv("LOGO_OUTPUT_DIR", "outputs"))
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    prompt = PROMPTS[args.prompt]

    if args.provider == "openai":
        if not os.environ.get("OPENAI_API_KEY"):
            raise SystemExit("Missing OPENAI_API_KEY. Add it to .env or environment.")
        paths = generate_with_openai(prompt, args.count, output_dir)
    else:
        if not os.environ.get("GEMINI_API_KEY"):
            raise SystemExit("Missing GEMINI_API_KEY. Add it to .env or environment.")
        paths = generate_with_gemini(prompt, args.count, output_dir)

    print("Generated logo concepts:")
    for path in paths:
        print(f"- {path}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Static guard for the Waterways two-phase flow shader contract."""

from __future__ import annotations

import re
import sys
from pathlib import Path


FEATURE_DIR = Path(__file__).resolve().parent
REPO_ROOT = FEATURE_DIR.parents[2]

SHADERS = {
    "river": Path("addons/waterways/shaders/river.gdshader"),
    "river_debug": Path("addons/waterways/shaders/river_debug.gdshader"),
    "lava": Path("addons/waterways/shaders/lava.gdshader"),
}
MENU = Path("addons/waterways/gui/river_menu.gd")


class CheckRun:
    def __init__(self) -> None:
        self.passed: list[str] = []
        self.failed: list[str] = []

    def require(self, path: Path, label: str, condition: bool) -> None:
        rel_path = path.as_posix()
        message = f"{rel_path}: {label}"
        if condition:
            self.passed.append(message)
        else:
            self.failed.append(message)


def read_text(path: Path) -> str:
    return (REPO_ROOT / path).read_text(encoding="utf-8")


def compact(text: str) -> str:
    return re.sub(r"\s+", "", text)


def main() -> int:
    run = CheckRun()
    shader_text = {name: read_text(path) for name, path in SHADERS.items()}
    shader_compact = {name: compact(text) for name, text in shader_text.items()}

    common_needles = {
        "FlowUVW signature": "vec3FlowUVW(vec2uv_in,vec2flowVector,vec2jump,vec3tiling,floattime,boolflowB)",
        "phase B half-period offset": "floatphaseOffset=flowB?0.5:0.0;",
        "progress uses fract(time + phaseOffset)": "floatprogress=fract(time+phaseOffset);",
        "local displacement preserves progress - 0.5": "uvw.xy=uv_in-flowVector*(progress-0.5);",
        "tiling applies to displaced UV": "uvw.xy*=tiling.xy;",
        "phase offset is added to UV": "uvw.xy+=phaseOffset;",
        "jump offset uses time - progress": "uvw.xy+=(time-progress)*jump;",
        "triangle-wave blend weight": "uvw.z=1.0-abs(1.0-2.0*progress);",
        "packed RG flow decode": "flow=(flow-0.5)*2.0;",
        "alpha phase/noise participates in time": "floattime=TIME*flow_speed+flow_foam_noise.a;",
        "primary jump constant": "vec2(0.24,0.2083333)",
    }

    for name, path in SHADERS.items():
        text = shader_compact[name]
        for label, needle in common_needles.items():
            run.require(path, label, needle in text)

    for name in ("river", "river_debug"):
        run.require(
            SHADERS[name],
            "secondary detail jump constant where the variant uses a second layer",
            "vec2(0.20,0.25)" in shader_compact[name],
        )

    run.require(
        SHADERS["lava"],
        "lava intentionally omits the secondary detail jump layer",
        "vec2(0.20,0.25)" not in shader_compact["lava"],
    )

    steepness_expectations = {
        "river": "floatsteepness_map=max(0.0,dot(flow_viewspace,up_viewspace))*4.0;",
        "river_debug": "floatsteepness_map=max(0.0,dot(flow_viewspace,up_viewspace))*8.0;",
        "lava": "floatsteepness_map=max(0.0,dot(flow_viewspace,up_viewspace))*4.0;",
    }
    for name, needle in steepness_expectations.items():
        run.require(
            SHADERS[name],
            "steepness diagnostic scale matches documented variant behavior",
            needle in shader_compact[name],
        )

    debug_shader_checks = {
        "NOISEMAP mode id": "constintNOISEMAP=3;",
        "FLOW_PATTERN mode id": "constintFLOW_PATTERN=6;",
        "FLOW_ARROWS mode id": "constintFLOW_ARROWS=7;",
        "FLOW_FORCE mode id": "constintFLOW_FORCE=8;",
        "FOAM_MIX mode id": "constintFOAM_MIX=9;",
        "Flow Pattern branch": "mode==FLOW_PATTERN",
        "Flow Arrows branch": "mode==FLOW_ARROWS",
        "Flow Strength branch": "mode==FLOW_FORCE",
        "Foam Mix branch": "mode==FOAM_MIX",
    }
    for label, needle in debug_shader_checks.items():
        run.require(SHADERS["river_debug"], label, needle in shader_compact["river_debug"])

    menu_text = read_text(MENU)
    menu_checks = {
        "Validate Data Textures menu action": "Validate Data Textures",
        "Noise Map debug menu item": "Display Debug Noise Map (A)",
        "Flow Pattern debug menu item": "Display Debug Flow Pattern",
        "Flow Arrows debug menu item": "Display Debug Flow Arrows",
        "Flow Strength debug menu item": "Display Debug Flow Strength",
        "Foam Mix debug menu item": "Display Debug Foam Mix",
    }
    for label, needle in menu_checks.items():
        run.require(MENU, label, needle in menu_text)

    print("Two-phase flow drift guard")
    for message in run.passed:
        print(f"PASS {message}")
    for message in run.failed:
        print(f"FAIL {message}")
    print(f"Summary: {len(run.passed)} passed, {len(run.failed)} failed")

    return 1 if run.failed else 0


if __name__ == "__main__":
    sys.exit(main())

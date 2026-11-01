#!/usr/bin/env python3
import json
import re
import subprocess
import sys
import time


def run(*args):
    try:
        return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL)
    except (OSError, subprocess.CalledProcessError):
        return ""


def value(block, key):
    match = re.search(rf"^\s*{re.escape(key)}:\s*(.+)$", block, re.M)
    return match.group(1).strip() if match else ""


def property_value(block, key):
    match = re.search(rf"^\s*{re.escape(key)}\s*=\s*\"?([^\"\n]+)", block, re.M)
    return match.group(1).strip() if match else ""


def volume(block):
    match = re.search(r"Volume:.*?/(\s*\d+)%", block, re.S)
    # The panel intentionally exposes a standard 0-100% control. PipeWire
    # can report software amplification above 100%; cap only the UI value.
    return min(100, int(match.group(1))) if match else 0


def muted(block):
    return value(block, "Mute").lower() == "yes"


def blocks(kind):
    data = run("pactl", "list", kind)
    return re.split(r"\n(?=(?:Sink|Sink Input) #)", data)


def main():
    sinks = []
    default = run("pactl", "get-default-sink").strip()
    for block in blocks("sinks"):
        ident = re.match(r"Sink #(\d+)", block)
        if not ident:
            continue
        sink_id = ident.group(1)
        name = value(block, "Name") or sink_id
        description = value(block, "Description") or name
        sinks.append({
            "id": sink_id,
            "name": description,
            "pactl_name": name,
            "default": name == default,
            "volume": volume(block),
            "muted": muted(block),
        })

    inputs = []
    for block in blocks("sink-inputs"):
        ident = re.match(r"Sink Input #(\d+)", block)
        if not ident:
            continue
        input_id = ident.group(1)
        sink = value(block, "Sink")
        binary = property_value(block, "application.process.binary")
        app_name = property_value(block, "application.name")
        media = property_value(block, "media.name")
        # Prefer the user-facing process name. PipeWire's node name (for
        # example WEBRTC VoiceEngine) is an implementation detail.
        # Use the friendly application name unless it is a generic
        # implementation label such as WebRTC VoiceEngine.
        generic_names = {"webrtc voiceengine", "pipewire", "pulseaudio"}
        app = app_name if app_name and app_name.lower() not in generic_names else (binary or media or "Aplicación")
        if (media and media not in (app, "playStream") and media.lower() != app.lower()
                and not re.fullmatch(r"0x[0-9a-f]+", media, re.I)):
            app = f"{app} — {media}"
        inputs.append({
            "id": input_id,
            "sink": sink.split(" ", 1)[0],
            "name": app,
            "volume": volume(block),
            "muted": muted(block),
        })

    result = {"sinks": sinks, "inputs": inputs}
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    print(json.dumps(result.get(mode, result), ensure_ascii=False), flush=True)

    if len(sys.argv) < 3 or sys.argv[2] != "--watch":
        return

    # Keep one listener alive instead of spawning a new pactl/python process
    # every second. This avoids rebuilding Eww sliders while they are dragged.
    try:
        process = subprocess.Popen(
            ["pactl", "subscribe"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        for line in process.stdout:
            # Refresh the list only when streams/devices appear or disappear.
            # Ignore volume/mute change events so dragging a slider cannot
            # cause Eww to rebuild that slider under the pointer.
            if ("'new'" in line or "'remove'" in line) and any(
                kind in line for kind in ("'sink'", "'sink-input'", "'server'")
            ):
                time.sleep(0.05)
                data = {"sinks": [], "inputs": []}
                # Re-run this script once for a fresh snapshot, without watch.
                fresh = subprocess.check_output(
                    [sys.executable, __file__, mode],
                    text=True,
                    stderr=subprocess.DEVNULL,
                ).strip()
                print(fresh, flush=True)
    except (OSError, subprocess.CalledProcessError):
        return


if __name__ == "__main__":
    main()

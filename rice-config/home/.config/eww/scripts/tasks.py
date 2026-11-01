#!/usr/bin/env python3
"""Small local task store for the Eww dashboard."""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


DATA_FILE = Path(
    os.environ.get(
        "EWW_TASKS_FILE",
        str(Path.home() / ".local/share/eww-tasks/tasks.json"),
    )
)
CONFIG_DIR = Path(
    os.environ.get("EWW_TASKS_CONFIG", str(Path.home() / ".config/eww"))
)
UPDATE_VARIABLE = os.environ.get("EWW_TASKS_VARIABLE", "tasks")


def load_tasks() -> list[dict]:
    if not DATA_FILE.exists():
        return []
    try:
        tasks = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"No pude leer {DATA_FILE}: {exc}") from exc
    if not isinstance(tasks, list) or any(
        not isinstance(task, dict)
        or not isinstance(task.get("id"), int)
        or not isinstance(task.get("text"), str)
        or not isinstance(task.get("done"), bool)
        for task in tasks
    ):
        raise RuntimeError(f"El archivo de tareas tiene un formato inesperado: {DATA_FILE}")
    return tasks


def save_tasks(tasks: list[dict]) -> None:
    DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(tasks, ensure_ascii=False, indent=2) + "\n"
    fd, temp_name = tempfile.mkstemp(prefix="tasks-", dir=DATA_FILE.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_name, DATA_FILE)
    except Exception:
        try:
            os.close(fd)
        except OSError:
            pass
        try:
            os.unlink(temp_name)
        except OSError:
            pass
        raise


def update_eww(tasks: list[dict]) -> None:
    value = UPDATE_VARIABLE + "=" + json.dumps(
        tasks, ensure_ascii=False, separators=(",", ":")
    )
    try:
        subprocess.run(
            ["eww", "-c", str(CONFIG_DIR), "update", value],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=2,
        )
    except (OSError, subprocess.TimeoutExpired):
        # The data remains saved; Eww will load it the next time its config starts.
        pass


def mutate(operation: str, task_id: int | None = None, text: str | None = None) -> None:
    lock_path = DATA_FILE.with_suffix(DATA_FILE.suffix + ".lock")
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        tasks = load_tasks()

        if operation == "add":
            task_text = (text or "").strip()
            if not task_text:
                return
            next_id = max((task["id"] for task in tasks), default=0) + 1
            tasks.append({"id": next_id, "text": task_text[:240], "done": False})
        elif operation == "toggle":
            for task in tasks:
                if task["id"] == task_id:
                    task["done"] = not task["done"]
                    break
        elif operation == "delete":
            tasks = [task for task in tasks if task["id"] != task_id]

        save_tasks(tasks)
        update_eww(tasks)


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("list")
    subparsers.add_parser("add-stdin")
    toggle_parser = subparsers.add_parser("toggle")
    toggle_parser.add_argument("task_id", type=int)
    delete_parser = subparsers.add_parser("delete")
    delete_parser.add_argument("task_id", type=int)
    args = parser.parse_args()

    try:
        if args.command == "list":
            print(json.dumps(load_tasks(), ensure_ascii=False, separators=(",", ":")))
        elif args.command == "add-stdin":
            mutate("add", text=sys.stdin.readline(4096))
        elif args.command == "toggle":
            mutate("toggle", task_id=args.task_id)
        elif args.command == "delete":
            mutate("delete", task_id=args.task_id)
    except (OSError, RuntimeError) as exc:
        print(f"Eww tasks: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

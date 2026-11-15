#!/usr/bin/env python3
"""Pair (if needed), trust, and connect a Bluetooth device via bluetoothctl."""

import os
import pty
import re
import select
import subprocess
import sys
import time

ANSI_RE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]|\r")


def run_cmd(args: list[str], timeout: int = 15) -> tuple[int, str]:
    proc = subprocess.run(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout,
    )
    return proc.returncode, ANSI_RE.sub("", proc.stdout).strip()


def pair_with_agent(mac: str, timeout_sec: float = 25.0) -> tuple[bool, str]:
    master_fd, slave_fd = pty.openpty()
    proc = subprocess.Popen(
        ["bluetoothctl"],
        stdin=slave_fd,
        stdout=slave_fd,
        stderr=slave_fd,
        close_fds=True,
    )
    os.close(slave_fd)

    buf = ""
    last_error = ""
    sent_pair = False
    deadline = time.monotonic() + timeout_sec

    try:
        os.write(master_fd, b"agent NoInputNoOutput\ndefault-agent\n")
        time.sleep(0.3)
        os.write(master_fd, f"pair {mac}\n".encode())
        sent_pair = True

        while time.monotonic() < deadline:
            remaining = max(0.1, min(0.5, deadline - time.monotonic()))
            rlist, _, _ = select.select([master_fd], [], [], remaining)
            if rlist:
                try:
                    chunk = os.read(master_fd, 4096).decode("utf-8", errors="replace")
                except OSError:
                    break
                if not chunk:
                    break
                buf += ANSI_RE.sub("", chunk)

                if "(yes/no)" in buf or "Confirm passkey" in buf or "Authorize service" in buf:
                    os.write(master_fd, b"yes\n")
                    buf = ""
                    continue

                if "Pairing successful" in buf or "Already Exists" in buf:
                    return True, ""

                for line in buf.splitlines():
                    s = line.strip()
                    if (
                        "Failed to pair" in s
                        or "org.bluez.Error" in s
                        or "not available" in s
                    ):
                        last_error = s
                if last_error:
                    return False, last_error

            if proc.poll() is not None:
                break

        if not sent_pair:
            return False, "Failed to start bluetoothctl pairing."
        return False, last_error or "Pairing timed out — confirm the prompt on your device."
    finally:
        try:
            os.write(master_fd, b"quit\n")
        except OSError:
            pass
        try:
            os.close(master_fd)
        except OSError:
            pass
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()


def main() -> int:
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("Missing Bluetooth MAC address.")
        return 1

    mac = sys.argv[1].strip()

    subprocess.run(["rfkill", "unblock", "bluetooth"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    _, show_out = run_cmd(["bluetoothctl", "show"])
    if "Powered: yes" not in show_out:
        rc, pwr_out = run_cmd(["bluetoothctl", "power", "on"])
        if rc != 0:
            print(pwr_out or "Failed to power on Bluetooth.")
            return 1

    _, info_out = run_cmd(["bluetoothctl", "info", mac])
    if "Paired: yes" not in info_out:
        ok, err = pair_with_agent(mac)
        if not ok:
            print(err or "Failed to pair device.")
            return 1

    run_cmd(["bluetoothctl", "trust", mac])

    rc, conn_out = run_cmd(["bluetoothctl", "connect", mac], timeout=20)
    if rc != 0:
        if "br-connection-key-missing" in conn_out:
            print("Pairing key missing — click Forget and reconnect to re-pair.")
        else:
            lines = [l.strip() for l in conn_out.splitlines() if l.strip()]
            print(lines[-1] if lines else "Failed to connect.")
        return 1

    print(conn_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

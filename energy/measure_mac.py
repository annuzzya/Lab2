import argparse
import calendar
import os
import plistlib
import signal
import statistics
import subprocess
import sys
import time

SAMPLERS = "cpu_power,tasks"


def powermetrics_cmd(path, interval, count=None):
    cmd = ["powermetrics", "--samplers", SAMPLERS, "--show-process-energy",
           "-i", str(interval), "-f", "plist", "-o", path]
    if count:
        cmd += ["-n", str(count)]
    return cmd


def read_samples(path):
    raw = open(path, "rb").read()
    out = []
    for chunk in raw.split(b"</plist>"):
        chunk = chunk.strip(b"\x00\n\r\t ")
        if not chunk:
            continue
        try:
            out.append(plistlib.loads(chunk + b"</plist>"))
        except Exception:
            pass
    return out


def power_mw(s):
    p = s.get("processor", {})
    dt = s.get("elapsed_ns", 0) / 1e9
    if "combined_power" in p:
        return float(p["combined_power"])
    if "cpu_power" in p:
        return float(p["cpu_power"])
    if "cpu_energy" in p and dt:
        return float(p["cpu_energy"]) / dt
    if "package_watts" in p:
        return float(p["package_watts"]) * 1000
    raise KeyError("no power field, keys: %s" % sorted(p.keys()))


def task_share(s, pid, name):
    tasks = s.get("tasks", [])
    total = sum(t.get("cputime_ms_per_s", 0) for t in tasks)
    mine = [t for t in tasks if t.get("pid") == pid or t.get("name") == name]
    if not mine or not total:
        return 0.0, 0.0
    cpu = sum(t.get("cputime_ms_per_s", 0) for t in mine)
    ei = sum(t.get("energy_impact_per_s", t.get("energy_impact", 0)) for t in mine)
    return cpu / total, ei


def sample_windows(samples, pm_start, t0, t1, use_ts=True):
    windows = []
    t = pm_start
    for s in samples:
        dt = s.get("elapsed_ns", 0) / 1e9
        ts = s.get("timestamp") if use_ts else None
        end = calendar.timegm(ts.timetuple()) + ts.microsecond / 1e6 if ts else t + dt
        windows.append((end - dt, end, s))
        t = end
    covered = sum(max(0.0, min(b, t1) - max(a, t0)) for a, b, _ in windows)
    if use_ts and covered < 0.5 * (t1 - t0):
        return sample_windows(samples, pm_start, t0, t1, False)
    return windows


def measure_idle(seconds, interval, out_dir):
    path = os.path.join(out_dir, "idle.plist")
    n = max(3, int(seconds * 1000 / interval))
    subprocess.run(powermetrics_cmd(path, interval, n), check=True, stdout=subprocess.DEVNULL)
    samples = read_samples(path)
    return statistics.mean(power_mw(s) for s in samples[1:] or samples)


def measure_run(binary, interval, out_dir, idx, idle_mw):
    name = os.path.basename(binary)
    path = os.path.join(out_dir, f"{name}_run{idx}.plist")
    pm_start = time.time()
    pm = subprocess.Popen(powermetrics_cmd(path, interval), stdout=subprocess.DEVNULL)
    time.sleep(2)
    t0 = time.time()
    proc = subprocess.Popen([binary], stdout=subprocess.PIPE, text=True)
    output, _ = proc.communicate()
    t1 = time.time()
    time.sleep(interval / 1000 * 2)
    pm.send_signal(signal.SIGINT)
    pm.wait()

    e_sys = e_sub = e_share = ei_sum = 0.0
    for a, b, s in sample_windows(read_samples(path), pm_start, t0, t1):
        ov = max(0.0, min(b, t1) - max(a, t0))
        if ov <= 0:
            continue
        p = power_mw(s) / 1000
        share, ei = task_share(s, proc.pid, name)
        e_sys += p * ov
        e_sub += max(0.0, p - idle_mw / 1000) * ov
        e_share += p * share * ov
        ei_sum += ei * ov
    return {"time": t1 - t0, "e_sys": e_sys, "e_sub": e_sub, "e_share": e_share,
            "p_avg": e_sys / (t1 - t0), "ei": ei_sum, "output": output}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("binaries", nargs="+")
    ap.add_argument("--repeat", type=int, default=3)
    ap.add_argument("--idle", type=float, default=10)
    ap.add_argument("--interval", type=int, default=250)
    ap.add_argument("--out", default="results/energy_mac")
    a = ap.parse_args()

    if os.geteuid() != 0:
        sys.exit("run with sudo: sudo python3 energy/measure_mac.py build/bench_O0 build/bench_O3")
    os.makedirs(a.out, exist_ok=True)

    print(f"idle baseline {a.idle:.0f} s, do not touch the laptop...")
    idle = measure_idle(a.idle, a.interval, a.out)
    print(f"idle power: {idle:.0f} mW\n")

    rows = []
    for b in a.binaries:
        runs = []
        for i in range(a.repeat):
            r = measure_run(b, a.interval, a.out, i, idle)
            runs.append(r)
            print(f"{os.path.basename(b)} run {i + 1}: {r['time']:.2f} s, "
                  f"system {r['e_sys']:.2f} J, program {r['e_sub']:.2f} J / {r['e_share']:.2f} J")
            time.sleep(3)
        avg = {k: statistics.mean(r[k] for r in runs) for k in ("time", "e_sys", "e_sub", "e_share", "p_avg", "ei")}
        rows.append((os.path.basename(b), avg))

    lines = [
        f"Idle power (baseline): **{idle:.0f} mW**, interval {a.interval} ms, {a.repeat} runs each\n",
        "| build | time, s | avg power, W | system energy, J | program energy (minus idle), J | program energy (CPU-time share), J | energy impact |",
        "|---|---|---|---|---|---|---|",
    ]
    for n, v in rows:
        lines.append(f"| {n} | {v['time']:.2f} | {v['p_avg']:.2f} | {v['e_sys']:.2f} | {v['e_sub']:.2f} | {v['e_share']:.2f} | {v['ei']:.1f} |")
    if len(rows) == 2:
        (n0, v0), (n1, v1) = rows
        lines.append("")
        lines.append(f"{n0} / {n1}: time x{v0['time'] / v1['time']:.2f}, "
                     f"system energy x{v0['e_sys'] / v1['e_sys']:.2f}, "
                     f"program energy x{v0['e_sub'] / max(v1['e_sub'], 1e-9):.2f}")
    text = "\n".join(lines)
    print("\n" + text)
    open(os.path.join(a.out, "summary.md"), "w").write(text + "\n")


if __name__ == "__main__":
    main()

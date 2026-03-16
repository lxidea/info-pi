"""System statistics collector using psutil."""

import os
import psutil


def _read_cpu_temp():
    """Read CPU temperature, trying psutil first then sysfs thermal zone."""
    try:
        temps = psutil.sensors_temperatures()
        if temps:
            for name in ("cpu_thermal", "cpu-thermal", "coretemp"):
                if name in temps and temps[name]:
                    return temps[name][0].current
            first = next(iter(temps.values()), [])
            if first:
                return first[0].current
    except (AttributeError, Exception):
        pass

    # Fallback: read from sysfs (Raspberry Pi)
    thermal_path = "/sys/class/thermal/thermal_zone0/temp"
    if os.path.exists(thermal_path):
        try:
            with open(thermal_path) as f:
                return int(f.read().strip()) / 1000.0
        except (IOError, ValueError):
            pass

    return None


def collect():
    cpu_percent = psutil.cpu_percent(interval=None)
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage("/")
    temp = _read_cpu_temp()

    return {
        "cpu_percent": cpu_percent,
        "ram_percent": mem.percent,
        "ram_used_gb": round(mem.used / (1024 ** 3), 1),
        "ram_total_gb": round(mem.total / (1024 ** 3), 1),
        "disk_percent": disk.percent,
        "disk_used_gb": round(disk.used / (1024 ** 3), 1),
        "disk_total_gb": round(disk.total / (1024 ** 3), 1),
        "temperature": round(temp, 1) if temp is not None else None,
    }

"""Network information collector."""

import subprocess
import psutil


def _get_ip_addresses():
    """Get IP addresses for each network interface."""
    addrs = psutil.net_if_addrs()
    result = {}
    for iface, addr_list in addrs.items():
        if iface == "lo":
            continue
        for addr in addr_list:
            if addr.family.name == "AF_INET":
                result[iface] = addr.address
                break
    return result


def _get_arp_devices():
    """Get network devices from ARP/neighbor table."""
    devices = []
    try:
        output = subprocess.check_output(
            ["ip", "neigh"], timeout=5, text=True, stderr=subprocess.DEVNULL
        )
        for line in output.strip().split("\n"):
            if not line:
                continue
            parts = line.split()
            if len(parts) >= 4 and parts[-1] != "FAILED":
                ip = parts[0]
                mac = ""
                state = parts[-1]
                if "lladdr" in parts:
                    mac_idx = parts.index("lladdr") + 1
                    if mac_idx < len(parts):
                        mac = parts[mac_idx]
                devices.append({"ip": ip, "mac": mac, "state": state})
    except Exception:
        pass
    return devices


def _get_bandwidth():
    """Get cumulative network byte counters."""
    counters = psutil.net_io_counters(pernic=True)
    result = {}
    for iface, stats in counters.items():
        if iface == "lo":
            continue
        result[iface] = {
            "bytes_sent": stats.bytes_sent,
            "bytes_recv": stats.bytes_recv,
        }
    return result


def collect():
    return {
        "interfaces": _get_ip_addresses(),
        "devices": _get_arp_devices(),
        "bandwidth": _get_bandwidth(),
    }

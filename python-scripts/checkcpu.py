#!/usr/bin/env python3
"""
CPU Information Tool

Displays comprehensive CPU information including count, model, frequency,
cache sizes, and usage statistics.

Usage:
    python3 checkcpu.py [options]
"""

import argparse
import json
import multiprocessing
import os
import platform
import sys
from typing import Dict, Any, Optional


def get_cpu_count() -> Dict[str, int]:
    """Get CPU count information."""
    logical_count = multiprocessing.cpu_count()

    # Try to get physical core count
    try:
        physical_count = os.cpu_count() or logical_count
    except AttributeError:
        physical_count = logical_count

    return {
        'logical': logical_count,
        'physical': physical_count
    }


def get_cpu_info_linux() -> Dict[str, Any]:
    """Get detailed CPU information on Linux."""
    info = {}

    try:
        with open('/proc/cpuinfo', 'r') as f:
            cpuinfo = f.read()

        # Extract model name
        for line in cpuinfo.split('\n'):
            if 'model name' in line:
                info['model'] = line.split(':')[1].strip()
                break

        # Extract vendor
        for line in cpuinfo.split('\n'):
            if 'vendor_id' in line:
                info['vendor'] = line.split(':')[1].strip()
                break

        # Extract CPU MHz
        for line in cpuinfo.split('\n'):
            if 'cpu MHz' in line:
                info['mhz'] = float(line.split(':')[1].strip())
                break

        # Extract cache size
        for line in cpuinfo.split('\n'):
            if 'cache size' in line:
                info['cache_size'] = line.split(':')[1].strip()
                break

        # Extract flags/features (first processor only)
        for line in cpuinfo.split('\n'):
            if 'flags' in line:
                flags = line.split(':')[1].strip().split()
                info['flags'] = flags
                info['flag_count'] = len(flags)
                break

    except FileNotFoundError:
        pass

    return info


def get_cpu_info_macos() -> Dict[str, Any]:
    """Get detailed CPU information on macOS."""
    info = {}

    try:
        import subprocess

        # Get CPU brand
        result = subprocess.run(
            ['sysctl', '-n', 'machdep.cpu.brand_string'],
            capture_output=True,
            text=True,
            check=True
        )
        info['model'] = result.stdout.strip()

        # Get CPU frequency
        try:
            result = subprocess.run(
                ['sysctl', '-n', 'hw.cpufrequency'],
                capture_output=True,
                text=True,
                check=True
            )
            if result.stdout.strip():
                info['hz'] = int(result.stdout.strip())
                info['mhz'] = info['hz'] / 1_000_000
        except (subprocess.CalledProcessError, ValueError):
            pass

        # Get cache sizes
        for cache_type in ['l1icachesize', 'l1dcachesize', 'l2cachesize', 'l3cachesize']:
            try:
                result = subprocess.run(
                    ['sysctl', '-n', f'hw.{cache_type}'],
                    capture_output=True,
                    text=True,
                    check=True
                )
                cache_bytes = int(result.stdout.strip())
                cache_kb = cache_bytes / 1024
                info[cache_type] = f"{cache_kb:.0f} KB"
            except (subprocess.CalledProcessError, ValueError):
                pass

        # Get CPU features
        try:
            result = subprocess.run(
                ['sysctl', '-n', 'machdep.cpu.features'],
                capture_output=True,
                text=True,
                check=True
            )
            flags = result.stdout.strip().split()
            info['flags'] = flags
            info['flag_count'] = len(flags)
        except subprocess.CalledProcessError:
            pass

    except (ImportError, FileNotFoundError):
        pass

    return info


def get_cpu_usage() -> Optional[float]:
    """Get current CPU usage percentage."""
    try:
        import psutil
        return psutil.cpu_percent(interval=1)
    except ImportError:
        # Try Linux-specific method
        try:
            with open('/proc/stat', 'r') as f:
                lines = f.readlines()

            # First line is aggregate CPU stats
            cpu_line = lines[0].split()

            # Calculate usage (simplified)
            user = int(cpu_line[1])
            nice = int(cpu_line[2])
            system = int(cpu_line[3])
            idle = int(cpu_line[4])

            total = user + nice + system + idle
            used = user + nice + system

            return (used / total) * 100 if total > 0 else 0.0
        except (FileNotFoundError, IndexError, ValueError):
            return None


def get_cpu_temperature() -> Optional[float]:
    """Get CPU temperature if available."""
    try:
        import psutil
        temps = psutil.sensors_temperatures()

        # Try common sensor names
        for sensor_name in ['coretemp', 'cpu_thermal', 'k10temp']:
            if sensor_name in temps:
                return temps[sensor_name][0].current

        # If no common sensor found, try first available
        if temps:
            first_sensor = list(temps.keys())[0]
            return temps[first_sensor][0].current
    except (ImportError, AttributeError):
        pass

    return None


def is_virtual_cpu() -> bool:
    """Detect if running on a virtual machine."""
    system = platform.system()

    if system == 'Linux':
        try:
            with open('/proc/cpuinfo', 'r') as f:
                cpuinfo = f.read().lower()

            # Check for hypervisor flags
            if 'hypervisor' in cpuinfo:
                return True

            # Check for virtual CPU models
            virtual_indicators = ['qemu', 'kvm', 'virtual', 'vmware', 'xen']
            for indicator in virtual_indicators:
                if indicator in cpuinfo:
                    return True
        except FileNotFoundError:
            pass

    return False


def format_text_output(cpu_data: Dict[str, Any], verbose: bool = False) -> str:
    """Format CPU information as text."""
    lines = []

    lines.append("CPU Information")
    lines.append("=" * 50)
    lines.append("")

    # Basic info
    lines.append(f"Logical CPUs:  {cpu_data['count']['logical']}")
    lines.append(f"Physical CPUs: {cpu_data['count']['physical']}")

    if cpu_data.get('model'):
        lines.append(f"Model:         {cpu_data['model']}")

    if cpu_data.get('vendor'):
        lines.append(f"Vendor:        {cpu_data['vendor']}")

    if cpu_data.get('mhz'):
        lines.append(f"Frequency:     {cpu_data['mhz']:.2f} MHz")

    if cpu_data.get('cache_size'):
        lines.append(f"Cache Size:    {cpu_data['cache_size']}")

    # Cache info (macOS)
    for cache in ['l1icachesize', 'l1dcachesize', 'l2cachesize', 'l3cachesize']:
        if cpu_data.get(cache):
            cache_name = cache.replace('cachesize', '').upper()
            lines.append(f"{cache_name} Cache:     {cpu_data[cache]}")

    if cpu_data.get('virtual') is not None:
        lines.append(f"Virtual CPU:   {'Yes' if cpu_data['virtual'] else 'No'}")

    if cpu_data.get('usage') is not None:
        lines.append(f"CPU Usage:     {cpu_data['usage']:.1f}%")

    if cpu_data.get('temperature') is not None:
        lines.append(f"Temperature:   {cpu_data['temperature']:.1f}°C")

    lines.append(f"Platform:      {cpu_data['platform']}")
    lines.append(f"Architecture:  {cpu_data['architecture']}")

    if verbose and cpu_data.get('flags'):
        lines.append("")
        lines.append(f"CPU Flags ({cpu_data.get('flag_count', 0)}):")
        lines.append("-" * 50)

        # Display flags in columns
        flags = cpu_data['flags']
        col_width = 15
        cols = 4

        for i in range(0, len(flags), cols):
            row_flags = flags[i:i+cols]
            line = "  ".join(f"{flag:<{col_width}}" for flag in row_flags)
            lines.append(f"  {line}")
    elif cpu_data.get('flag_count'):
        lines.append(f"CPU Flags:     {cpu_data['flag_count']} features")

    return "\n".join(lines)


def format_json_output(cpu_data: Dict[str, Any]) -> str:
    """Format CPU information as JSON."""
    return json.dumps(cpu_data, indent=2)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Display detailed CPU information',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                  # Display CPU information
  %(prog)s --json           # JSON output
  %(prog)s --verbose        # Show all CPU flags/features
  %(prog)s -v --json        # Verbose JSON output
        """
    )

    parser.add_argument(
        '--json',
        action='store_true',
        help='Output in JSON format'
    )

    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show detailed CPU flags and features'
    )

    args = parser.parse_args()

    # Gather CPU information
    cpu_data = {
        'count': get_cpu_count(),
        'platform': platform.system(),
        'architecture': platform.machine(),
    }

    # Get platform-specific info
    system = platform.system()
    if system == 'Linux':
        cpu_data.update(get_cpu_info_linux())
    elif system == 'Darwin':
        cpu_data.update(get_cpu_info_macos())

    # Get dynamic info
    cpu_data['usage'] = get_cpu_usage()
    cpu_data['temperature'] = get_cpu_temperature()
    cpu_data['virtual'] = is_virtual_cpu()

    # Output
    if args.json:
        # If not verbose, remove flags from JSON
        if not args.verbose and 'flags' in cpu_data:
            flag_count = cpu_data.get('flag_count')
            del cpu_data['flags']
            if flag_count:
                cpu_data['flag_count'] = flag_count

        print(format_json_output(cpu_data))
    else:
        print(format_text_output(cpu_data, verbose=args.verbose))

    return 0


if __name__ == '__main__':
    sys.exit(main())

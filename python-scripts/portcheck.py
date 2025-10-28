#!/usr/bin/env python3
"""
Port connectivity checker with advanced features.

This script checks if a TCP/UDP port is open on a given host with support for
timeouts, port ranges, concurrent scanning, and JSON output.

Usage:
    python3 portcheck.py <host> <port> [options]
    python3 portcheck.py example.com 80
    python3 portcheck.py 192.168.1.1 22 --timeout 5
    python3 portcheck.py example.com 80-443 --json
"""

import sys
import socket
import argparse
import json
import time
from typing import Dict, List, Tuple
from concurrent.futures import ThreadPoolExecutor, as_completed


def check_port(host: str, port: int, timeout: int = 5, protocol: str = 'tcp') -> Dict[str, any]:
    """
    Check if a port is open on a host.

    Args:
        host: Hostname or IP address
        port: Port number to check
        timeout: Connection timeout in seconds
        protocol: Protocol to use ('tcp' or 'udp')

    Returns:
        Dictionary with check results including host, port, open status, error, and latency
    """
    result = {
        'host': host,
        'port': port,
        'protocol': protocol,
        'open': False,
        'error': None,
        'latency_ms': None
    }

    try:
        start_time = time.time()

        if protocol.lower() == 'tcp':
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result_code = sock.connect_ex((host, port))
            sock.close()
            result['open'] = (result_code == 0)

        elif protocol.lower() == 'udp':
            # UDP is connectionless, so we send a packet and wait for response
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.settimeout(timeout)
            try:
                sock.sendto(b'', (host, port))
                sock.recvfrom(1024)
                result['open'] = True
            except socket.timeout:
                # No response doesn't necessarily mean closed for UDP
                result['open'] = None  # Unknown
                result['error'] = 'No response (UDP is unreliable for port checking)'
            finally:
                sock.close()

        result['latency_ms'] = round((time.time() - start_time) * 1000, 2)

    except socket.gaierror as e:
        result['error'] = f'DNS resolution failed: {e}'
    except socket.timeout:
        result['error'] = 'Connection timeout'
    except PermissionError:
        result['error'] = 'Permission denied (may need root for some operations)'
    except OSError as e:
        result['error'] = f'OS error: {e}'
    except Exception as e:
        result['error'] = f'Unexpected error: {e}'

    return result


def check_port_range(host: str, start_port: int, end_port: int,
                     timeout: int = 5, protocol: str = 'tcp',
                     workers: int = 10) -> List[Dict]:
    """
    Check multiple ports concurrently.

    Args:
        host: Hostname or IP address
        start_port: Starting port number
        end_port: Ending port number (inclusive)
        timeout: Connection timeout in seconds
        protocol: Protocol to use ('tcp' or 'udp')
        workers: Number of concurrent workers

    Returns:
        List of result dictionaries for each port
    """
    results = []

    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(check_port, host, port, timeout, protocol): port
            for port in range(start_port, end_port + 1)
        }

        for future in as_completed(futures):
            try:
                results.append(future.result())
            except Exception as e:
                port = futures[future]
                results.append({
                    'host': host,
                    'port': port,
                    'protocol': protocol,
                    'open': False,
                    'error': f'Check failed: {e}',
                    'latency_ms': None
                })

    return sorted(results, key=lambda x: x['port'])


def validate_port(port: int) -> bool:
    """Validate port number is in valid range."""
    return 1 <= port <= 65535


def parse_port_argument(port_arg: str) -> Tuple[int, int]:
    """
    Parse port argument which can be a single port or range.

    Args:
        port_arg: Port string (e.g., '80' or '80-443')

    Returns:
        Tuple of (start_port, end_port)

    Raises:
        ValueError: If port format is invalid
    """
    if '-' in port_arg:
        parts = port_arg.split('-')
        if len(parts) != 2:
            raise ValueError('Invalid port range format. Use: start-end (e.g., 80-443)')

        start_port = int(parts[0])
        end_port = int(parts[1])

        if start_port > end_port:
            raise ValueError('Start port must be less than or equal to end port')

        if not validate_port(start_port) or not validate_port(end_port):
            raise ValueError('Port numbers must be between 1 and 65535')

        return start_port, end_port
    else:
        port = int(port_arg)
        if not validate_port(port):
            raise ValueError('Port number must be between 1 and 65535')
        return port, port


def format_output_text(results: List[Dict], verbose: bool = False) -> None:
    """Format and print results in human-readable text."""
    for r in results:
        if r['open']:
            status = '✓ OPEN'
            latency = f" ({r['latency_ms']}ms)" if r['latency_ms'] else ''
            print(f"{status:10} {r['host']}:{r['port']}{latency}")
        elif r['open'] is None:  # UDP unknown
            status = '? UNKNOWN'
            print(f"{status:10} {r['host']}:{r['port']} - {r['error']}")
        else:
            if verbose:
                status = '✗ CLOSED'
                error_msg = f" - {r['error']}" if r['error'] else ''
                print(f"{status:10} {r['host']}:{r['port']}{error_msg}")


def format_output_json(results: List[Dict]) -> None:
    """Format and print results as JSON."""
    print(json.dumps(results, indent=2))


def main():
    """Main entry point for the port checker."""
    parser = argparse.ArgumentParser(
        description='Check if TCP/UDP ports are open on a host',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s example.com 80
  %(prog)s 192.168.1.1 22 --timeout 5
  %(prog)s example.com 80-443 --json
  %(prog)s example.com 53 --protocol udp
  %(prog)s 10.0.0.1 1-1024 --workers 50
        """
    )

    parser.add_argument('host', help='Target hostname or IP address')
    parser.add_argument('port', help='Port number or range (e.g., 80 or 80-443)')
    parser.add_argument('-t', '--timeout', type=int, default=5,
                       help='Connection timeout in seconds (default: 5)')
    parser.add_argument('-p', '--protocol', choices=['tcp', 'udp'], default='tcp',
                       help='Protocol to use (default: tcp)')
    parser.add_argument('-j', '--json', action='store_true',
                       help='Output results in JSON format')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Show closed ports (only affects text output)')
    parser.add_argument('-w', '--workers', type=int, default=10,
                       help='Number of concurrent workers for port ranges (default: 10)')

    args = parser.parse_args()

    # Parse port argument
    try:
        start_port, end_port = parse_port_argument(args.port)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Perform port check(s)
    try:
        if start_port == end_port:
            # Single port
            results = [check_port(args.host, start_port, args.timeout, args.protocol)]
        else:
            # Port range
            if not args.json and not args.verbose:
                print(f"Scanning {args.host} ports {start_port}-{end_port}...")
            results = check_port_range(
                args.host, start_port, end_port,
                args.timeout, args.protocol, args.workers
            )

        # Output results
        if args.json:
            format_output_json(results)
        else:
            format_output_text(results, args.verbose)

        # Exit code: 0 if all checked ports are open, 1 if any are closed/error
        open_ports = [r for r in results if r['open'] is True]
        if open_ports and len(open_ports) == len(results):
            sys.exit(0)
        else:
            sys.exit(1)

    except KeyboardInterrupt:
        print("\n\nScan interrupted by user", file=sys.stderr)
        sys.exit(130)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

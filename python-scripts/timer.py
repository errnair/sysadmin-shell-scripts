#!/usr/bin/env python3
"""
Command Benchmarking Tool

Times command execution with support for multiple iterations, statistics,
and comparison mode.

Usage:
    python3 timer.py [options] command [command2 ...]
"""

import argparse
import json
import statistics
import subprocess
import sys
import time
from typing import List, Dict, Any, Optional


class BenchmarkResult:
    """Store and analyze benchmark results."""

    def __init__(self, command: str, iterations: int):
        self.command = command
        self.iterations = iterations
        self.times: List[float] = []
        self.success_count = 0
        self.failure_count = 0

    def add_time(self, elapsed: float, success: bool = True):
        """Add a timing result."""
        self.times.append(elapsed)
        if success:
            self.success_count += 1
        else:
            self.failure_count += 1

    def get_statistics(self) -> Dict[str, float]:
        """Calculate timing statistics."""
        if not self.times:
            return {}

        return {
            'min': min(self.times),
            'max': max(self.times),
            'mean': statistics.mean(self.times),
            'median': statistics.median(self.times),
            'stdev': statistics.stdev(self.times) if len(self.times) > 1 else 0.0,
            'total': sum(self.times)
        }

    def format_time(self, seconds: float) -> str:
        """Format time in human-readable format."""
        if seconds < 0.001:
            return f"{seconds * 1_000_000:.2f} μs"
        elif seconds < 1:
            return f"{seconds * 1000:.2f} ms"
        elif seconds < 60:
            return f"{seconds:.3f} s"
        else:
            minutes = int(seconds // 60)
            secs = seconds % 60
            return f"{minutes}m {secs:.2f}s"


def run_command(command: str, shell: bool = True, timeout: Optional[int] = None) -> tuple[float, bool, str]:
    """
    Run a command and measure its execution time.

    Returns:
        Tuple of (elapsed_time, success, output/error)
    """
    start_time = time.time()

    try:
        result = subprocess.run(
            command,
            shell=shell,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=True
        )
        elapsed = time.time() - start_time
        return (elapsed, True, result.stdout)

    except subprocess.CalledProcessError as e:
        elapsed = time.time() - start_time
        return (elapsed, False, e.stderr or str(e))

    except subprocess.TimeoutExpired:
        elapsed = time.time() - start_time
        return (elapsed, False, f"Command timed out after {timeout} seconds")

    except Exception as e:
        elapsed = time.time() - start_time
        return (elapsed, False, str(e))


def benchmark_command(
    command: str,
    iterations: int = 1,
    warmup: int = 0,
    timeout: Optional[int] = None,
    verbose: bool = False
) -> BenchmarkResult:
    """
    Benchmark a command over multiple iterations.

    Args:
        command: Command to benchmark
        iterations: Number of times to run
        warmup: Number of warmup runs (not counted)
        timeout: Command timeout in seconds
        verbose: Show detailed output

    Returns:
        BenchmarkResult with timing data
    """
    result = BenchmarkResult(command, iterations)

    # Warmup runs
    if warmup > 0 and verbose:
        print(f"  Warmup: {warmup} iteration(s)...", end='', flush=True)

    for _ in range(warmup):
        run_command(command, timeout=timeout)

    if warmup > 0 and verbose:
        print(" done")

    # Actual benchmark runs
    for i in range(iterations):
        if verbose and iterations > 1:
            print(f"  Iteration {i + 1}/{iterations}...", end='', flush=True)

        elapsed, success, output = run_command(command, timeout=timeout)
        result.add_time(elapsed, success)

        if verbose:
            if iterations > 1:
                print(f" {result.format_time(elapsed)}")
            if not success:
                print(f"  Error: {output}")

    return result


def format_text_output(results: List[BenchmarkResult], compare: bool = False) -> str:
    """Format benchmark results as text."""
    lines = []

    if compare and len(results) > 1:
        lines.append("Benchmark Comparison")
        lines.append("=" * 70)
        lines.append("")

        # Find fastest
        fastest_mean = min(r.get_statistics().get('mean', float('inf')) for r in results)

        for result in results:
            stats = result.get_statistics()
            if not stats:
                continue

            mean_time = stats['mean']
            ratio = mean_time / fastest_mean if fastest_mean > 0 else 0

            lines.append(f"Command: {result.command}")
            lines.append(f"  Mean:   {result.format_time(mean_time)}")
            lines.append(f"  Ratio:  {ratio:.2f}x {'(fastest)' if ratio == 1.0 else ''}")
            lines.append("")

    else:
        for result in results:
            lines.append("Benchmark Results")
            lines.append("=" * 70)
            lines.append("")
            lines.append(f"Command:    {result.command}")
            lines.append(f"Iterations: {result.iterations}")
            lines.append(f"Success:    {result.success_count}/{result.iterations}")
            lines.append("")

            stats = result.get_statistics()
            if stats:
                lines.append("Timing Statistics:")
                lines.append(f"  Minimum:    {result.format_time(stats['min'])}")
                lines.append(f"  Maximum:    {result.format_time(stats['max'])}")
                lines.append(f"  Mean:       {result.format_time(stats['mean'])}")
                lines.append(f"  Median:     {result.format_time(stats['median'])}")
                if stats['stdev'] > 0:
                    lines.append(f"  Std Dev:    {result.format_time(stats['stdev'])}")
                lines.append(f"  Total:      {result.format_time(stats['total'])}")

            if result.failure_count > 0:
                lines.append("")
                lines.append(f"Failures: {result.failure_count}")

            lines.append("")

    return "\n".join(lines)


def format_json_output(results: List[BenchmarkResult]) -> str:
    """Format benchmark results as JSON."""
    output = []

    for result in results:
        stats = result.get_statistics()

        data = {
            'command': result.command,
            'iterations': result.iterations,
            'success_count': result.success_count,
            'failure_count': result.failure_count,
            'times': result.times,
            'statistics': stats
        }

        output.append(data)

    return json.dumps(output if len(output) > 1 else output[0], indent=2)


def format_csv_output(results: List[BenchmarkResult]) -> str:
    """Format benchmark results as CSV."""
    lines = []

    # Header
    lines.append("command,iteration,time_seconds,success")

    # Data
    for result in results:
        for i, time_val in enumerate(result.times, 1):
            success = "true" if i <= result.success_count else "false"
            lines.append(f'"{result.command}",{i},{time_val:.6f},{success}')

    return "\n".join(lines)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Benchmark command execution time',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s "ls -la"                         # Time a single command
  %(prog)s -n 10 "curl https://example.com" # Run 10 times
  %(prog)s --json "python script.py"        # JSON output
  %(prog)s --compare "cmd1" "cmd2"          # Compare two commands
  %(prog)s -n 100 --warmup 5 "echo test"    # 5 warmup + 100 iterations
  %(prog)s --csv "ls" > results.csv         # Export to CSV
        """
    )

    parser.add_argument(
        'commands',
        nargs='+',
        help='Command(s) to benchmark'
    )

    parser.add_argument(
        '-n', '--iterations',
        type=int,
        default=1,
        help='Number of iterations to run (default: 1)'
    )

    parser.add_argument(
        '--warmup',
        type=int,
        default=0,
        help='Number of warmup runs (default: 0)'
    )

    parser.add_argument(
        '--timeout',
        type=int,
        default=None,
        help='Command timeout in seconds (default: none)'
    )

    parser.add_argument(
        '--compare',
        action='store_true',
        help='Compare multiple commands'
    )

    parser.add_argument(
        '--json',
        action='store_true',
        help='Output in JSON format'
    )

    parser.add_argument(
        '--csv',
        action='store_true',
        help='Output in CSV format'
    )

    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show detailed progress'
    )

    args = parser.parse_args()

    # Validate arguments
    if args.iterations < 1:
        print("Error: iterations must be at least 1", file=sys.stderr)
        return 1

    if args.compare and len(args.commands) < 2:
        print("Error: compare mode requires at least 2 commands", file=sys.stderr)
        return 1

    # Run benchmarks
    results = []

    for command in args.commands:
        if args.verbose:
            print(f"Benchmarking: {command}")

        result = benchmark_command(
            command,
            iterations=args.iterations,
            warmup=args.warmup,
            timeout=args.timeout,
            verbose=args.verbose
        )
        results.append(result)

        if args.verbose and len(args.commands) > 1:
            print("")

    # Output results
    if args.json:
        print(format_json_output(results))
    elif args.csv:
        print(format_csv_output(results))
    else:
        print(format_text_output(results, compare=args.compare))

    # Exit with error if any command failed
    total_failures = sum(r.failure_count for r in results)
    return 1 if total_failures > 0 else 0


if __name__ == '__main__':
    sys.exit(main())

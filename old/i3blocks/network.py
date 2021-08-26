#!/usr/bin/env python

import argparse
import json
import subprocess


def human_readable(num_bytes):
    SUFFIXES = ['B', 'K', 'M', 'G']
    rounds = 0
    while num_bytes >= 1024:
        num_bytes = num_bytes / 1024
        rounds += 1

    return f'{num_bytes:.2f}{SUFFIXES[rounds]}'


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('DEVICE')

    return parser.parse_args()


def get_net_use(dev):
    proc = subprocess.run(
        ['ifstat', dev, '-j'],
        stdout=subprocess.PIPE,
    )

    try:
        data = json.loads(proc.stdout.decode('utf-8'))['kernel'][dev]
    except KeyError:
        return None

    down = human_readable(data['rx_bytes'])
    up = human_readable(data['tx_bytes'])
    return f'{down}/{up}'


def get_ip(dev):
    ip_addrs = []

    proc = subprocess.run(
        ['ip', 'address', 'show', 'dev', dev],
        stdout=subprocess.PIPE,
    )

    stdout_lines = proc.stdout.decode('utf-8').splitlines()

    for line in stdout_lines:
        line = line.strip()
        if line.startswith('inet'):
            ip_addrs.append(line.split()[1])

    return ip_addrs


def main():
    args = parse_args()

    use = get_net_use(args.DEVICE)

    ips = get_ip(args.DEVICE)

    print(f'{ips[0]}: {use}')


if __name__ == '__main__':
    main()

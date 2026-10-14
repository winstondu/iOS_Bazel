#!/usr/bin/env python3
"""Exercise the real MCP -> SourceKit-LSP -> Bazel BSP connection."""
import argparse
import json
import os
from pathlib import Path
import queue
import signal
import subprocess
import threading
import time
import tomllib


class MCPClient:
    def __init__(self, root, log):
        config = tomllib.loads((root / '.codex/config.toml').read_text())['mcp_servers']['swift']
        self.proc = subprocess.Popen(
            [config['command'], *config.get('args', [])], cwd=root,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=log,
            text=True, bufsize=1, start_new_session=True,
        )
        self.messages = queue.Queue()
        self.transcript = []
        self.next_id = 0
        threading.Thread(target=self.read, daemon=True).start()

    def read(self):
        for line in self.proc.stdout:
            try:
                self.messages.put(json.loads(line))
            except json.JSONDecodeError:
                self.messages.put({'invalid_stdout': line})
        self.messages.put({'eof': True})

    def notify(self, method, params):
        notification = {'jsonrpc': '2.0', 'method': method, 'params': params}
        self.transcript.append({'notification': notification})
        self.proc.stdin.write(json.dumps(notification) + '\n')
        self.proc.stdin.flush()

    def request(self, method, params, timeout=180):
        self.next_id += 1
        request = {'jsonrpc': '2.0', 'id': self.next_id, 'method': method, 'params': params}
        self.transcript.append({'request': request})
        self.proc.stdin.write(json.dumps(request) + '\n')
        self.proc.stdin.flush()
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            try:
                response = self.messages.get(timeout=max(0.1, deadline - time.monotonic()))
            except queue.Empty:
                raise TimeoutError(f'MCP request timed out: {method}') from None
            self.transcript.append({'response': response})
            if 'eof' in response or 'invalid_stdout' in response:
                raise RuntimeError(f'MCP transport failed: {response}; see mcp-stderr.log')
            if response.get('id') == self.next_id:
                if 'error' in response or response.get('result', {}).get('isError'):
                    raise RuntimeError(response)
                return response['result']
        raise TimeoutError(method)

    def tool(self, name, arguments):
        result = self.request('tools/call', {'name': name, 'arguments': arguments})
        return '\n'.join(item.get('text', '') for item in result.get('content', []))

    def close(self):
        self.proc.stdin.close()
        try:
            self.proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(self.proc.pid, signal.SIGTERM)
            self.proc.wait(timeout=10)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--file', default='App/HelloWorldApp.swift')
    parser.add_argument('--symbol', default='ContentView')
    parser.add_argument('--definition-file', default='ContentView.swift')
    parser.add_argument('--diagnostics-probe', action='store_true',
                        help='Temporarily append a type error, check diagnostics, then restore the file')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    path = root / args.file
    original = path.read_bytes()
    probe_contents = None

    def restore_probe():
        if path.read_bytes() != probe_contents:
            raise RuntimeError(f'{path} changed during the probe; refusing to overwrite concurrent edits')
        path.write_bytes(original)
    lines = original.decode().splitlines()
    line = next(i for i, text in enumerate(lines)
                if args.symbol in text and not text.lstrip().startswith('//'))
    character = len(lines[line][:lines[line].index(args.symbol)].encode('utf-16-le')) // 2
    position = {'file_path': str(path), 'line': line, 'character': character}
    output = root / '.tools/verification' / f'{path.stem}-{args.symbol}'
    output.mkdir(parents=True, exist_ok=True)
    with (output / 'mcp-stderr.log').open('w') as log:
        client = MCPClient(root, log)
        try:
            result = client.request('initialize', {
                'protocolVersion': '2024-11-05', 'capabilities': {},
                'clientInfo': {'name': 'bazel-template-verifier', 'version': '1.0'},
            })
            print('MCP initialized:', result.get('serverInfo'), flush=True)
            client.notify('notifications/initialized', {})
            names = {tool['name'] for tool in client.request('tools/list', {})['tools']}
            assert {'get_hover_info', 'get_definition', 'get_diagnostics',
                    'find_symbols', 'search_workspace_symbols'} <= names
            # Repeated queries tolerate a genuinely cold Bazel index; no mocked responses.
            deadline = time.monotonic() + 600
            while True:
                hover = client.tool('get_hover_info', position)
                definition = client.tool('get_definition', position)
                if args.symbol in hover and args.definition_file in definition:
                    break
                if time.monotonic() > deadline:
                    raise RuntimeError(f'Semantic check failed: hover={hover}, definition={definition}')
                print('Waiting for Bazel index preparation...', flush=True)
                time.sleep(3)
            print('Hover:', hover, flush=True)
            print('Definition:', definition, flush=True)
            symbols = client.tool('find_symbols', {'file_path': str(path), 'name_pattern': ''})
            assert symbols and symbols != 'No results.', symbols
            print('Document symbols:', symbols, flush=True)
            # workspace/symbol searches project declarations. External dependency
            # navigation is checked through get_definition above.
            if root.as_uri() + '/' in definition:
                deadline = time.monotonic() + 120
                while True:
                    workspace_symbols = client.tool('search_workspace_symbols', {'query': args.symbol})
                    if args.symbol in workspace_symbols and args.definition_file in workspace_symbols:
                        break
                    if time.monotonic() > deadline:
                        raise AssertionError(f'Missing indexed workspace symbol: {workspace_symbols}')
                    time.sleep(2)
                print('Workspace symbols:', workspace_symbols, flush=True)
            else:
                print('External definition: workspace-symbol check applies to project declarations only.', flush=True)
            diagnostics = client.tool('get_diagnostics', {'file_path': str(path)})
            assert '[error]' not in diagnostics, diagnostics
            print('App diagnostics:', diagnostics, flush=True)
            if args.diagnostics_probe:
                if path.read_bytes() != original:
                    raise RuntimeError(f'{path} changed during verification; refusing to append the probe')
                probe_contents = original + b'\nprivate let sourcekitDiagnosticProbe: Int = "SourceKit probe"\n'
                path.write_bytes(probe_contents)
                deadline = time.monotonic() + 45
                while True:
                    diagnostics = client.tool('get_diagnostics', {'file_path': str(path)})
                    if '[error]' in diagnostics and 'Int' in diagnostics:
                        break
                    if time.monotonic() > deadline:
                        raise AssertionError(diagnostics)
                    time.sleep(1)
                print('Deliberate type-error diagnostic:', diagnostics, flush=True)
                restore_probe()
                probe_contents = None
                deadline = time.monotonic() + 45
                while True:
                    restored = client.tool('get_diagnostics', {'file_path': str(path)})
                    if '[error]' not in restored:
                        break
                    if time.monotonic() > deadline:
                        raise AssertionError(restored)
                    time.sleep(1)
                print('Restored file diagnostics:', restored, flush=True)
            print('PASS: configured MCP launch and semantic checks.', flush=True)
        finally:
            if probe_contents is not None and path.read_bytes() == probe_contents:
                path.write_bytes(original)
            (output / 'mcp-transcript.json').write_text(json.dumps(client.transcript, indent=2) + '\n')
            client.close()


if __name__ == '__main__':
    main()

"""Offline regression tests. Run: python -m unittest discover -s tests -v"""
import asyncio
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import threading
import types
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'skill-creator'))
from scripts.model_api import ModelClient, resolve_model
from scripts.run_eval import run_single_query, run_eval
from scripts.improve_description import _call_model
from scripts.utils import parse_skill_md


def load_mcp_module():
    # Test the model loop independently of the optional MCP transport dependency.
    spec = importlib.util.spec_from_file_location('evaluation_test', ROOT / 'mcp-builder/scripts/evaluation.py')
    module = importlib.util.module_from_spec(spec)
    with patch.dict(sys.modules, {'connections': types.SimpleNamespace(create_connection=None),
                                'model_api': sys.modules['scripts.model_api']}):
        spec.loader.exec_module(module)
    return module


class ModelScriptsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.requests = []
        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                payload = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                cls.requests.append((self.path, dict(self.headers), payload))
                text = payload['messages'][-1]['content']
                if text == 'error':
                    self.send_error(503)
                    return
                if text == 'malformed':
                    result = {'choices': []}
                else:
                    message = {'role': 'assistant', 'content': '<new_description>Helps write reports.</new_description>'}
                    if text in ('trigger', 'wrong'):
                        message.update(content=None, tool_calls=[{'id': 'one', 'type': 'function',
                            'function': {'name': 'read_skill', 'arguments': json.dumps({'skill': 'reports' if text == 'trigger' else 'other'})}}])
                    result = {'choices': [{'message': message}]}
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(result).encode())
            def log_message(self, *args):
                pass
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def setUp(self):
        self.env = patch.dict(os.environ, {'BIG_THINKER_URL': f'http://127.0.0.1:{self.server.server_port}/v1/', 'MODEL_NAME': 'test-model', 'BIG_THINKER_API_KEY': 'test-key'}, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_request_configuration_and_text(self):
        self.assertIn('Helps write reports', _call_model('describe', None))
        path, headers, payload = self.requests[-1]
        self.assertEqual(path, '/v1/chat/completions')
        self.assertEqual(headers['Authorization'], 'Bearer test-key')
        self.assertEqual(payload['model'], 'test-model')
        self.assertNotIn('tools', payload)
        self.assertEqual(resolve_model('override'), 'override')

    def test_inherited_model_and_local_no_auth(self):
        with patch.dict(os.environ, {'MODEL_NAME': 'active-aitui-model', 'BIG_THINKER_URL': 'http://localhost/v1'}, clear=True):
            self.assertEqual(resolve_model(), 'active-aitui-model')
            client = ModelClient()
            self.assertEqual(client.base_url, 'http://localhost/v1')
            self.assertIsNone(client.api_key)
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ValueError):
                resolve_model()
            with self.assertRaisesRegex(ValueError, "BIG_THINKER_URL"):
                ModelClient()

    def test_trigger_and_no_trigger(self):
        self.assertTrue(run_single_query('trigger', 'reports', 'Write reports.', 5, '.'))
        self.assertFalse(run_single_query('wrong', 'reports', 'Write reports.', 5, '.'))
        self.assertFalse(run_single_query('plain', 'reports', 'Write reports.', 5, '.'))
        self.assertEqual(self.requests[-1][2]['tools'][0]['function']['name'], 'read_skill')

    def test_api_errors_and_malformed_response(self):
        for query in ('error', 'malformed'):
            with self.assertRaises(RuntimeError):
                _call_model(query, None)
        results = run_eval([{'query': 'error', 'should_trigger': False}], 'reports', 'Write reports.', 1, 5, ROOT)
        self.assertFalse(results['results'][0]['pass'])
        self.assertTrue(results['results'][0]['errors'])

    def test_sibling_description(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / 'SKILL.md').write_text('---\nname: example\ndescription: obsolete\n---\nBody')
            (path / 'description.md').write_text('Helps write reports.\n')
            self.assertEqual(parse_skill_md(path)[:2], ('example', 'Helps write reports.'))

    def test_mcp_multiple_tools_and_error_result(self):
        module = load_mcp_module()
        class Client:
            def __init__(self):
                self.rounds = 0
            def chat(self, messages, model, tools):
                self.rounds += 1
                self.assert_tools = tools
                if self.rounds == 1:
                    return {'content': None, 'tool_calls': [
                        {'id': 'a', 'type': 'function', 'function': {'name': 'good', 'arguments': '{"x":1}'}},
                        {'id': 'b', 'type': 'function', 'function': {'name': 'bad', 'arguments': '{}'}}]}
                self.final_messages = messages
                return {'content': '<response>done</response>'}
        class Connection:
            async def call_tool(self, name, args):
                if name == 'bad':
                    raise ValueError('failed')
                return {'value': args['x']}
        client = Client()
        text, metrics = asyncio.run(module.agent_loop(client, 'test', 'question',
            [{'name': 'good', 'description': 'Tool', 'input_schema': {'type': 'object'}}], Connection()))
        self.assertEqual(text, '<response>done</response>')
        self.assertEqual(metrics['good']['count'], 1)
        self.assertEqual(metrics['bad']['count'], 1)
        self.assertEqual(client.assert_tools[0]['function']['parameters'], {'type': 'object'})
        results = [m for m in client.final_messages if m['role'] == 'tool']
        self.assertEqual([m['tool_call_id'] for m in results], ['a', 'b'])
        self.assertIn('failed', results[1]['content'])

    def test_mcp_empty_tools_and_round_limit(self):
        module = load_mcp_module()
        class Client:
            def chat(self, messages, model, tools):
                return {'content': 'done'}
        self.assertEqual(asyncio.run(module.agent_loop(Client(), 'test', 'q', [], None)), ('done', {}))
        class LoopClient:
            def chat(self, messages, model, tools):
                return {'content': None, 'tool_calls': [{'id': str(len(messages)), 'type': 'function', 'function': {'name': 'tool', 'arguments': '{}'}}]}
        with self.assertRaisesRegex(RuntimeError, '50-round'):
            asyncio.run(module.agent_loop(LoopClient(), 'test', 'q', [], None))

    def test_adapters_remain_identical(self):
        self.assertEqual((ROOT / 'skill-creator/scripts/model_api.py').read_bytes(),
                         (ROOT / 'mcp-builder/scripts/model_api.py').read_bytes())


if __name__ == '__main__':
    unittest.main()

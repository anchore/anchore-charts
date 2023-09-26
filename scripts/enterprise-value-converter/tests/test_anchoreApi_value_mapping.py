import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsApi(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreApi_replicaCount_value(self):
        dot_string_dict = {
            "anchoreApi.replicaCount": 2,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_extraEnv_value(self):
        dot_string_dict = {
            "anchoreApi.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'extraEnv': [
                    {
                        "name": "foo",
                        "value": "bar"
                    }
                ]
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_service_value(self):
        dot_string_dict = {
            "anchoreApi.service.name": "null",
            "anchoreApi.service.type": "ClusterIP",
            "anchoreApi.service.port": 8228,
            "anchoreApi.service.annotations.foo": "bar",
            "anchoreApi.service.annotations.baz": "qux",
            "anchoreApi.service.annotations.with.a.dot.foobar": "baz",
            "anchoreApi.service.labels.foobar": "baz",
            "anchoreApi.service.labels.with.a.dot.foobar": "baz"
        }

        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'service': {
                    "name": "null",
                    "type": "ClusterIP",
                    "port": 8228,
                    "annotations": {
                        "foo": "bar",
                        "baz": "qux",
                        "with.a.dot.foobar": "baz"
                    },
                    "labels": {
                        "foobar": "baz",
                        "with.a.dot.foobar": "baz"
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreApi.serviceAccountName": "Null"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_resources_value(self):
        dot_string_dict = {
            "anchoreApi.resources.limits.cpu": 1,
            "anchoreApi.resources.limits.memory": "4G",
            "anchoreApi.resources.requests.cpu": 1,
            "anchoreApi.resources.requests.memory": "1G",
            }

        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'resources': {
                    'limits': {
                        'cpu': 1,
                        'memory': '4G'
                    },
                    'requests': {
                        'cpu': 1,
                        'memory': '1G'
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_labels_value(self):
        dot_string_dict = {
            "anchoreApi.labels.name": "foo",
            "anchoreApi.labels.value": "bar",
            "anchoreApi.labels.anotherLabel.with.a.dot": "baz",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'labels':
                    {
                        'name': 'foo',
                        'value': 'bar',
                        'anotherLabel.with.a.dot': 'baz'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_annotations_value(self):
        dot_string_dict = {
            "anchoreApi.annotations.foo": "bar",
            "anchoreApi.annotations.baz": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'annotations':
                    {
                        'foo': 'bar',
                        'baz': 'qux'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreApi.deploymentAnnotations.name": "foo",
            "anchoreApi.deploymentAnnotations.mydot.value": "bar"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'deploymentAnnotations': {
                    'name': 'foo',
                    'mydot.value': 'bar'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreApi.nodeSelector.name": "foo",
            "anchoreApi.nodeSelector.value": "bar"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'nodeSelector':
                    {
                        'name': 'foo',
                        'value': 'bar'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_tolerations_value(self):
        dot_string_dict = {
            "anchoreApi.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'tolerations': [
                    {
                        'name': 'foo',
                        'value': 'bar'
                    }
                ]
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_affinity_value(self):
        dot_string_dict = {
            "anchoreApi.affinity.name": "foo",
            "anchoreApi.affinity.value": "bar"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'api': {
                'affinity': {
                    'name': 'foo',
                    'value': 'bar'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreApi_external_value(self):
        dot_string_dict = {
            "anchoreApi.external.use_tls": True,
            "anchoreApi.external.hostname": "anchore-api.example.com",
            "anchoreApi.external.port": 8443
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'apiext': {
                    'external': {
                        'useTLS': True,
                        'hostname': 'anchore-api.example.com',
                        'port': 8443
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)

        self.assertEqual(result[0], expected_result)

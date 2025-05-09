import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsPolicyEngine(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchorePolicyEngine_replicaCount_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.replicaCount": 2,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchorePolicyEngine_resources_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.resources.limits.cpu": 1,
            "anchorePolicyEngine.resources.limits.memory": "4G",
            "anchorePolicyEngine.resources.requests.cpu": 1,
            "anchorePolicyEngine.resources.requests.memory": "1G"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
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

    def test_anchorePolicyEngine_labels_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.labels.foobar": "baz",
            "anchorePolicyEngine.labels.with.a.dot.foobar": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'labels':
                    {
                        'foobar': 'baz',
                        'with.a.dot.foobar': 'baz'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_annotations_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.annotations.foobar": "baz",
            "anchorePolicyEngine.annotations.with.a.dot.foobar": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'annotations':
                    {
                        'foobar': 'baz',
                        'with.a.dot.foobar': 'baz'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.deploymentAnnotations.foobar": "baz",
            "anchorePolicyEngine.deploymentAnnotations.with.a.dot.foobar": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'deploymentAnnotations': {
                    'foobar': 'baz',
                    'with.a.dot.foobar': 'baz'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_nodeSelector_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.nodeSelector.name": "foo",
            "anchorePolicyEngine.nodeSelector.with.a.dot.name": "bar"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'nodeSelector': {
                    'name': 'foo',
                    'with.a.dot.name': 'bar'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_tolerations_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.tolerations": [
                {
                    "key": "key",
                    "operator": "Equal",
                    "value": "value",
                    "effect": "NoSchedule"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'tolerations': [
                    {
                        'key': 'key',
                        'operator': 'Equal',
                        'value': 'value',
                        'effect': 'NoSchedule'
                    }
                ]
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_affinity_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.affinity.name": "foo"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'affinity':
                    {
                        'name': 'foo'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_extraEnv_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
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

    def test_anchorePolicyEngine_serviceAccountName_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.serviceAccountName": "Null"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchorePolicyEngine_service_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.service.name": "Null",
            "anchorePolicyEngine.service.type": "ClusterIP",
            "anchorePolicyEngine.service.port": 8087,
            "anchorePolicyEngine.service.annotations.foo": "bar",
            "anchorePolicyEngine.service.annotations.with.a.dot": "qux",
            "anchorePolicyEngine.service.labels.foobar": "baz",
            "anchorePolicyEngine.service.labels.with.a.dot": "qux",
        }

        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'policyEngine': {
                'service': {
                    "name": "Null",
                    "type": "ClusterIP",
                    "port": 8087,
                    "annotations": {
                        "foo": "bar",
                        "with.a.dot": "qux"
                    },
                    "labels": {
                        "foobar": "baz",
                        "with.a.dot": "qux"
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_cycleTimers_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.cycleTimers.feed_sync": 14400,
            "anchorePolicyEngine.cycleTimers.feed_sync_checker": 3600,
            "anchorePolicyEngine.cycleTimers.grypedb_sync": 60,
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'policy_engine': {
                    'cycle_timers': {
                        "feed_sync": 14400,
                        "feed_sync_checker": 3600,
                        "grypedb_sync": 60,
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchorePolicyEngine_overrideFeedsToUpstream_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.overrideFeedsToUpstream": True
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'policy_engine': {
                    'overrideFeedsToUpstream': True
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    # Values that become environment variables for Anchore Policy Engine
    def test_anchorePolicyEngine_cacheTTL_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.cacheTTL": 3600,
        }

        expected_result = {
            'policyEngine': {
                'extraEnv': [
                    {
                        'name': 'ANCHORE_POLICY_EVAL_CACHE_TTL_SECONDS',
                        'value': 3600
                    }
                ]
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[1], expected_result)

    def test_anchorePolicyEngine_enablePackageDbLoad_value(self):
        dot_string_dict = {
            "anchorePolicyEngine.enablePackageDbLoad": True,
        }

        expected_result = {
            'policyEngine': {
                'extraEnv': [
                    {
                        'name': 'ANCHORE_POLICY_ENGINE_ENABLE_PACKAGE_DB_LOAD',
                        'value': False
                    }
                ]
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[1], expected_result)

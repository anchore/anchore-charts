import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsAnalyzer(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreAnalyzer_replicaCount_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.replicaCount": 2,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_containerPort_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.containerPort": 8084,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'service': {
                    'port': 8084
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_extraEnv_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'extraEnv': [
                    {
                        'name': 'foo',
                        'value': 'bar'
                    }
                ]
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.serviceAccountName": "foo",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'serviceAccountName': 'foo'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_resources_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.resources.limits.cpu": 1,
            "anchoreAnalyzer.resources.limits.memory": "4G",
            "anchoreAnalyzer.resources.requests.cpu": 1,
            "anchoreAnalyzer.resources.requests.memory": "1G",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
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

    def test_anchoreAnalyzer_labels_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.labels.name": "foo",
            "anchoreAnalyzer.labels.value": "bar",
            "anchoreAnalyzer.labels.kubernetes.io/description": "baz",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'labels':
                    {
                        'name': 'foo',
                        'value': 'bar',
                        'kubernetes.io/description': 'baz'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_annotations_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.annotations.name": "foo",
            "anchoreAnalyzer.annotations.value": "bar",
            "anchoreAnalyzer.annotations.kubernetes.io/description": "baz",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'annotations':
                    {
                        'name': 'foo',
                        'value': 'bar',
                        'kubernetes.io/description': 'baz'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreanalyzer_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.deploymentAnnotations.name": "foo",
            "anchoreAnalyzer.deploymentAnnotations.value": "bar",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'deploymentAnnotations': {
                    'name': 'foo',
                    'value': 'bar'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.nodeSelector.name": "foo",
            "anchoreAnalyzer.nodeSelector.value": "bar",

        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'nodeSelector':
                    {
                        'name': 'foo',
                        'value': 'bar'
                    }

            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_tolerations_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
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

    def test_anchoreAnalyzer_affinity_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.affinity.name": "foo",
            "anchoreAnalyzer.affinity.value": "bar",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'analyzer': {
                'affinity': {
                    'name': 'foo',
                    'value': 'bar'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_cycleTimers_image_analyzer_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.cycleTimers.image_analyzer": 1,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'analyzer': {
                    'cycle_timers': {
                        'image_analyzer': 1
                    }
                }
            }

        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_layerCacheMaxGigabytes_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.layerCacheMaxGigabytes": 1,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'analyzer': {
                    'layer_cache_max_gigabytes': 1
                }
            }

        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_enableHints_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.enableHints": False,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'analyzer': {
                    'enable_hints': False
                }
            }

        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreAnalyzer_configFile_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.configFile.retrieve_files.file_list": [
                "/etc/passwd"
            ],
            "anchoreAnalyzer.configFile.secret_search.match_params": [
                "MAXFILESIZE=10000",
                "STOREONMATCH=n"
            ],
            "anchoreAnalyzer.configFile.secret_search.regexp_match": [
                "AWS_ACCESS_KEY=(?i).*aws_access_key_id( *=+ *).*(?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9]).*",
                "AWS_SECRET_KEY=(?i).*aws_secret_access_key( *=+ *).*(?<![A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=]).*"
            ],
            "anchoreAnalyzer.configFile.content_search.match_params": [
                "MAXFILESIZE=10000"
            ],
            "anchoreAnalyzer.configFile.content_search.regexp_match": [
                "EXAMPLE_MATCH="
            ],
            "anchoreAnalyzer.configFile.malware.clamav.enabled": True,
            "anchoreAnalyzer.configFile.malware.clamav.db_update_enabled": True,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'analyzer': {
                    'configFile': {
                        'retrieve_files': {
                            'file_list': ['/etc/passwd']
                        },
                        'secret_search': {
                            'match_params': ['MAXFILESIZE=10000', 'STOREONMATCH=n'],
                            'regexp_match': [
                                'AWS_ACCESS_KEY=(?i).*aws_access_key_id( *=+ *).*(?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9]).*',
                                'AWS_SECRET_KEY=(?i).*aws_secret_access_key( *=+ *).*(?<![A-Za-z0-9/+=])[A-Za-z0-9/+=]{40}(?![A-Za-z0-9/+=]).*'
                            ]
                        },
                        'content_search': {
                            'match_params': ['MAXFILESIZE=10000'],
                            'regexp_match': ['EXAMPLE_MATCH=']
                        },
                        'malware': {
                            'clamav': {
                                'enabled': True,
                                'db_update_enabled': True
                            }
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    # Values that become environment variables for Anchore Analyzer
    def test_enableOwnedPackageFiltering_value(self):
        dot_string_dict = {
            "anchoreAnalyzer.enableOwnedPackageFiltering": True,
        }
        expected_result = {
                'analyzer': {
                    'extraEnv': [
                        {
                            'name': 'ANCHORE_OWNED_PACKAGE_FILTERING_ENABLED',
                            'value': True
                        }
                    ]
                }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], {'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}}})
        self.assertEqual(result[1], expected_result)

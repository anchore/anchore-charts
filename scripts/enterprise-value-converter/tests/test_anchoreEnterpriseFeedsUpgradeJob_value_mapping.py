import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsAnchoreEnterpriseFeedsUpgradeJob(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreEnterpriseFeedsUpgradeJob_enabled_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.enabled": True,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'enabled': True
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeedsUpgradeJob_resources_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.resources.limits.cpu": 1,
            "anchoreEnterpriseFeedsUpgradeJob.resources.limits.memory": "4G",
            "anchoreEnterpriseFeedsUpgradeJob.resources.requests.cpu": 1,
            "anchoreEnterpriseFeedsUpgradeJob.resources.requests.memory": "1G"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
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
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreEnterpriseFeedsUpgradeJob_labels_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.labels.myLabel": "myValue",
            "anchoreEnterpriseFeedsUpgradeJob.labels.myOtherLabel": "myOtherValue",
            "anchoreEnterpriseFeedsUpgradeJob.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'labels':
                        {
                            'myLabel': 'myValue',
                            'myOtherLabel': 'myOtherValue',
                            'anotherLabel.with.a.dot': 'qux'
                        }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeedsUpgradeJob_annotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.annotations.foo": "bar",
            "anchoreEnterpriseFeedsUpgradeJob.annotations.bar": "baz",
            "anchoreEnterpriseFeedsUpgradeJob.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'annotations':
                        {
                            'foo': 'bar',
                            'bar': 'baz',
                            'anotherLabel.with.a.dot': 'qux'
                        }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeedsUpgradeJob_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.nodeSelector.name": "foo",
            "anchoreEnterpriseFeedsUpgradeJob.nodeSelector.value": "bar",
            "anchoreEnterpriseFeedsUpgradeJob.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'nodeSelector':
                        {
                            'name': 'foo',
                            'value': 'bar',
                            'anotherLabel.with.a.dot': 'baz'
                        }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeedsUpgradeJob_tolerations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'tolerations': [
                        {
                            'name': 'foo',
                            'value': 'bar'
                        }
                    ]
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeedsUpgradeJob_affinity_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.affinity.name": "foo",
            "anchoreEnterpriseFeedsUpgradeJob.affinity.value": "bar",
            "anchoreEnterpriseFeedsUpgradeJob.affinity.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'affinity':{
                        'name': 'foo',
                        'value': 'bar',
                        'anotherLabel.with.a.dot': 'baz'
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeedsUpgradeJob_extraEnv_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'extraEnv': [
                        {
                            "name": "foo",
                            "value": "bar"
                        }
                    ]
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeedsUpgradeJob_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeedsUpgradeJob.serviceAccountName": "Null"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feedsUpgradeJob': {
                    'serviceAccountName': "Null"
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

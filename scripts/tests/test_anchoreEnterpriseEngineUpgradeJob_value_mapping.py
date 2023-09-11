import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsAnchoreEnterpriseEngineUpgradeJob(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreEnterpriseEngineUpgradeJob_enabled_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.enabled": True
        }
        expected_result = {
            'upgradeJob': {
                'enabled': True
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseEngineUpgradeJob_resources_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.resources.limits.cpu": 1,
            "anchoreEnterpriseEngineUpgradeJob.resources.limits.memory": "4G",
            "anchoreEnterpriseEngineUpgradeJob.resources.requests.cpu": 1,
            "anchoreEnterpriseEngineUpgradeJob.resources.requests.memory": "1G"
        }
        expected_result = {
            'upgradeJob': {
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


    def test_anchoreEnterpriseEngineUpgradeJob_labels_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.labels.myLabel": "myValue",
            "anchoreEnterpriseEngineUpgradeJob.labels.myOtherLabel": "myOtherValue",
            "anchoreEnterpriseEngineUpgradeJob.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = {
            'upgradeJob': {
                'labels':
                    {
                        'myLabel': 'myValue',
                        'myOtherLabel': 'myOtherValue',
                        'anotherLabel.with.a.dot': 'qux'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseEngineUpgradeJob_annotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.annotations.foo": "bar",
            "anchoreEnterpriseEngineUpgradeJob.annotations.bar": "baz",
            "anchoreEnterpriseEngineUpgradeJob.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = {
            'upgradeJob': {
                'annotations':
                    {
                        'foo': 'bar',
                        'bar': 'baz',
                        'anotherLabel.with.a.dot': 'qux'
                    }

            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseEngineUpgradeJob_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.nodeSelector.name": "foo",
            "anchoreEnterpriseEngineUpgradeJob.nodeSelector.value": "bar",
            "anchoreEnterpriseEngineUpgradeJob.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = {
            'upgradeJob': {
                'nodeSelector':
                    {
                        'name': 'foo',
                        'value': 'bar',
                        'anotherLabel.with.a.dot': 'baz'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseEngineUpgradeJob_tolerations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = {
            'upgradeJob': {
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

    def test_anchoreEnterpriseEngineUpgradeJob_affinity_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.affinity.name": "foo",
            "anchoreEnterpriseEngineUpgradeJob.affinity.value": "bar",
            "anchoreEnterpriseEngineUpgradeJob.affinity.anotherLabel.with.a.dot": "baz"
        }
        expected_result = {
            'upgradeJob': {
                'affinity':{
                    'name': 'foo',
                    'value': 'bar',
                    'anotherLabel.with.a.dot': 'baz'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseEngineUpgradeJob_extraEnv_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = {
            'upgradeJob': {
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

    def test_anchoreEnterpriseEngineUpgradeJob_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreEnterpriseEngineUpgradeJob.serviceAccountName": "Null"
        }
        expected_result = {
            'upgradeJob': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

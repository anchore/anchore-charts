import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsEngineUpgradeJob(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreEngineUpgradeJob_enabled_value(self):
        dot_string_dict = {
            "anchoreEngineUpgradeJob.enabled": True
        }
        expected_result = {}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEngineUpgradeJob_resources_value(self):
        dot_string_dict = {
            "anchoreEngineUpgradeJob.resources.limits.cpu": 1,
            "anchoreEngineUpgradeJob.resources.limits.memory": "4G",
            "anchoreEngineUpgradeJob.resources.requests.cpu": 1,
            "anchoreEngineUpgradeJob.resources.requests.memory": "1G"
        }
        expected_result = {}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEngineUpgradeJob_labels_value(self):
        dot_string_dict = {
            "anchoreEngineUpgradeJob.labels.myLabel": "myValue",
            "anchoreEngineUpgradeJob.labels.myOtherLabel": "myOtherValue",
            "anchoreEngineUpgradeJob.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = {}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEngineUpgradeJob_annotations_value(self):
        dot_string_dict = {
            "anchoreEngineUpgradeJob.annotations.foo": "bar",
            "anchoreEngineUpgradeJob.annotations.bar": "baz",
            "anchoreEngineUpgradeJob.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = {}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEngineUpgradeJob_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreEngineUpgradeJob.nodeSelector.name": "foo",
            "anchoreEngineUpgradeJob.nodeSelector.value": "bar",
            "anchoreEngineUpgradeJob.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = {}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEngineUpgradeJob_tolerations_value(self):
        dot_string_dict = {
            "anchoreEngineUpgradeJob.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = {}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEngineUpgradeJob_affinity_value(self):
        dot_string_dict = {
            "anchoreEngineUpgradeJob.affinity.name": "foo",
            "anchoreEngineUpgradeJob.affinity.value": "bar",
            "anchoreEngineUpgradeJob.affinity.anotherLabel.with.a.dot": "baz"
        }
        expected_result = {}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

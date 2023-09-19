import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsSimpleQueue(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreSimpleQueue_replicaCount_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.replicaCount": 2,
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreSimpleQueue_resources_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.resources.limits.cpu": 1,
            "anchoreSimpleQueue.resources.limits.memory": "4G",
            "anchoreSimpleQueue.resources.requests.cpu": 1,
            "anchoreSimpleQueue.resources.requests.memory": "1G"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
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


    def test_anchoreSimpleQueue_labels_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.labels.myLabel": "myValue",
            "anchoreSimpleQueue.labels.myOtherLabel": "myOtherValue",
            "anchoreSimpleQueue.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
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

    def test_anchoreSimpleQueue_annotations_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.annotations.foo": "bar",
            "anchoreSimpleQueue.annotations.bar": "baz",
            "anchoreSimpleQueue.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
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

    def test_anchoreSimpleQueue_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.deploymentAnnotations.foo": "bar",
            "anchoreSimpleQueue.deploymentAnnotations.bar": "baz",
            "anchoreSimpleQueue.deploymentAnnotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
                'deploymentAnnotations':
                    {
                        'foo': 'bar',
                        'bar': 'baz',
                        'anotherLabel.with.a.dot': 'qux'
                    }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreSimpleQueue_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.nodeSelector.name": "foo",
            "anchoreSimpleQueue.nodeSelector.value": "bar",
            "anchoreSimpleQueue.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
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

    def test_anchoreSimpleQueue_tolerations_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
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

    def test_anchoreSimpleQueue_affinity_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.affinity.name": "foo",
            "anchoreSimpleQueue.affinity.value": "bar",
            "anchoreSimpleQueue.affinity.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
                'affinity':{
                    'name': 'foo',
                    'value': 'bar',
                    'anotherLabel.with.a.dot': 'baz'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreSimpleQueue_extraEnv_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
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

    def test_anchoreSimpleQueue_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.serviceAccountName": "Null"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreSimpleQueue_service_value(self):
        dot_string_dict = {
            "anchoreSimpleQueue.service.name": "Null",
            "anchoreSimpleQueue.service.type": "ClusterIP",
            "anchoreSimpleQueue.service.port": 8082,
            "anchoreSimpleQueue.service.annotations.foo": "bar",
            "anchoreSimpleQueue.service.annotations.baz": "qux",
            "anchoreSimpleQueue.service.annotations.with.a.dot": "quux",
            "anchoreSimpleQueue.service.labels.foobar": "baz",
            "anchoreSimpleQueue.service.labels.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'simpleQueue': {
                'service': {
                    "name": "Null",
                    "type": "ClusterIP",
                    "port": 8082,
                    "annotations": {
                        "foo": "bar",
                        "baz": "qux",
                        "with.a.dot": "quux"
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

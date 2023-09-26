import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsEnterpriseNotifications(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreEnterpriseNotifications_enabled_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.enabled": True, # deprecated
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseNotifications_replicaCount_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.replicaCount": 2,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreEnterpriseNotifications_resources_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.resources.limits.cpu": 1,
            "anchoreEnterpriseNotifications.resources.limits.memory": "4G",
            "anchoreEnterpriseNotifications.resources.requests.cpu": 1,
            "anchoreEnterpriseNotifications.resources.requests.memory": "1G"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
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


    def test_anchoreEnterpriseNotifications_labels_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.labels.myLabel": "myValue",
            "anchoreEnterpriseNotifications.labels.myOtherLabel": "myOtherValue",
            "anchoreEnterpriseNotifications.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
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

    def test_anchoreEnterpriseNotifications_annotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.annotations.foo": "bar",
            "anchoreEnterpriseNotifications.annotations.bar": "baz",
            "anchoreEnterpriseNotifications.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
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

    def test_anchoreEnterpriseNotifications_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.deploymentAnnotations.foo": "bar",
            "anchoreEnterpriseNotifications.deploymentAnnotations.bar": "baz",
            "anchoreEnterpriseNotifications.deploymentAnnotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
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

    def test_anchoreEnterpriseNotifications_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.nodeSelector.name": "foo",
            "anchoreEnterpriseNotifications.nodeSelector.value": "bar",
            "anchoreEnterpriseNotifications.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
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

    def test_anchoreEnterpriseNotifications_tolerations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
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

    def test_anchoreEnterpriseNotifications_affinity_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.affinity.name": "foo",
            "anchoreEnterpriseNotifications.affinity.value": "bar",
            "anchoreEnterpriseNotifications.affinity.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
                'affinity':{
                    'name': 'foo',
                    'value': 'bar',
                    'anotherLabel.with.a.dot': 'baz'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseNotifications_extraEnv_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
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

    def test_anchoreEnterpriseNotifications_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.serviceAccountName": "Null"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreEnterpriseNotifications_service_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.service.name": "Null",
            "anchoreEnterpriseNotifications.service.type": "ClusterIP",
            "anchoreEnterpriseNotifications.service.port": 8668,
            "anchoreEnterpriseNotifications.service.annotations.foo": "bar",
            "anchoreEnterpriseNotifications.service.annotations.baz": "qux",
            "anchoreEnterpriseNotifications.service.annotations.with.a.dot": "quux",
            "anchoreEnterpriseNotifications.service.labels": {}
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'notifications': {
                'service': {
                    "name": "Null",
                    "type": "ClusterIP",
                    "port": 8668,
                    "annotations": {
                        "foo": "bar",
                        "baz": "qux",
                        "with.a.dot": "quux"
                    },
                    "labels": {}
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseNotifications_cycleTimers_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.cycleTimers.notifications": 30
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'notifications': {
                    'cycle_timers': {
                        "notifications": 30
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseNotifications_uiUrl_value(self):
        dot_string_dict = {
            "anchoreEnterpriseNotifications.uiUrl": "http://myurl.myurl"
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'notifications': {
                    'ui_url': "http://myurl.myurl"
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

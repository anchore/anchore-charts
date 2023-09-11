import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsCatalog(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreEnterpriseRbac_replicaCount_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.replicaCount": 2,
        }
        expected_result = {
            'rbacManager': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreEnterpriseRbac_resources_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.resources.limits.cpu": 1,
            "anchoreEnterpriseRbac.resources.limits.memory": "4G",
            "anchoreEnterpriseRbac.resources.requests.cpu": 1,
            "anchoreEnterpriseRbac.resources.requests.memory": "1G"
        }
        expected_result = {
            'rbacManager': {
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


    def test_anchoreEnterpriseRbac_labels_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.labels.myLabel": "myValue",
            "anchoreEnterpriseRbac.labels.myOtherLabel": "myOtherValue",
            "anchoreEnterpriseRbac.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = {
            'rbacManager': {
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

    def test_anchoreEnterpriseRbac_annotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.annotations.foo": "bar",
            "anchoreEnterpriseRbac.annotations.bar": "baz",
            "anchoreEnterpriseRbac.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = {
            'rbacManager': {
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

    def test_anchoreEnterpriseRbac_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.deploymentAnnotations.foo": "bar",
            "anchoreEnterpriseRbac.deploymentAnnotations.bar": "baz",
            "anchoreEnterpriseRbac.deploymentAnnotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = {
            'rbacManager': {
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

    def test_anchoreEnterpriseRbac_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.nodeSelector.name": "foo",
            "anchoreEnterpriseRbac.nodeSelector.value": "bar",
            "anchoreEnterpriseRbac.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = {
            'rbacManager': {
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

    def test_anchoreEnterpriseRbac_tolerations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = {
            'rbacManager': {
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

    def test_anchoreEnterpriseRbac_affinity_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.affinity.name": "foo",
            "anchoreEnterpriseRbac.affinity.value": "bar",
            "anchoreEnterpriseRbac.affinity.anotherLabel.with.a.dot": "baz"
        }
        expected_result = {
            'rbacManager': {
                'affinity':{
                    'name': 'foo',
                    'value': 'bar',
                    'anotherLabel.with.a.dot': 'baz'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseRbac_extraEnv_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = {
            'rbacManager': {
                'extraEnv': [
                    {
                        "name": "foo",
                        "value": "bar"
                    }
                ]
            },
            'rbacAuth': {
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

    def test_anchoreEnterpriseRbac_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.serviceAccountName": "Null"
        }
        expected_result = {
            'rbacManager': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreEnterpriseRbac_service_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.service.name": "Null",
            "anchoreEnterpriseRbac.service.type": "ClusterIP",
            "anchoreEnterpriseRbac.service.managerPort": 8082,
            "anchoreEnterpriseRbac.service.authPort": "8089",
            "anchoreEnterpriseRbac.service.annotations.foo": "bar",
            "anchoreEnterpriseRbac.service.annotations.bar": "baz",
            "anchoreEnterpriseRbac.service.annotations.anotherLabel.with.a.dot": "qux",
            "anchoreEnterpriseRbac.service.labels": {},
        }
        expected_result = {
            'rbacManager': {
                'service': {
                    'name': 'Null',
                    'type': 'ClusterIP',
                    'port': 8082,
                    # 'authPort': '8089', Deprecated
                    'annotations': {
                        'foo': 'bar',
                        'bar': 'baz',
                        'anotherLabel.with.a.dot': 'qux'
                    },
                    'labels': {}
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

#   enabled: true
    def test_anchoreEnterpriseRbac_enabled_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.enabled": True # deprecated
        }
        expected_result = {}

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseRbac_authResources_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.authResources.limits.cpu": 1,
            "anchoreEnterpriseRbac.authResources.limits.memory": "1G",
            "anchoreEnterpriseRbac.authResources.requests.cpu": "100m",
            "anchoreEnterpriseRbac.authResources.requests.memory": "256M"
        }
        expected_result = {
            'rbacAuth': {
                'resources': {
                    'limits': {
                        'cpu': 1,
                        'memory': '1G'
                    },
                    'requests': {
                        'cpu': '100m',
                        'memory': '256M'
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseRbac_managerResources_value(self):
        dot_string_dict = {
            "anchoreEnterpriseRbac.managerResources.limits.cpu": 1,
            "anchoreEnterpriseRbac.managerResources.limits.memory": "1G",
            "anchoreEnterpriseRbac.managerResources.requests.cpu": "100m",
            "anchoreEnterpriseRbac.managerResources.requests.memory": "256M"
        }
        expected_result = {
            'rbacManager': {
                'resources': {
                    'limits': {
                        'cpu': 1,
                        'memory': '1G'
                    },
                    'requests': {
                        'cpu': '100m',
                        'memory': '256M'
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
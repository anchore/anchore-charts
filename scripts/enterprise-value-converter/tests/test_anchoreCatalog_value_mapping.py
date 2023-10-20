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

    def test_anchoreCatalog_replicaCount_value(self):
        dot_string_dict = {
            "anchoreCatalog.replicaCount": 2,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_extraEnv_value(self):
        dot_string_dict = {
            "anchoreCatalog.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreCatalog.serviceAccountName": "Null"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_service_value(self):
        dot_string_dict = {
            "anchoreCatalog.service.name": "Null",
            "anchoreCatalog.service.type": "ClusterIP",
            "anchoreCatalog.service.port": 8082,
            "anchoreCatalog.service.annotations.foo": "bar",
            "anchoreCatalog.service.annotations.baz": "qux",
            "anchoreCatalog.service.annotations.with.a.dot": "quux",
            "anchoreCatalog.service.labels.foobar": "baz",
            "anchoreCatalog.service.labels.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_resources_value(self):
        dot_string_dict = {
            "anchoreCatalog.resources.limits.cpu": 1,
            "anchoreCatalog.resources.limits.memory": "4G",
            "anchoreCatalog.resources.requests.cpu": 1,
            "anchoreCatalog.resources.requests.memory": "1G"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_labels_value(self):
        dot_string_dict = {
            "anchoreCatalog.labels.myLabel": "myValue",
            "anchoreCatalog.labels.myOtherLabel": "myOtherValue",
            "anchoreCatalog.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_annotations_value(self):
        dot_string_dict = {
            "anchoreCatalog.annotations.foo": "bar",
            "anchoreCatalog.annotations.bar": "baz",
            "anchoreCatalog.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreCatalog.deploymentAnnotations.foo": "bar",
            "anchoreCatalog.deploymentAnnotations.bar": "baz",
            "anchoreCatalog.deploymentAnnotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreCatalog.nodeSelector.name": "foo",
            "anchoreCatalog.nodeSelector.value": "bar",
            "anchoreCatalog.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_tolerations_value(self):
        dot_string_dict = {
            "anchoreCatalog.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
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

    def test_anchoreCatalog_affinity_value(self):
        dot_string_dict = {
            "anchoreCatalog.affinity.name": "foo",
            "anchoreCatalog.affinity.value": "bar"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'catalog': {
                'affinity':{
                    'name': 'foo',
                    'value': 'bar'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_cycleTimers_value(self):
        dot_string_dict = {
            "anchoreCatalog.cycleTimers.image_watcher": 3600,
            "anchoreCatalog.cycleTimers.policy_eval": 3600,
            "anchoreCatalog.cycleTimers.vulnerability_scan": 14400,
            "anchoreCatalog.cycleTimers.analyzer_queue": 1,
            "anchoreCatalog.cycleTimers.archive_tasks": 43200,
            "anchoreCatalog.cycleTimers.notifications": 30,
            "anchoreCatalog.cycleTimers.service_watcher": 15,
            "anchoreCatalog.cycleTimers.repo_watcher": 60,
            "anchoreCatalog.cycleTimers.image_gc": 60,
            "anchoreCatalog.cycleTimers.k8s_image_watcher": 150,
            "anchoreCatalog.cycleTimers.resource_metrics": 60,
            "anchoreCatalog.cycleTimers.events_gc": 43200
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'catalog': {
                    'cycle_timers': {
                        'analyzer_queue': 1,
                        'archive_tasks': 43200,
                        'events_gc': 43200,
                        'image_gc': 60,
                        'image_watcher': 3600,
                        'k8s_image_watcher': 150,
                        'notifications': 30,
                        'policy_eval': 3600,
                        'repo_watcher': 60,
                        'resource_metrics': 60,
                        'service_watcher': 15,
                        'vulnerability_scan': 14400
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_events_value(self):
        dot_string_dict = {
            "anchoreCatalog.events.max_retention_age_days": 0,
            "anchoreCatalog.events.notification.enabled": False,
            "anchoreCatalog.events.notification.level": [
                "error"
            ]
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'catalog': {
                    'event_log': {
                        'max_retention_age_days': 0,
                        'notification': {
                            'enabled': False,
                            'level': [
                                'error'
                            ]
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_analysis_archive_value(self):
        dot_string_dict = {
            "anchoreCatalog.analysis_archive.compression.enabled": True,
            "anchoreCatalog.analysis_archive.compression.min_size_kbytes": 100,
            "anchoreCatalog.analysis_archive.storage_driver.name": "s3",
            "anchoreCatalog.analysis_archive.storage_driver.config.bucket": "anchore-engine-testing",
            "anchoreCatalog.analysis_archive.storage_driver.config.prefix": "internaltest",
            "anchoreCatalog.analysis_archive.storage_driver.config.create_bucket": False,
            "anchoreCatalog.analysis_archive.storage_driver.config.url": "https://s3.amazonaws.com",
            "anchoreCatalog.analysis_archive.storage_driver.config.region": "us-west-2",
            "anchoreCatalog.analysis_archive.storage_driver.config.access_key": "XXXX",
            "anchoreCatalog.analysis_archive.storage_driver.config.secret_key": "YYYY",
            "anchoreCatalog.analysis_archive.storage_driver.config.iamauto": True
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'catalog': {
                    'analysis_archive': {
                        'compression': {
                            'enabled': True,
                            'min_size_kbytes': 100
                        },
                        'storage_driver': {
                            'config': {
                                'access_key': 'XXXX',
                                'bucket': 'anchore-engine-testing',
                                'create_bucket': False,
                                'iamauto': True,
                                'prefix': 'internaltest',
                                'region': 'us-west-2',
                                'secret_key': 'YYYY',
                                'url': 'https://s3.amazonaws.com'
                            },
                            'name': 's3'
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_object_store_value(self):
        dot_string_dict = {
            "anchoreCatalog.object_store.compression.enabled": True,
            "anchoreCatalog.object_store.compression.min_size_kbytes": 100,
            "anchoreCatalog.object_store.storage_driver.name": "db",
            "anchoreCatalog.object_store.storage_driver.config": {}
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'catalog': {
                    'object_store': {
                        'compression': {
                            'enabled': True,
                            'min_size_kbytes': 100
                        },
                        'storage_driver': {
                            'config': {},
                            'name': 'db'
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_runtimeInventory_value(self):
        dot_string_dict = {
            "anchoreCatalog.runtimeInventory.imageTTLDays": 1
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'catalog': {
                    'runtime_inventory': {
                        'image_ttl_days': 1
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreCatalog_downAnalyzerTaskRequeue_value(self):
        dot_string_dict = {
            "anchoreCatalog.downAnalyzerTaskRequeue": True
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'catalog': {
                    'down_analyzer_task_requeue': True
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

class TestReplaceKeysWithMappingsFeeds(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_anchoreEnterpriseFeeds_enabled_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.enabled": True,
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'chartEnabled': True
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_replicaCount_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.replicaCount": 2,
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'replicaCount': 2
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreEnterpriseFeeds_resources_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.resources.limits.cpu": 1,
            "anchoreEnterpriseFeeds.resources.limits.memory": "4G",
            "anchoreEnterpriseFeeds.resources.requests.cpu": 1,
            "anchoreEnterpriseFeeds.resources.requests.memory": "1G"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
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


    def test_anchoreEnterpriseFeeds_labels_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.labels.myLabel": "myValue",
            "anchoreEnterpriseFeeds.labels.myOtherLabel": "myOtherValue",
            "anchoreEnterpriseFeeds.labels.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
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

    def test_anchoreEnterpriseFeeds_annotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.annotations.foo": "bar",
            "anchoreEnterpriseFeeds.annotations.bar": "baz",
            "anchoreEnterpriseFeeds.annotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
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

    def test_anchoreEnterpriseFeeds_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.deploymentAnnotations.foo": "bar",
            "anchoreEnterpriseFeeds.deploymentAnnotations.bar": "baz",
            "anchoreEnterpriseFeeds.deploymentAnnotations.anotherLabel.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
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

    def test_anchoreEnterpriseFeeds_nodeSelector_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.nodeSelector.name": "foo",
            "anchoreEnterpriseFeeds.nodeSelector.value": "bar",
            "anchoreEnterpriseFeeds.nodeSelector.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
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

    def test_anchoreEnterpriseFeeds_tolerations_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.tolerations": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
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

    def test_anchoreEnterpriseFeeds_affinity_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.affinity.name": "foo",
            "anchoreEnterpriseFeeds.affinity.value": "bar",
            "anchoreEnterpriseFeeds.affinity.anotherLabel.with.a.dot": "baz"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'affinity':{
                    'name': 'foo',
                    'value': 'bar',
                    'anotherLabel.with.a.dot': 'baz'
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_extraEnv_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.extraEnv": [
                {
                    "name": "foo",
                    "value": "bar"
                }
            ]
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
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

    def test_anchoreEnterpriseFeeds_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.serviceAccountName": "Null"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'serviceAccountName': "Null"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)


    def test_anchoreEnterpriseFeeds_service_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.service.name": "Null",
            "anchoreEnterpriseFeeds.service.type": "ClusterIP",
            "anchoreEnterpriseFeeds.service.port": 8448,
            "anchoreEnterpriseFeeds.service.annotations.foo": "bar",
            "anchoreEnterpriseFeeds.service.annotations.baz": "qux",
            "anchoreEnterpriseFeeds.service.annotations.with.a.dot": "quux",
            "anchoreEnterpriseFeeds.service.labels.foobar": "baz",
            "anchoreEnterpriseFeeds.service.labels.with.a.dot": "qux"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'service': {
                    "name": "Null",
                    "type": "ClusterIP",
                    "port": 8448,
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

    def test_anchoreEnterpriseFeeds_url_value(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.url": "https://myhostname:9999"
        }
        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'url': "https://myhostname:9999"
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_driver_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.npmDriverEnabled": False,
            "anchoreEnterpriseFeeds.gemDriverEnabled": False,
            "anchoreEnterpriseFeeds.githubDriverEnabled": False,
            "anchoreEnterpriseFeeds.githubDriverToken": "Null",
            "anchoreEnterpriseFeeds.useNvdDriverApiKey": False,
            "anchoreEnterpriseFeeds.nvdDriverApiKey": "Null",
            "anchoreEnterpriseFeeds.msrcDriverEnabled": False,
            "anchoreEnterpriseFeeds.msrcWhitelist": [
                12345
            ]
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'feeds': {
                        'drivers': {
                            'npm': {'enabled': False},
                            'gem': {'enabled': False},
                            'github': {'enabled': False, 'token': 'Null'},
                            'nvdv2': {'api_key': 'Null'},
                            'msrc': {'enabled': False, 'whitelist': [12345]}
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_ubuntuExtraReleases_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.ubuntuExtraReleases.kinetic": "22.10"
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'feeds': {
                        'drivers': {
                            'ubuntu': {
                                'releases': {
                                    'kinetic': '22.10'
                                }
                            }
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_ubuntuExtraReleases_empty_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.ubuntuExtraReleases": {}
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'feeds': {
                        'drivers': {
                            'ubuntu': {
                                'releases': {}
                            }
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_debianExtraReleases_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.debianExtraReleases.trixie": "13"
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'feeds': {
                        'drivers': {
                            'debian': {
                                'releases': {
                                    'trixie': '13'
                                }
                            }
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_debianExtraReleases_empty_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.debianExtraReleases": {}
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'feeds': {
                        'drivers': {
                            'debian': {
                                'releases': {}
                            }
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreEnterpriseFeeds_cycleTimers_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.cycleTimers.driver_sync": 7200
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'feeds': {
                        'cycle_timers': {
                            'driver_sync': 7200
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreEnterpriseFeeds_dbConfig_with_engineArgs_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.dbConfig.timeout": 120,
            "anchoreEnterpriseFeeds.dbConfig.ssl": False,
            "anchoreEnterpriseFeeds.dbConfig.sslMode": "verify-full",
            "anchoreEnterpriseFeeds.dbConfig.sslRootCertName": "my-mount/path/certname",
            "anchoreEnterpriseFeeds.dbConfig.connectionPoolSize": 30,
            "anchoreEnterpriseFeeds.dbConfig.connectionPoolMaxOverflow": 100,
            "anchoreEnterpriseFeeds.dbConfig.engineArgs.pool_recycle": 600
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'dbConfig': {
                        'timeout': 120,
                        'ssl': False,
                        'sslMode': 'verify-full',
                        'sslRootCertName': 'my-mount/path/certname',
                        'connectionPoolSize': 30,
                        'connectionPoolMaxOverflow': 100,
                        'engineArgs': {
                            'pool_recycle': 600
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreEnterpriseFeeds_dbConfig_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.dbConfig.timeout": 120,
            "anchoreEnterpriseFeeds.dbConfig.ssl": False,
            "anchoreEnterpriseFeeds.dbConfig.sslMode": "verify-full",
            "anchoreEnterpriseFeeds.dbConfig.sslRootCertName": "my-mount/path/certname",
            "anchoreEnterpriseFeeds.dbConfig.connectionPoolSize": 30,
            "anchoreEnterpriseFeeds.dbConfig.connectionPoolMaxOverflow": 100,
            "anchoreEnterpriseFeeds.dbConfig.engineArgs": {}
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'anchoreConfig': {
                    'dbConfig': {
                        'timeout': 120,
                        'ssl': False,
                        'sslMode': 'verify-full',
                        'sslRootCertName': 'my-mount/path/certname',
                        'connectionPoolSize': 30,
                        'connectionPoolMaxOverflow': 100,
                        'engineArgs': {}
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreEnterpriseFeeds_persistence_false_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.persistence.enabled": False,
            "anchoreEnterpriseFeeds.persistence.resourcePolicy": None
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'persistence': {
                    'enabled': False,
                    'resourcePolicy': None
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreEnterpriseFeeds_persistence_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.persistence.enabled": True,
            "anchoreEnterpriseFeeds.persistence.resourcePolicy": "keep",
            "anchoreEnterpriseFeeds.persistence.existingClaim": "my-claim",
            "anchoreEnterpriseFeeds.persistence.storageClass": "-",
            "anchoreEnterpriseFeeds.persistence.accessMode": "ReadWriteOnce",
            "anchoreEnterpriseFeeds.persistence.size": "40Gi",
            "anchoreEnterpriseFeeds.persistence.subPath": "postgresql-db",
            "anchoreEnterpriseFeeds.persistence.mountPath": "/workspace"
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'persistence': {
                    'enabled': True,
                    'resourcePolicy': 'keep',
                    'existingClaim': 'my-claim',
                    'storageClass': '-',
                    'accessMode': 'ReadWriteOnce',
                    'size': '40Gi',
                    'subPath': 'postgresql-db',
                    'mountPath': '/workspace'
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    # Values that become environment variables for Anchore Feeds
    def test_anchoreEnterpriseFeeds_rhelDriverConcurrency_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.rhelDriverConcurrency": 5
        }

        expected_result = {
            'feeds': {
                'extraEnv': [
                    {
                        'name': 'ANCHORE_FEEDS_DRIVER_RHEL_CONCURRENCY',
                        'value': 5
                    }
                ]
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], {
            'anchoreConfig': {'user_authentication': {'hashed_passwords': False}}
        })
        self.assertEqual(result[1], expected_result)

    def test_anchoreEnterpriseFeeds_ubuntuDriverGit_values(self):
        dot_string_dict = {
            "anchoreEnterpriseFeeds.ubuntuDriverGitUrl": "https://git.launchpad.net/ubuntu-cve-tracker",
            "anchoreEnterpriseFeeds.ubuntuDriverGitBranch": "master"
        }

        expected_result = {
            'feeds': {
                'extraEnv': [
                    { 'name': 'ANCHORE_FEEDS_DRIVER_UBUNTU_URL', 'value': 'https://git.launchpad.net/ubuntu-cve-tracker' },
                    { 'name': 'ANCHORE_FEEDS_DRIVER_UBUNTU_BRANCH', 'value': 'master' }
                ]
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], {
            'anchoreConfig': {'user_authentication': {'hashed_passwords': False}}
        })
        self.assertEqual(result[1], expected_result)

    # Anchore Feeds DB values
    def test_anchoreFeedsDB_values(self):
        dot_string_dict = {
            "anchore-feeds-db.enabled": True,
            "anchore-feeds-db.externalEndpoint": "Null",
            "anchore-feeds-db.postgresUser": "anchoreengine",
            "anchore-feeds-db.postgresPassword": "anchore-postgres,123",
            "anchore-feeds-db.postgresDatabase": "anchore-feeds",
            "anchore-feeds-db.postgresPort": 5432
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            "feeds": {
                "feeds-db": {
                    "chartEnabled": True,
                    "externalEndpoint": "Null",
                    'auth': {
                        'username': 'anchoreengine',
                        'password': 'anchore-postgres,123',
                        'database': 'anchore-feeds'
                    },
                    'primary': {
                        'service': {
                            'ports': {
                                'postgresql': 5432
                            }
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreFeedsDB_persistence_values(self):
        dot_string_dict = {
            "anchore-feeds-db.persistence.enabled": True,
            "anchore-feeds-db.persistence.resourcePolicy": "keep",
            "anchore-feeds-db.persistence.size": "20Gi"
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feeds-db': {
                    'primary': {
                        'persistence': {
                            'enabled': True,
                            'resourcePolicy': 'keep',
                            'size': '20Gi'
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreFeedsDB_image_values(self):
        dot_string_dict = {
            "anchore-feeds-db.image": "registry.access.redhat.com/rhscl/postgresql-96-rhel7",
            "anchore-feeds-db.imageTag": "latest"
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feeds-db': {
                    'image': {
                        'repository': 'registry.access.redhat.com/rhscl/postgresql-96-rhel7',
                        'tag': 'latest'
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreFeedsDB_extraEnv_values(self):
        dot_string_dict = {
            "anchore-feeds-db.extraEnv": [
                {
                    "name": "POSTGRESQL_USER",
                    "value": "anchoreengine"
                },
                {
                    "name": "POSTGRESQL_PASSWORD",
                    "value": "anchore-postgres,123"
                }
            ]
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'feeds-db':{
                    'primary': {
                        'extraEnvVars': [
                            {'name': 'POSTGRESQL_USER', 'value': 'anchoreengine'},
                            {'name': 'POSTGRESQL_PASSWORD', 'value': 'anchore-postgres,123'}
                        ]
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    # Anchore Feeds Gem DB values
    def test_anchoreFeedsGemDB_values(self):
        dot_string_dict = {
            "anchore-feeds-gem-db.enabled": True,
            "anchore-feeds-gem-db.externalEndpoint": "Null",
            "anchore-feeds-gem-db.postgresUser": "anchoreengine",
            "anchore-feeds-gem-db.postgresPassword": "anchore-postgres,123",
            "anchore-feeds-gem-db.postgresDatabase": "gems",
            "anchore-feeds-gem-db.postgresPort": 5432
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            "feeds": {
                "gem-db": {
                    "chartEnabled": True,
                    "externalEndpoint": "Null",
                    'auth': {
                        'username': 'anchoreengine',
                        'password': 'anchore-postgres,123',
                        'database': 'gems'
                    },
                    'primary': {
                        'service': {
                            'ports': {
                                'postgresql': 5432
                            }
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreFeedsGemDB_persistence_values(self):
        dot_string_dict = {
            "anchore-feeds-gem-db.persistence.enabled": True,
            "anchore-feeds-gem-db.persistence.resourcePolicy": "keep",
            "anchore-feeds-gem-db.persistence.size": "20Gi"
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'gem-db': {
                    'primary': {
                        'persistence': {
                            'enabled': True,
                            'resourcePolicy': 'keep',
                            'size': '20Gi'
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreFeedsGemDB_image_values(self):
        dot_string_dict = {
            "anchore-feeds-gem-db.image": "registry.access.redhat.com/rhscl/postgresql-96-rhel7",
            "anchore-feeds-gem-db.imageTag": "latest"
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'gem-db': {
                    'image': {
                        'repository': 'registry.access.redhat.com/rhscl/postgresql-96-rhel7',
                        'tag': 'latest'
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreFeedsGemDB_extraEnv_values(self):
        dot_string_dict = {
            "anchore-feeds-gem-db.extraEnv": [
                {
                    "name": "POSTGRESQL_USER",
                    "value": "anchoreengine"
                },
                {
                    "name": "POSTGRESQL_PASSWORD",
                    "value": "anchore-postgres,123"
                }
            ]
        }

        expected_result = { 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'feeds': {
                'gem-db':{
                    'primary': {
                        'extraEnvVars': [
                            {'name': 'POSTGRESQL_USER', 'value': 'anchoreengine'},
                            {'name': 'POSTGRESQL_PASSWORD', 'value': 'anchore-postgres,123'}
                        ]
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
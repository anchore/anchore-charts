import os
import shutil
import unittest
from helpers import (
    replace_keys_with_mappings,
)

# replace_keys_with_mappings(dot_string_dict, results_dir):
# returns a dictionary where the keys are created from the dot string representation
class TestReplaceKeysWithMappings(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_fullnameOverride(self):
        dot_string_dict = {"fullnameOverride": "overridden"}
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'global': {'fullnameOverride': 'overridden'}
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_nameOverride(self):
        dot_string_dict = {"nameOverride": "overridden"}
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'global': {'nameOverride': 'overridden'}
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_postgresql_values(self):
        dot_string_dict = {
            "postgresql.enabled": True,
            "postgresql.externalEndpoint": "notnull",
            "postgresql.postgresUser": "myuser",
            "postgresql.postgresPassword": "mypass",
            "postgresql.postgresDatabase": "mydb",
            "postgresql.postgresPort": 5555,
            "postgresql.persistence.size": "100Gi",
            "postgresql.persistence.resourcePolicy": "",
            "postgresql.extraEnv": [{'name': 'POSTGRES_USER', 'value': 'myuser'}, {'name': 'POSTGRES_PASSWORD', 'value': 'mypass'}],
        }

        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'postgresql':{
                'chartEnabled': True,
                'auth':{
                    'database': 'mydb',
                    'password': 'mypass',
                    'username': 'myuser'
                 },
                'externalEndpoint': 'notnull',
                'primary': {
                    'extraEnvVars': [
                        {'name': 'POSTGRES_USER', 'value': 'myuser'},
                        {'name': 'POSTGRES_PASSWORD', 'value': 'mypass'}
                    ],
                    'persistence': {
                        # 'resourcePolicy': '', Deprecated
                        'size': '100Gi'
                    },
                    'service': {
                        'ports': {
                            'postgresql': 5555
                        }
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_cloudsql_values(self):
        dot_string_dict = {
            "cloudsql.enabled": True,
            "cloudsql.extraArgs": ["--max_connections=1000"],
            "cloudsql.instance": "project:zone:instancename",
            "cloudsql.useExistingServiceAcc": True,
            "cloudsql.serviceAccSecretName": "service_acc",
            "cloudsql.serviceAccJsonName": "for_cloudsql.json",
            "cloudsql.image.repository": "my.repo/cloudsql-docker/gce-proxy",
            "cloudsql.image.tag": "1.11",
            "cloudsql.image.pullPolicy": "Always",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'cloudsql': {
                'enabled': True,
                'extraArgs': ['--max_connections=1000'],
                'instance': 'project:zone:instancename',
                'useExistingServiceAcc': True,
                'serviceAccSecretName': 'service_acc',
                'serviceAccJsonName': 'for_cloudsql.json',
                'image': 'my.repo/cloudsql-docker/gce-proxy:1.11',
                'imagePullPolicy': 'Always'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)

        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_ingress_values(self):
        dot_string_dict = {
            "ingress.enabled": False,
            "ingress.apiPath": "/v1/",
            "ingress.uiPath": "/",
            "ingress.ingressClassName": "nginx",
            "ingress.apiHosts": ["anchore-api.example.com"],
            "ingress.uiHosts": ["anchore-ui.example.com"],
            "ingress.feedsHosts": ["anchore-feeds.example.com"],
            "ingress.reportsHosts": ["anchore-api.example.com"],
            "ingress.annotations.kubernetes.io/ingress.class": "nginx",
            "ingress.annotations.nginx.ingress.kubernetes.io/ssl-redirect": "false",
            "ingress.annotations.kubernetes.io/ingress.allow-http": False,
            "ingress.annotations.kubernetes.io/tls-acme": True,
            "ingress.tls": [
                {
                    "secretName": "chart-example-tls",
                    "hosts": ["chart-example.local"]
                }
            ]
        }

        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'ingress': {
                'enabled': False,
                'apiPath': '/v1/',
                'uiPath': '/',
                'ingressClassName': 'nginx',
                'apiHosts': ['anchore-api.example.com'],
                'uiHosts': ['anchore-ui.example.com'],
                'feedsHosts': ['anchore-feeds.example.com'],
                'reportsHosts': ['anchore-api.example.com'],
                'annotations': {
                    'kubernetes.io/ingress.class': 'nginx',
                    'nginx.ingress.kubernetes.io/ssl-redirect': 'false',
                    'kubernetes.io/ingress.allow-http': False,
                    'kubernetes.io/tls-acme': True
                },
                'tls': [
                    {
                        'secretName': 'chart-example-tls',
                        'hosts': ['chart-example.local']
                    }
                ]
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})


    def test_anchoreGlobal_image_values(self):
        dot_string_dict = {
            "anchoreGlobal.image": "my.repo/anchore-engine:v1.0.0",
            "anchoreGlobal.imagePullPolicy": "Always",
            "anchoreGlobal.imagePullSecretName": "mysecret",
            "anchoreEnterpriseGlobal.image": "my.repo/anchore-enterprise:v4.9.0",
            "anchoreEnterpriseGlobal.imagePullPolicy": "ifNotPresent",
            "anchoreEnterpriseGlobal.imagePullSecretName": "enterprise-pull-secret",
            "anchoreEnterpriseGlobal.enabled": True,
            "anchoreEnterpriseGlobal.licenseSecretName": "my-anchore-enterprise-license"
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'image': 'my.repo/anchore-enterprise:v4.9.0',
            'imagePullPolicy': 'ifNotPresent',
            'imagePullSecretName': 'enterprise-pull-secret',
            'licenseSecretName': 'my-anchore-enterprise-license',
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_openShiftDeployment_value(self):
        # this value is no longer required in the enterprise chart
        dot_string_dict = {
            "openShiftDeployment": True,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_serviceAccountName_value(self):
        dot_string_dict = {
            "anchoreGlobal.serviceAccountName": "my-sa-anchore-engine",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'serviceAccountName': 'my-sa-anchore-engine'
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_labels_value(self):
        dot_string_dict = {
            "anchoreGlobal.labels.mylabel": "myvalue",
            "anchoreGlobal.labels.myotherlabel": "myothervalue",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'labels': {
                'mylabel': 'myvalue',
                'myotherlabel': 'myothervalue'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_annotations_value(self):
        dot_string_dict = {
            "anchoreGlobal.annotations.myannotation": "myvalue",
            "anchoreGlobal.annotations.myotherannotation": "myothervalue",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'annotations': {
                'myannotation': 'myvalue',
                'myotherannotation': 'myothervalue'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_extraEnv_value(self):
        dot_string_dict = {
            "anchoreGlobal.extraEnv": [
                {"name": "MY_ENV_VAR", "value": "myvalue"},
                {"name": "MY_OTHER_ENV_VAR", "value": "myothervalue"}
            ],
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'extraEnv': [
                {'name': 'MY_ENV_VAR', 'value': 'myvalue'},
                {'name': 'MY_OTHER_ENV_VAR', 'value': 'myothervalue'}
            ]
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    # TODO check if this is not in the enterprise chart for a reason
    def test_anchoreGlobal_deploymentAnnotations_value(self):
        dot_string_dict = {
            "anchoreGlobal.deploymentAnnotations.myannotation": "myvalue",
            "anchoreGlobal.deploymentAnnotations.myotherannotation": "myothervalue",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'deploymentAnnotations': {
                'myannotation': 'myvalue',
                'myotherannotation': 'myothervalue'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_useExistingSecret_value(self):
        dot_string_dict = {
            "anchoreGlobal.useExistingSecret": True,
            "anchoreGlobal.existingSecretName": "my-existing-secret",
            "anchoreEnterpriseUi.existingSecretName": "my-existing-secret-ui",
            "anchoreEnterpriseFeeds.existingSecretName": "my-existing-secret-feeds",
        }

        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'useExistingSecret': True,
            'existingSecretName': 'my-existing-secret',
            'ui': {
                'existingSecretName': 'my-existing-secret-ui'
            },
            'feeds':{
                'existingSecretName': 'my-existing-secret-feeds',
                'useExistingSecrets': True
            }
        }


        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_doSourceAtEntry_value(self):
        dot_string_dict = {
            "anchoreGlobal.doSourceAtEntry.enabled": True,
            "anchoreGlobal.doSourceAtEntry.filePaths": ["/vault/secrets/config"],
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'doSourceAtEntry': {
                'enabled': True,
                'filePaths': ['/vault/secrets/config']
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_extraVolumes_value(self):
        dot_string_dict = {
            "anchoreGlobal.extraVolumes": [
                {
                    "name": "config",
                    "secret": {
                        "secretName": "config"
                    }
                }
            ],
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'extraVolumes': [
                {
                    'name': 'config',
                    'secret': {
                        'secretName': 'config'
                    }
                }
            ]
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_extraVolumeMounts_value(self):
        dot_string_dict = {
            "anchoreGlobal.extraVolumeMounts": [
                {
                    "name": "config",
                    "mountPath": "/vault/secrets/config",
                    "subPath": "config",
                    "readOnly": True
                }
            ],
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'extraVolumeMounts': [
                {
                    'name': 'config',
                    'mountPath': '/vault/secrets/config',
                    'subPath': 'config',
                    'readOnly': True
                }
            ]
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_scratchVolume_value(self):
        dot_string_dict = {
            "anchoreGlobal.scratchVolume.fixGroupPermissions": False,
            "anchoreGlobal.scratchVolume.mountPath": "/analysis_scratch",
            "anchoreGlobal.scratchVolume.details": {},
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'scratchVolume': {
                'fixGroupPermissions': False,
                'mountPath': '/analysis_scratch',
                'details': {}
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_certStoreSecretName_value(self):
        dot_string_dict = {
            "anchoreGlobal.certStoreSecretName": "my-cert-store-secret",
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'certStoreSecretName': 'my-cert-store-secret'
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)
        self.assertEqual(result[1], {})

    def test_anchoreGlobal_securityContext_value(self):
        dot_string_dict = {
            "anchoreGlobal.securityContext.runAsUser": 1000,
            "anchoreGlobal.securityContext.runAsGroup": 1000,
            "anchoreGlobal.securityContext.fsGroup": 1000,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'securityContext': {
                'runAsUser': 1000,
                'runAsGroup': 1000,
                'fsGroup': 1000
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_containerSecurityContext_value(self):
        dot_string_dict = {
            "anchoreGlobal.containerSecurityContext.securityContext.runAsUser": 1000,
            "anchoreGlobal.containerSecurityContext.securityContext.runAsGroup": 1000,
            "anchoreGlobal.containerSecurityContext.securityContext.fsGroup": 1000,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'containerSecurityContext': {
                'securityContext': {
                    'runAsUser': 1000,
                    'runAsGroup': 1000,
                    'fsGroup': 1000
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_serviceDir_value(self):
        dot_string_dict = {
            "anchoreGlobal.serviceDir": "/anchore_service",
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'service_dir': '/anchore_service'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_logLevel_value(self):
        dot_string_dict = {
            "anchoreGlobal.logLevel": "INFO",
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'log_level': 'INFO'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    # deprecated value, should be empty
    def test_anchoreGlobal_imageAnalyzeTimeoutSeconds_value(self):
        dot_string_dict = {
            "anchoreGlobal.imageAnalyzeTimeoutSeconds": 100,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_allowECRUseIAMRole_value(self):
        dot_string_dict = {
            "anchoreGlobal.allowECRUseIAMRole": True,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'allow_awsecr_iam_auto': True
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_enableMetrics_value(self):
        dot_string_dict = {
            "anchoreGlobal.enableMetrics": False,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'metrics': {
                    'enabled': False
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_metricsAuthDisabled_value(self):
        dot_string_dict = {
            "anchoreGlobal.metricsAuthDisabled": True,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'metrics': {
                    'auth_disabled': True
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_defaultAdmin_value(self):
        dot_string_dict = {
            "anchoreGlobal.defaultAdminPassword": "myadminpassword",
            "anchoreGlobal.defaultAdminEmail": "myadminemail@email.com",
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'default_admin_password': 'myadminpassword',
                'default_admin_email': 'myadminemail@email.com'
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    #   saml:
    #     secret: Null
    #     useExistingSecret: false
    #     privateKeyName: Null
    #     publicKeyName: Null
    def test_anchoreGlobal_saml_values(self):
        dot_string_dict = {
            "anchoreGlobal.saml.secret": "my-saml-secret",
            "anchoreGlobal.saml.useExistingSecret": True,
            "anchoreGlobal.saml.privateKeyName": "my-private-key-name",
            "anchoreGlobal.saml.publicKeyName": "my-public-key-name",
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'keys': {
                    'secret': 'my-saml-secret',
                    'privateKeyFileName': 'my-private-key-name',
                    'publicKeyFileName': 'my-public-key-name'
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_oauth_values(self):
        dot_string_dict = {
            "anchoreGlobal.oauthEnabled": True,
            "anchoreGlobal.oauthTokenExpirationSeconds": 100,
            "anchoreGlobal.oauthRefreshTokenExpirationSeconds": 200,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {
                    'hashed_passwords': False,
                    'oauth': {
                        'enabled': True,
                        'default_token_expiration_seconds': 100,
                        'refresh_token_expiration_seconds': 200
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_ssoRequireExistingUsers_value(self):
        dot_string_dict = {
            "anchoreGlobal.ssoRequireExistingUsers": True,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {
                    'hashed_passwords': False,
                    'sso_require_existing_users': True
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_hashedPasswords_value(self):
        dot_string_dict = {
            "anchoreGlobal.hashedPasswords": True,
        }
        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {
                    'hashed_passwords': True
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_dbConfig_values(self):
        dot_string_dict = {
            "anchoreGlobal.dbConfig.timeout": 100,
            "anchoreGlobal.dbConfig.ssl": True,
            "anchoreGlobal.dbConfig.sslMode": "verify-full",
            "anchoreGlobal.dbConfig.sslRootCertName": "my-ssl-root-cert-name",
            "anchoreGlobal.dbConfig.connectionPoolSize": 50,
            "anchoreGlobal.dbConfig.connectionPoolMaxOverflow": 200,
            "anchoreGlobal.dbConfig.engineArgs.pool_recycle": 1000,
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'database': {
                    'timeout': 100,
                    'ssl': True,
                    'sslMode': 'verify-full',
                    'sslRootCertFileName': 'my-ssl-root-cert-name',
                    'db_pool_size': 50,
                    'db_pool_max_overflow': 200,
                    'engineArgs': {
                        'pool_recycle': 1000
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_internalServicesSsl_values(self):
        dot_string_dict = {
            "anchoreGlobal.internalServicesSsl.enabled": True,
            "anchoreGlobal.internalServicesSsl.verifyCerts": True,
            "anchoreGlobal.internalServicesSsl.certSecretKeyName": "my-cert-secret-key-name",
            "anchoreGlobal.internalServicesSsl.certSecretCertName": "my-cert-secret-cert-name",
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'internalServicesSSL': {
                    'certSecretCertFileName': 'my-cert-secret-cert-name',
                    'certSecretKeyFileName': 'my-cert-secret-key-name',
                    'enabled': True,
                    'verifyCerts': True
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_webhooks_values(self):
        dot_string_dict = {
            "anchoreGlobal.webhooksEnabled": True, # this no longer used
            "anchoreGlobal.webhooks.webhook_user": "my-webhook-user",
            "anchoreGlobal.webhooks.webhook_pass": "my-webhook-pass",
            "anchoreGlobal.webhooks.ssl_verify": False,
            "anchoreGlobal.webhooks.url": "http://somehost:9090/<notification_type>/<userId>",
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'webhooks': {
                    'ssl_verify': False,
                    'url': 'http://somehost:9090/<notification_type>/<userId>',
                    'webhook_pass': 'my-webhook-pass',
                    'webhook_user': 'my-webhook-user'
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_policyBundles_values(self):
        dot_string_dict = {
            'anchoreGlobal.policyBundles.custom_policy_bundle1.json': '{\n  "id": "custom1",\n  "version": "1_0",\n  "name": "My custom bundle",\n  "comment": "My system\'s custom bundle",\n  "whitelisted_images": [],\n  "blacklisted_images": [],\n  "mappings": [],\n  "whitelists": [],\n  "policies": []\n}\n'
        }

        expected_result = {
            'postgresql': {'auth': {'username': 'anchoreengine'}},
            'anchoreConfig': {
                'user_authentication': {'hashed_passwords': False},
                'policyBundles': {
                    'custom_policy_bundle1': {
                        'json': '{\n  "id": "custom1",\n  "version": "1_0",\n  "name": "My custom bundle",\n  "comment": "My system\'s custom bundle",\n  "whitelisted_images": [],\n  "blacklisted_images": [],\n  "mappings": [],\n  "whitelists": [],\n  "policies": []\n}\n'
                    }
                }
            }
        }

        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_anchoreGlobal_probes_values(self):
        dot_string_dict = {
            "anchoreGlobal.probes.liveness.initialDelaySeconds": 120,
            "anchoreGlobal.probes.liveness.timeoutSeconds": 10,
            "anchoreGlobal.probes.liveness.periodSeconds": 10,
            "anchoreGlobal.probes.liveness.failureThreshold": 6,
            "anchoreGlobal.probes.liveness.successThreshold": 1,
            "anchoreGlobal.probes.readiness.timeoutSeconds": 10,
            "anchoreGlobal.probes.readiness.periodSeconds": 10,
            "anchoreGlobal.probes.readiness.failureThreshold": 3,
            "anchoreGlobal.probes.readiness.successThreshold": 1,
        }

        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'probes': {
                'liveness': {
                    'failureThreshold': 6,
                    'initialDelaySeconds': 120,
                    'periodSeconds': 10,
                    'successThreshold': 1,
                    'timeoutSeconds': 10
                },
                'readiness': {
                    'failureThreshold': 3,
                    'periodSeconds': 10,
                    'successThreshold': 1,
                    'timeoutSeconds': 10
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    # inject_secrets_via_env: false
    def test_anchoreGlobal_inject_secrets_via_env_value(self):
        dot_string_dict = {
            "inject_secrets_via_env": True,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            'injectSecretsViaEnv': True
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    def test_replace_keys_with_mappings_env_var(self):

        dot_string_dict = {"anchoreApi.maxRequestThreads": 999}
        expected_result = {
            'api':
                {'extraEnv': [
                    {'name': 'ANCHORE_MAX_REQUEST_THREADS', 'value': 999}
                ]}
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[1], expected_result)

    def test_replace_keys_with_mappings(self):

        dot_string_dict = {"anchore-feeds-db.persistence.size": 100}
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
            "feeds": {
                "feeds-db": {
                    "primary": {
                        "persistence": {
                            "size": 100
                        }
                    }
                }
            }
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

    # now an environment variable
    def test_anchoreGlobal_serverRequestTimeout_value(self):
        dot_string_dict = {
            "anchoreGlobal.serverRequestTimeout": 300,
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},}
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[0], expected_result)

        expected_env_result = {
            'extraEnv':
                [
                    {
                        'name': 'ANCHORE_GLOBAL_SERVER_REQUEST_TIMEOUT_SEC',
                        'value': 300
                    }
                ]
        }
        self.assertEqual(result[1], expected_env_result)

    def test_anchoreGlobal_maxCompressedImageSizeMB_value(self):
        dot_string_dict = {
            "anchoreGlobal.maxCompressedImageSizeMB": 700
        }
        expected_result = { 'postgresql': {'auth': {'username': 'anchoreengine'}}, 'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
        }

        expected_env_result = {
            'extraEnv':
                [
                    {
                        'name': 'ANCHORE_MAX_COMPRESSED_IMAGE_SIZE_MB',
                        'value': 700
                    }
                ]
        }
        result = replace_keys_with_mappings(dot_string_dict, self.results_dir)
        self.assertEqual(result[1], expected_env_result)


if __name__ == '__main__':
    unittest.main()

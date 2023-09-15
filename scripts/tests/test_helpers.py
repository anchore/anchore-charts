# test_helpers.py
import os
import shutil
import unittest
import yaml
from helpers import (
    create_new_dotstring,
    write_to_file,
    prep_dir,
    dict_keys_to_dot_string,
    merge_dicts,
    replace_keys_with_mappings,
    create_dict_entry,
    convert_values_file
)

# write_to_file(data, file_name): writes data to file_name, returns file_name
class TestWriteToFile(unittest.TestCase):
    def setUp(self):
        self.test_filename = 'test_file.txt'

    def tearDown(self):
        if os.path.exists(self.test_filename):
            os.remove(self.test_filename)

    def test_write_to_file(self):
        data = 'Hello, world!'
        file_name = write_to_file(data, self.test_filename)

        self.assertTrue(os.path.exists(self.test_filename))
        self.assertEqual(file_name, self.test_filename)

        with open(self.test_filename, 'r') as file:
            written_data = file.read()

        self.assertEqual(written_data, data)

# prep_dir(directory_name, clean=False): creates directory_name if it doesn't exist, returns directory_name
class TestPrepDir(unittest.TestCase):
    def empty_dir(self, directory_path):
        # if listdir returns an empty list, the directory is empty, return true
        return not os.listdir(directory_path)

    def setUp(self):
        self.prep_dir_name = 'prep_dir_name'
        if os.path.exists(self.prep_dir_name):
            shutil.rmtree(self.prep_dir_name)

    def tearDown(self):
        if os.path.exists(self.prep_dir_name):
            shutil.rmtree(self.prep_dir_name)

    def test_prep_dir_with_clean(self):
        # create the self.prep_dir_name directory with some stuff in it to confirm its cleared out
        os.makedirs(self.prep_dir_name)
        file_path = os.path.join(self.prep_dir_name, "test_file.txt")

        # Create and close an empty file
        with open(file_path, 'w'):
            pass

        self.assertFalse(self.empty_dir(self.prep_dir_name))

        # clean=True deletes the whole directory, then recreates it
        prep_dir_path = prep_dir(self.prep_dir_name, clean=True)
        self.assertTrue(os.path.exists(self.prep_dir_name))
        self.assertTrue(self.empty_dir(self.prep_dir_name))
        self.assertEqual(prep_dir_path, self.prep_dir_name)

    def test_prep_dir_without_clean(self):
        # create the self.prep_dir_name directory with some stuff in it to confirm its not cleared out
        os.makedirs(self.prep_dir_name)
        file_path = os.path.join(self.prep_dir_name, "test_file.txt")

        # Create and close an empty file
        with open(file_path, 'w'):
            pass

        self.assertFalse(self.empty_dir(self.prep_dir_name))

        # clean=False just creates the directory if it doesn't exist
        prep_dir_path = prep_dir(self.prep_dir_name, clean=False)
        self.assertTrue(os.path.exists(self.prep_dir_name))
        self.assertEqual(prep_dir_path, self.prep_dir_name)
        self.assertFalse(self.empty_dir(self.prep_dir_name))

# dict_keys_to_dot_string(dictionary, prefix=''): recursively converts dictionary keys to dot string representation
# # return a dictionary where the keys are dot string representation of the old keys and
# the value is the original values
class TestDictKeysToDotString(unittest.TestCase):
    def test_dict_keys_to_dotstring(self):
        my_dict = {
            "key1": "value1",
            "key2": "value2",
            "key3": {
                "key31": "value31",
                "key32": "value32",
                "key33": {
                    "key331": "value331",
                    "key332": "value332",
                    "key333": ["value3331", "value3332"]
                }
            },
            "key4": ["value41", "value42"],
            "key5": 5,
            "key6": False
        }

        result = dict_keys_to_dot_string(my_dict)

        self.assertIn("key1", result)
        self.assertEqual(result["key1"], "value1")
        self.assertTrue(isinstance(result["key1"], str))

        self.assertIn("key2", result)
        self.assertEqual(result["key2"], "value2")
        self.assertTrue(isinstance(result["key2"], str))

        self.assertIn("key3.key31", result)
        self.assertEqual(result["key3.key31"], "value31")
        self.assertTrue(isinstance(result["key3.key31"], str))

        self.assertIn("key3.key32", result)
        self.assertEqual(result["key3.key32"], "value32")
        self.assertTrue(isinstance(result["key3.key32"], str))

        self.assertIn("key3.key33.key331", result)
        self.assertEqual(result["key3.key33.key331"], "value331")
        self.assertTrue(isinstance(result["key3.key33.key331"], str))

        self.assertIn("key3.key33.key332", result)
        self.assertEqual(result["key3.key33.key332"], "value332")
        self.assertTrue(isinstance(result["key3.key33.key332"], str))

        self.assertIn("key3.key33.key333", result)
        self.assertEqual(result["key3.key33.key333"], ["value3331", "value3332"])
        self.assertTrue(isinstance(result["key3.key33.key333"], list))

        self.assertIn("key4", result)
        self.assertEqual(result["key4"], ["value41", "value42"])
        self.assertTrue(isinstance(result["key4"], list))

        self.assertIn("key5", result)
        self.assertEqual(result["key5"], 5)
        self.assertTrue(isinstance(result["key5"], int))

        self.assertIn("key6", result)
        self.assertEqual(result["key6"], False)
        self.assertTrue(isinstance(result["key6"], bool))

        self.assertTrue(isinstance(result, dict))

# merge_dicts(dict1, dict2): merges dictionaries, returns merged dictionary
class TestMergeDicts(unittest.TestCase):
    def test_merge_dicts(self):
        dicts1 = {
            "key1": "value1",
            "nested_keys": {
                "uncommon": "uncommon_value",
                "common": "dict1_common_value"
            },
            "common_key": "dict1_common_value"
        }

        dict2 = {
            "key2": "value2",
            "nested_keys": {
                "common": "dict2_common_value"
            },
            "common_key": "dict2_common_value"
        }

        expected_dict = {
            "key1": "value1",
            "key2": "value2",
            "nested_keys": {
                "uncommon": "uncommon_value",
                "common": "dict2_common_value"
            },
            "common_key": "dict2_common_value"
        }

        merge_dicts_result = merge_dicts(dicts1, dict2)

        self.assertEqual(merge_dicts_result, expected_dict)

# create_new_dotstring(keys: list, dotstring: str, level: int) -> str
# takes the original key as a list, a dotstring representation of the new key, and the level that the replacement should occur
# strips off the level number from the original key, and appends the dotstring representation of the new key as a list to the end of the original key
# returns a string
class TestCreateNewDotString(unittest.TestCase):
    def test_create_new_dotstring_level_1(self):
        keys = ["key1", "key2", "key3"]
        dotstring = "key4"
        level = 1

        expected_result = "key4.key2.key3"

        result = create_new_dotstring(keys, dotstring, level)

        self.assertEqual(result, expected_result)

    def test_create_new_dotstring_level_2(self):
        keys = ["key1", "key2", "key3"]
        dotstring = "key4"
        level = 2

        expected_result = "key4.key3"

        result = create_new_dotstring(keys, dotstring, level)

        self.assertEqual(result, expected_result)

    def test_create_new_dotstring_level_3(self):
        keys = ["key1", "key2", "key3"]
        dotstring = "key4"
        level = 3

        expected_result = "key4"

        result = create_new_dotstring(keys, dotstring, level)

        self.assertEqual(result, expected_result)

# create_dict_entry(dotstring, value)
# takes a dotstring and a value, returns a dictionary where the keys are created from the dot string representation
class TestCreateDictEntry(unittest.TestCase):
    def test_create_dict_entry(self):
        dotstring = "key1.key2.key3"
        value = "value"

        expected_result = {
            "key1": {
                "key2": {
                    "key3": "value"
                }
            }
        }

        result = create_dict_entry(dotstring, value)

        self.assertEqual(result, expected_result)

# convert_values_file(file, results_dir)
class TestConvertValuesFile(unittest.TestCase):
    def setUp(self):
        original_test_config_file = 'tests/configs/test_convert_values_file.yaml'
        self.expected_result_file = 'tests/configs/test_convert_values_file_result.yaml'
        self.temp_test_config_file = 'test_values.yaml'
        self.test_results_dir = 'test_results_dir'
        shutil.copy(original_test_config_file, self.temp_test_config_file)

    def tearDown(self):
        if os.path.exists(self.temp_test_config_file):
            os.remove(self.temp_test_config_file)
        if os.path.exists(self.test_results_dir):
            shutil.rmtree(self.test_results_dir)

    def test_convert_values_file(self):
        convert_values_file(self.temp_test_config_file, self.test_results_dir)
        self.assertTrue(os.path.exists(self.test_results_dir))
        self.assertTrue(os.path.exists(os.path.join(self.test_results_dir, 'enterprise.test_values.yaml')))
        self.assertTrue(os.path.exists(os.path.join(self.test_results_dir, 'dotstring.txt')))
        converted = dict()
        with open(os.path.join(self.test_results_dir, 'enterprise.test_values.yaml'), 'r') as content:
            converted = yaml.safe_load(content)

        with open(self.expected_result_file, 'r') as expected_content:
            expected_result = yaml.safe_load(expected_content)

        self.assertEqual(converted, expected_result)

# replace_keys_with_mappings(dot_string_dict, results_dir):
# returns a dictionary where the keys are created from the dot string representation
class TestReplaceKeysWithMappings(unittest.TestCase):
    def setUp(self):
        self.results_dir = "test_results_dir"

    def tearDown(self):
        if os.path.exists(self.results_dir):
            shutil.rmtree(self.results_dir)

    def test_replace_keys_with_mappings(self):

        dot_string_dict = {"anchore-feeds-db.persistence.size": 100}
        expected_result = {
            'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
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

        anchore_config_expected_results = {
            'anchoreConfig': {'user_authentication': {'hashed_passwords': False}},
        }
        self.assertEqual(result[0], anchore_config_expected_results)

if __name__ == '__main__':
    unittest.main()
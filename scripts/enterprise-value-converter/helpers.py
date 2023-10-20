import copy
import os
import pathlib
import shutil
import yaml

from mappings import (
    KEYS_WITHOUT_CHANGES,
    KUBERNETES_KEYS,
    TOP_LEVEL_MAPPING,
    FULL_CHANGE_KEY_MAPPING, LEVEL_TWO_CHANGE_KEY_MAPPING, LEVEL_THREE_CHANGE_KEY_MAPPING,
    DEPENDENCY_CHARTS,
    ENTERPRISE_ENV_VAR_MAPPING, FEEDS_ENV_VAR_MAPPING,
    DEPRECATED_KEYS, CHECK_LAST,
    POST_PROCESSING
)

def represent_block_scalar(dumper, data):
    style = "|" if "\n" in data else '"'
    return dumper.represent_scalar("tag:yaml.org,2002:str", data, style=style)

def convert_to_str(env_var):
    if isinstance(env_var, dict):
        if not isinstance(env_var.get('value'), str):
            env_var['value'] = str(env_var.get('value'))
    else:
        return str(env_var)

def convert_values_file(file, results_dir):
    file_name = os.path.basename(file)
    prep_dir(path=results_dir, clean=True)

    with open(file, 'r') as content:
        parsed_data = yaml.safe_load(content)

    dot_string_dict = dict_keys_to_dot_string(parsed_data)
    write_to_file(data=str("\n".join(f"{key} = {val}" for key, val in dot_string_dict.items())), output_file=os.path.join(results_dir, "dotstring.txt"), write_mode="w")

    enterprise_chart_values_dict, enterprise_chart_env_var_dict = replace_keys_with_mappings(dot_string_dict, results_dir)

    for key, val in enterprise_chart_env_var_dict.items():
        if isinstance(val, list):
            for index, env_var in enumerate(val):
                val[index] = convert_to_str(env_var) or env_var
        elif isinstance(val, dict):
            for index, env_var in enumerate(val.get("extraEnv", [])):
                val["extraEnv"][index] = convert_to_str(env_var) or env_var

        # taking the environment variables and adding it into the enterprise_chart_values_dict to make one dictionary
        if key not in enterprise_chart_values_dict:
            val_type = type(val)
            enterprise_chart_values_dict[key] = val_type()
        if isinstance(val, list):
            enterprise_chart_values_dict[key] = enterprise_chart_values_dict[key] + val
        elif isinstance(val, dict):
            enterprise_chart_values_dict[key] = enterprise_chart_values_dict.get(key, {})
            enterprise_chart_values_dict[key]["extraEnv"] = enterprise_chart_values_dict[key].get("extraEnv", [])
            enterprise_chart_values_dict[key]["extraEnv"] = enterprise_chart_values_dict[key]["extraEnv"] + val.get("extraEnv", [])

    # for the current bitnami postgres chart, if your user is specifically the 'postgres' admin user, you need to override global.postgresql.auth.postgresPassword
    if (enterprise_chart_values_dict.get('postgresql', {}).get('auth', {}).get('username') == 'postgres') and (enterprise_chart_values_dict.get('postgresql', {}).get('auth', {}).get('password')):
        enterprise_chart_values_dict['postgresql']['auth']['postgresPassword'] = enterprise_chart_values_dict['postgresql']['auth']['password']

    yaml.add_representer(str, represent_block_scalar)
    yaml_data = yaml.dump(enterprise_chart_values_dict, default_flow_style=False)
    file_name = f"enterprise.{file_name}"
    write_to_file(data=yaml_data, output_file=os.path.join(results_dir, file_name), write_mode="w")

def write_to_file(data, output_file, write_mode='w'):
    file_parent_dir = pathlib.Path(output_file).parent
    prep_dir(file_parent_dir)
    with open(f"{output_file}", write_mode) as file:
        file.write(data)
    return f"{output_file}"

def prep_dir(path, clean=False):
    if clean:
        if pathlib.Path(path).is_dir():
           shutil.rmtree(path)
    if not pathlib.Path(path).is_dir():
        pathlib.Path(path).mkdir(parents=True, exist_ok=True)
    return path

# return as the first return value, a dictionary where the keys are dot string representation of the old keys and
# the value is the original values
def dict_keys_to_dot_string(dictionary, prefix=''):
    result = {}
    for key, value in dictionary.items():
        full_key = f'{prefix}.{key}' if prefix else key
        if isinstance(value, dict) and bool(value):
            sub_dict = dict_keys_to_dot_string(value, full_key)
            result.update(sub_dict)
        else:
            result[full_key] = value
    return result

# returns the resulting dictionary that will be used to create the new values file
def replace_keys_with_mappings(dot_string_dict, results_dir):
    result = {}
    env_var_results = {}
    keys_without_changes = KEYS_WITHOUT_CHANGES
    top_level_mapping = TOP_LEVEL_MAPPING
    kubernetes_keys = KUBERNETES_KEYS
    full_change_key_mapping = FULL_CHANGE_KEY_MAPPING

    level_two_change_key_mapping = LEVEL_TWO_CHANGE_KEY_MAPPING
    level_three_change_key_mapping = LEVEL_THREE_CHANGE_KEY_MAPPING

    enterprise_env_var_mapping = ENTERPRISE_ENV_VAR_MAPPING
    feeds_env_var_mapping = FEEDS_ENV_VAR_MAPPING
    deprecated_keys = DEPRECATED_KEYS
    dependency_charts_keys = DEPENDENCY_CHARTS
    check_last = CHECK_LAST
    post_processing = POST_PROCESSING

    env_var_mapping = {**enterprise_env_var_mapping, **feeds_env_var_mapping}
    logs_dir = f"{results_dir}/logs"
    if not dot_string_dict.get("postgresql.postgresUser"):
        log_file_name = "info.log"
        write_to_file(f"setting postgres user as anchoreengine as one was not set and this value was changed in enterprise.\n", os.path.join(logs_dir, log_file_name), "a")
        dot_string_dict["postgresql.postgresUser"] = "anchoreengine"
    if not dot_string_dict.get("anchoreGlobal.hashedPasswords"):
        log_file_name = "warning.log"
        write_to_file(f"hashedPasswords is not currently used. You should _really_ consider using it. Please see docs on how to migrate to hashed passwords.\n", os.path.join(logs_dir, log_file_name), "a")
        dot_string_dict["anchoreGlobal.hashedPasswords"] = False
    for dotstring_key, val in dot_string_dict.items():
        keys = dotstring_key.split('.')

        if deprecated_keys.get(dotstring_key):
            log_file_name = "warning.log"
            write_to_file(f"{dotstring_key}: no longer used\n", os.path.join(logs_dir, log_file_name), "a")
            continue

        # serviceName.service.annotations
        if len(keys) > 2 and keys[2] in ['annotations', 'labels']:
            if val != {}:
                val = {
                    '.'.join(keys[3:]): val
                }
            keys = keys[:3]

        # serviceName.annotations
        elif len(keys) > 1 and keys[1] in ['annotations', 'labels', 'nodeSelector', 'deploymentAnnotations']:
            if val != {}:
                val = {
                    '.'.join(keys[2:]): val
                }
            keys = keys[:2]

        update_result = False
        errored = True

        if dotstring_key in post_processing:
            pp_val = post_processing.get(dotstring_key)
            action = pp_val.get("action")
            if action == "split_value":
                delimeter = pp_val.get("split_on")
                new_vals = val.split(delimeter)
                new_keys = pp_val.get("new_keys")
                combined_dict = dict(zip(new_keys, new_vals))
                for new_key, new_val in combined_dict.items():
                    dict_key = create_dict_entry(new_key, new_val)
                    result = merge_dicts(result, dict_key)
                continue
            elif action == "merge":
                merge_keys = pp_val.get("merge_keys")
                merged_val = []
                for merge_key in merge_keys:
                    merged_val.append(dot_string_dict.get(merge_key))
                merged_val = ":".join(merged_val)

                dotstring_key = pp_val.get("new_key")
                dict_key = create_dict_entry(dotstring_key, merged_val)
                result = merge_dicts(result, dict_key)
                continue
            elif action == "duplicate":
                new_keys = pp_val.get("new_keys")
                for dotstring_key in new_keys:
                    dict_key = create_dict_entry(dotstring_key, copy.deepcopy(val))
                    result = merge_dicts(result, dict_key)
                continue
            elif action == "key_addition":
                new_keys = pp_val.get("new_keys")
                for new_key in new_keys:
                    key = new_key[0]
                    value = new_key[1]
                    if value == "default":
                        value = val
                    dict_key = create_dict_entry(key, value)
                    result = merge_dicts(result, dict_key)
                continue

        if not update_result:
            if full_change_key_mapping.get(dotstring_key):
                dotstring_key = full_change_key_mapping.get(dotstring_key)
                update_result = True
            elif len(keys) > 1:
                level_three_replacement = False
                if len(keys) > 2:
                    level_three_replacement = level_three_change_key_mapping.get(f"{keys[0]}.{keys[1]}.{keys[2]}", False)
                level_two_replacement = level_two_change_key_mapping.get(f"{keys[0]}.{keys[1]}", False)
                top_level_key = top_level_mapping.get(f"{keys[0]}", False)

                if level_three_replacement:
                    # replace the first three keys of the original
                    dotstring_key = create_new_dotstring(keys=keys, dotstring=level_three_replacement, level=3)
                    update_result = True
                # if its not a level 3 replacement, check if its a level 2 replacement
                elif level_two_replacement:
                    dotstring_key = create_new_dotstring(keys=keys, dotstring=level_two_replacement, level=2)
                    update_result = True
                elif top_level_key and (f"{keys[1]}" in kubernetes_keys):
                    keys[0] = top_level_key
                    dotstring_key = ".".join(keys)
                    update_result = True

        if not update_result:
            if env_var_mapping.get(dotstring_key):
                extra_environment_variable = env_var_mapping.get(dotstring_key)

                environment_variable_name = extra_environment_variable.split(".")[-1]
                service_name = ""
                if len(extra_environment_variable.split(".")) > 1:
                    service_name = extra_environment_variable.split(".")[0]

                message = f"{dotstring_key} is now an environment variable: {environment_variable_name}"
                log_file_name = "alert.log"
                write_to_file(f"{message}\n", os.path.join(logs_dir, log_file_name), "a")

                env_dict = {"name": environment_variable_name, "value": val}

                if service_name != "":
                    env_var_results[service_name] = env_var_results.get(service_name, {})
                    if env_var_results[service_name].get("extraEnv"):
                        env_var_results[service_name]["extraEnv"].append(env_dict)
                    else:
                        env_var_results[service_name]["extraEnv"] = [env_dict]
                else:
                    env_var_results["extraEnv"] = env_var_results.get("extraEnv", [])
                    env_var_results["extraEnv"].append(env_dict)
                continue

            elif f"{keys[0]}" in keys_without_changes:
                log_file_name = "info.log"
                write_to_file(f"{dotstring_key}: being carried over directly because there should be no changes\n", os.path.join(logs_dir, log_file_name), "a")
                update_result = True
            elif dependency_charts_keys.get(f"{keys[0]}"):
                new_dep_key = dependency_charts_keys.get(f"{keys[0]}")
                log_file_name = "dependency-chart-alert.log"
                write_to_file(f"{dotstring_key}: {keys[0]} changed to {new_dep_key} but inner keys should be checked.\n", os.path.join(logs_dir, log_file_name), "a")
                keys[0] = new_dep_key
                dotstring_key = ".".join(keys)
                update_result = True
            elif f"{keys[0]}" in check_last:
                keys.pop(0)
                dotstring_key = ".".join(keys)
                update_result = True

        if update_result:
            dict_key = create_dict_entry(dotstring_key, val)
            result = merge_dicts(result, dict_key)
        elif errored:
            if dotstring_key.split('.')[0] in deprecated_keys:
                message = f"{dotstring_key}: not found. likely deprecated.\n"
            else:
                message = f"{dotstring_key}: not found.\n"
            log_file_name = "error.log"
            write_to_file(message, os.path.join(logs_dir, log_file_name), "a")
    return result, env_var_results

def create_new_dotstring(keys: list, dotstring: str, level: int) -> str:
    new_keys = dotstring.split(".")
    new_keys.extend(keys[level:])
    dotstring_key = ".".join(new_keys)
    return dotstring_key

def create_dict_entry(dotstring, value):
    result = {}
    current_dict = result
    keys = dotstring.split('.')

    for index, key in enumerate(keys):
        if index == len(keys) - 1:
            current_dict[key] = value
        else:
            # creates the key with an empty map as a value because theres more to come
            current_dict[key] = {}
            current_dict = current_dict[key]
    return result

def merge_dicts(dict1, dict2):
    merged_dict = dict1.copy()

    for key, value in dict2.items():
        if key in merged_dict and isinstance(merged_dict[key], dict) and isinstance(value, dict):
            merged_dict[key] = merge_dicts(merged_dict[key], value)
        else:
            merged_dict[key] = value

    return merged_dict

import sys
sys.dont_write_bytecode = True

import argparse
from helpers import convert_values_file

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingests one values files, changes the keys based on a declared map, then spits out a different values file")
    parser.add_argument(
        "-e", "--engine-file",
        type=str,
        help="Path to the original values file being ingested",
        default=""
    )
    parser.add_argument(
        "-d", "--results-dir",
        type=str,
        help="directory to put resulting files in",
        default="enterprise-values"
    )

    args = parser.parse_args()
    engine_file = args.engine_file
    results_dir = args.results_dir
    convert_values_file(file=engine_file, results_dir=results_dir)
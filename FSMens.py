"""
Run an ensemble of FSM simulations

Richard Essery
School of GeoSciences
University of Edinburgh
"""

import os
import sys

# global config
fsm_binary_unix = os.path.join('./FSM')
fsm_binary_win = os.path.join('FSM.exe')


def parse_and_write_new_config(input_filename: str, run_num: int, run_id: str):
    tmp_nlst_file = os.path.join('tmp_nlst.txt')
    new_nlst_lines = []
    output_file = None

    # read input file and replace line with config
    with open(input_filename) as file:
        for line in file:
            # replace the line with out_file with the new output filename
            if 'out_file' in line:
                out_file = line.rsplit()[-1].replace('\'', '')
                out_file_parts = out_file.split('.')
                new_out_filename = f'{"".join(out_file_parts[:-1])}_{run_id}.{out_file_parts[-1]}'
                output_file = os.path.join('output', new_out_filename)
                new_nlst_lines.append(f'  out_file = \'{output_file}\'\n')
                continue

            new_nlst_lines.append(line)
            # add config line with run number
            if 'config' in line:
                new_nlst_lines.append(f'  nconfig = {run_num}\n')

    if output_file is None:
        raise Exception('No line with out_file was found in input file')

    # write new nlst.txt file with config for n
    with open(tmp_nlst_file, 'w') as file:
        for line in new_nlst_lines:
            file.write(line)

    return tmp_nlst_file, output_file


def perform_fsm_routine(input_filename: str, fsm_binary: str, total_runs: int = 64):
    print(f"Performing routing with input namelist {input_filename}")

    for n in range(total_runs):
        run_id = "{0:05b}".format(n)
        print(f'Running FSM configuration {run_id} {n}')

        # prepare new nlst file
        nlst_file, output_file = parse_and_write_new_config(input_filename=input_filename, run_num=n, run_id=run_id)

        # run FSM
        os.system(f'{fsm_binary} < {nlst_file}')
        print(f'FSM run finished, output file: {output_file}\n')


if __name__ == "__main__":
    namelist_parameter = sys.argv[1]

    # check if data and output directory exists and create it
    data_dir = os.path.join('data')
    output_dir = os.path.join('output')
    if not os.path.isdir(output_dir):
        os.mkdir(output_dir)
    if not os.path.isdir(data_dir):
        os.mkdir(data_dir)

    # check if input file exists
    namelist_filename = os.path.join(namelist_parameter)
    if not os.path.isfile(namelist_filename):
        raise Exception(f'Input file {namelist_filename} does not exist')

    # check if FSM binary exists
    if os.path.isfile(fsm_binary_unix):
        fsm_binary = fsm_binary_unix
    elif os.path.isfile(fsm_binary_win):
        fsm_binary = fsm_binary_win
    else:
        raise Exception(f'FSM binary does not exist, please compile first')

    perform_fsm_routine(input_filename=namelist_filename, fsm_binary=fsm_binary)

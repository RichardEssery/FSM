"""
Run an ensemble of FSM simulations

Richard Essery
School of GeoSciences
University of Edinburgh
"""

import os
import sys


def perform_fsm_routine(input_filename: str, fsm_binary: str, total_runs: int = 32):
    print(f"Performing routing with input namelist {input_filename}")

    nlst_filename = os.path.join('nlst.txt')

    for n in range(total_runs):
        n_binary = "{0:b}".format(n)
        print(f'Running FSM configuration {n_binary} {n}')

        new_nlst = []
        out_file = os.path.join('out.txt')

        # read input file and replace line with config
        with open(input_filename) as file:
            for line in file:
                new_nlst.append(line)
                if 'config' in line:
                    new_nlst.append(f'  nconfig = {n}\n')

                # the line with out_file includes the filename that FSM will use for output
                if 'out_file' in line:
                    out_file = line.rsplit()[-1]
                    out_file = out_file.replace('\'', '')
                    out_file = os.path.join(out_file)

        # write nlst.txt file with config for n
        with open(nlst_filename, 'w') as file:
            for line in new_nlst:
                file.write(line)
        out_name = out_file.replace('.txt', '')

        # run FSM
        os.system(f'{fsm_binary} < {nlst_filename}')

        # move FSM output file to output directory
        save_file = os.path.join('output', out_name + '_' + n_binary + '.txt')
        os.replace(out_file, save_file)
        print(f'Output file: {save_file}\n')


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
    fsm_binary_unix = os.path.join('./FSM')
    fsm_binary_win = os.path.join('FSM.exe')
    if os.path.isfile(fsm_binary_unix):
        fsm_binary = fsm_binary_unix
    elif os.path.isfile(fsm_binary_win):
        fsm_binary = fsm_binary_win
    else:
        raise Exception(f'FSM binary does not exist, please compile first')

    perform_fsm_routine(namelist_filename, fsm_binary)

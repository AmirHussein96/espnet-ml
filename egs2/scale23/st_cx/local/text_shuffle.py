#!/usr/bin/env python
# Copyright Johns Hopkins (Amir Hussein)
# Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

import sys
import os
import random


def main():

    input_file = sys.argv[1] # data dir
    out_file = sys.argv[2] # data dir
    with open(os.path.join(input_file), 'r') as file:
        file_content = file.readlines()
    
    ids = []
    text = []
    for lines in file_content:
        ids.append(lines.split()[0])
        text.append(lines.split()[1:])
    text_rand = random.sample(text, len(text))

    new_lines = []
    for id_, t in zip(ids, text_rand):
        #breakpoint()
        new_line = [id_]+t
        new_lines.append(" ".join(new_line)+'\n')

    output_filename = os.path.join(out_file)
    with open(output_filename, 'w') as file:
        file.writelines(new_lines)
		
if __name__ == "__main__":
    main()


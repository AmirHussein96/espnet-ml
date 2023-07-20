#!/usr/bin/env python
# Copyright Johns Hopkins (Amir Hussein)
# Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

import sys
import os

def main():

    input_dir = sys.argv[1] # data dir
    lang = sys.argv[2] # data dir
    files = ['utt2spk','segments','text.prev', 'text.prev.tc.eng', 'text.tc.eng', f'text.tc.rm.lid.{lang}','text', 'text.prev.eng', f'text.tc.rm.{lang}']
    file_contents = {}
    results = {file_name: [] for file_name in files}
    for file_name in files:
        with open(os.path.join(input_dir,file_name), 'r') as file:
            file_contents[file_name] = file.readlines()
    

    count = 0
    for i in range(len(file_contents['text.tc.eng'])):
        eng, ara = file_contents['text.tc.eng'][i].split()[1:], file_contents[f'text.tc.rm.lid.{lang}'][i].split()[1:]
        eng_cx = file_contents['text.prev.tc.eng'][i].split()[1:]
        if len(eng) < 100 and len(eng)/len(ara) <= 3:
            # if len(eng_cx) >50:
                # count += 1
                # content_tc  = file_contents['text.prev.tc.eng'][i].split()
                # content  = file_contents['text.prev.eng'][i].split()
                # assert content_tc[0] == content[0]
                # file_contents['text.prev.tc.eng'][i] = content_tc[0] + " "+ " ".join(content_tc[-35:])+ "\n"
                # file_contents['text.prev.eng'][i] = content[0]+ " "+ " ".join(content[-35:]) + '\n'
            for file_name in files:
                results[file_name].append(file_contents[file_name][i])

    #     else:
    #         if i < len(file_contents['text.tc.eng'])-1 :
    #             count+=1
    #             print(file_contents['text.prev.tc.eng'][i+1])
    #             print(file_contents['text.tc.eng'][i])
    #             print(file_contents[f'text.tc.rm.lid.{lang}'][i])
    #             content  = file_contents['text.prev.tc.eng'][i+1].split()
    #             file_contents['text.prev.tc.eng'][i+1] = " ".join([content[0],'<na>'])
    # print('Len after cleaning')
    for file_name in files:
        print(f'{file_name}: {len(results[file_name])}')  
    print(f"Reduced long context: {count}")  
    output_dir = 'tmp'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for file_name in files:
        output_filename = os.path.join(output_dir, f"{file_name}")
        with open(output_filename, 'w') as file:
            file.writelines(results[file_name])
		
if __name__ == "__main__":
    main()


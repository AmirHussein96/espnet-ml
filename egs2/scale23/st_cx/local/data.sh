#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined vaiable', -o ... 'error in pipeline', -x 'print commands',
# set -e
# set -u
# set -o pipefail

. ./db.sh || exit 1;
. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

stage=1
stop_stage=3

log "$0 $*"
. utils/parse_options.sh

if [ -z "${SCALE23}" ]; then
    log "Fill the value of 'SCALE23' of db.sh"
    exit 1
fi

if [ $# -ne 0 ]; then
    log "Error: No positional arguments are required."
    exit 2
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    log "stage 1: stm to kaldi"

    # sets="train-cts train-ood train-all dev test-cts test-ood"
    sets="train-cts train-ood train-all"
    langs="ara cmn kor rus spa"

    for lang in $langs
    do
        for set in $sets
        do
            local/convert_stm_to_espnet.sh --train_set ${set} --dev_set dev --src_lang ${lang}
        done
    done
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    log "stage 2: Normalize Transcripts"

    # check extra module installation
    if ! command -v tokenizer.perl > /dev/null; then
        echo "Error: it seems that moses is not installed." >&2
        echo "Error: please install moses as follows." >&2
        echo "Error: cd ${MAIN_ROOT}/tools && make moses.done" >&2
        exit 1
    fi
    declare -A cts_testset_dict
    declare -A ood_testset_dict
    declare -A lang_code_dict

    cts_testset_dict=( ["ara"]="iwslt22" ["cmn"]="bbn_cts_bolt" ["kor"]="uhura" ["rus"]="uhura" ["spa"]="fisher callhome" )
    ood_testset_dict=( ["ara"]="fleurs" ["cmn"]="fleurs" ["kor"]="fleurs" ["rus"]="fleurs" ["spa"]="fleurs" )
    lang_code_dict=( ["ara"]="ar" ["cmn"]="zh" ["kor"]="kr" ["rus"]="ru" ["spa"]="es" )
    for lang in ara cmn kor rus spa
    do
        for set_type in train-cts train-ood train-all dev test
        do
            set_list=${set_type}
            if [ $set_type = "test" ]; then
                set_list="${cts_testset_dict[${lang}]} ${ood_testset_dict[${lang}]}"
            fi
            for set_prefix in $set_list
            do
                if [ $set_type = "test" ]; then
                    set=${set_prefix}_test_${lang}
                else
                    set=${set_prefix}_${lang}
                fi
                cut -d ' ' -f 2- data/${set}/text.${lang} > data/${set}/${lang}.org
				#cut -d ' ' -f 2- data/${set}/text.prev.${lang} > data/${set}/${lang}.prev.org
				
                cut -d ' ' -f 1 data/${set}/text.${lang} > data/${set}/uttlist

                code=${lang_code_dict[${lang}]}
                echo $code
                echo $set
                
                tokenizer.perl -l ${code} -q < data/${set}/${lang}.org > data/${set}/${lang}.tok
                #tokenizer.perl -l ${code} -q < data/${set}/${lang}.prev.org > data/${set}/${lang}.prev.tok
				
                # remove punctuation
                /home/hltcoe/ahussein/brian/espnet-ml/utils/remove_punctuation.pl < data/${set}/${lang}.tok > data/${set}/${lang}.rm
				#/home/hltcoe/ahussein/brian/espnet-ml/utils/remove_punctuation.pl < data/${set}/${lang}.prev.tok > data/${set}/${lang}.prev.rm
				
                paste -d ' ' data/${set}/uttlist data/${set}/${lang}.rm > data/${set}/text.tc.rm.${lang}
				#paste -d ' ' data/${set}/uttlist data/${set}/${lang}.prev.rm > data/${set}/text.prev.tc.rm.${lang}

                # add LID tag
                sed -e "s/^/[${lang}] /" data/${set}/${lang}.rm > data/${set}/${lang}.rm.lid
                paste -d ' ' data/${set}/uttlist data/${set}/${lang}.rm.lid > data/${set}/text.tc.rm.lid.${lang}

                cut -d ' ' -f 2- data/${set}/text.eng > data/${set}/eng.org
				cut -d ' ' -f 2- data/${set}/text.prev.eng > data/${set}/prev.eng.org
                cut -d ' ' -f 2- data/${set}/text.prev2.eng > data/${set}/prev2.eng.org
                cut -d ' ' -f 2- data/${set}/text.prev3.eng > data/${set}/prev3.eng.org
                # tokenize
                tokenizer.perl -l en -q < data/${set}/eng.org > data/${set}/eng.tok
				tokenizer.perl -l en -q < data/${set}/prev.eng.org > data/${set}/prev.eng.tok
                tokenizer.perl -l en -q < data/${set}/prev2.eng.org > data/${set}/prev2.eng.tok
                tokenizer.perl -l en -q < data/${set}/prev3.eng.org > data/${set}/prev3.eng.tok

				sed -i -e 's:xnax:<na>:g' -e 's:xuttx:<utt>:g' data/${set}/prev.eng.tok
                sed -i -e 's:xnax:<na>:g' -e 's:xuttx:<utt>:g' data/${set}/prev2.eng.tok
                sed -i -e 's:xnax:<na>:g' -e 's:xuttx:<utt>:g' data/${set}/prev3.eng.tok
				
                paste -d ' ' data/${set}/uttlist data/${set}/eng.tok > data/${set}/text.tc.eng
				paste -d ' ' data/${set}/uttlist data/${set}/prev.eng.tok > data/${set}/text.prev.tc.eng
                paste -d ' ' data/${set}/uttlist data/${set}/prev2.eng.tok > data/${set}/text.prev2.tc.eng
                paste -d ' ' data/${set}/uttlist data/${set}/prev3.eng.tok > data/${set}/text.prev3.tc.eng
				#paste -d ' ' data/${set}/uttlist data/${set}/eng.org > data/${set}/text.tc.eng
				#paste -d ' ' data/${set}/uttlist data/${set}/prev.eng.org > data/${set}/text.prev.tc.eng
				if [ "$lang" = "ara" ]; then
					cp -r data/${set} tmp
					python local/remove_bad_segments.py data/${set} ${lang}
					cp tmp/* data/${set}/
					rm -rf tmp
				fi

                # remove empty lines that were previously only punctuation
                # use fix_data_dir as is, where it does reduce lines based on extra files
                <"data/${set}/text.tc.rm.${lang}" awk ' { if( NF != 1 ) print $0; } ' >"data/${set}/text"
                utils/fix_data_dir.sh --utt_extra_files "text.tc.rm.${lang} text.tc.rm.lid.${lang} text.tc.eng text.eng text.${lang} text.prev.eng text.prev.tc.eng text.prev2.tc.eng text.prev3.tc.eng" data/${set}
                cp data/${set}/text.tc.rm.lid.${lang} data/${set}/text
                utils/fix_data_dir.sh --utt_extra_files "text.tc.rm.${lang} text.tc.rm.lid.${lang} text.tc.eng text.eng text.${lang} text.prev.tc.eng text.prev.eng text.prev2.tc.eng text.prev3.tc.eng" data/${set}
                utils/validate_data_dir.sh --no-feats data/${set} || exit 1s

                # create random text
                python local/text_shuffle.py data/${set}/text.prev.tc.eng data/${set}/text.prev.rand.tc.eng
            done
        done
    done
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    log "stage 3: combining across langs"
    for domain in all cts ood
    do
        utils/combine_data.sh --extra_files "text.tc.eng text text.prev.tc.eng text.prev2.tc.eng text.prev3.tc.eng text.prev.rand.tc.eng" data/train-${domain}_all data/train-${domain}_ara data/train-${domain}_cmn data/train-${domain}_kor data/train-${domain}_rus data/train-${domain}_spa
        cp data/train-${domain}_all/text data/train-${domain}_all/text.tc.rm.lid.all
    done

    utils/combine_data.sh --extra_files "text.tc.eng text text.prev.tc.eng text.prev2.tc.eng text.prev3.tc.eng text.prev.rand.tc.eng" data/dev_all data/dev_ara data/dev_cmn data/dev_kor data/dev_rus data/dev_spa
    cp data/dev_all/text data/dev_all/text.tc.rm.lid.all
fi

log "Successfully finished. [elapsed=${SECONDS}s]"

#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
# set -e
# set -u
# set -o pipefail

domain=all      #all, cts, ood
src_lang=all

train_set=train-${domain}_${src_lang}
train_dev=dev_${src_lang}

if [ ${src_lang} = "ara" ]; then
    test_set="iwslt22_test_ara"
elif [ ${src_lang} = "cmn" ]; then
    test_set="bbn_cts_bolt_test_cmn"
elif [ ${src_lang} = "kor" ]; then
    test_set="uhura_test_kor"
elif [ ${src_lang} = "rus" ]; then
    test_set="uhura_test_rus"
elif [ ${src_lang} = "spa" ]; then
    test_set="fisher_test_spa callhome_test_spa"
else
    test_set="iwslt22_test_ara bbn_cts_bolt_test_cmn uhura_test_kor uhura_test_rus fisher_test_spa callhome_test_spa"
fi

asr_config=conf/tuning/train_asr_conformer.yaml
inference_config=conf/tuning/decode_asr_conformer.yaml

nbpe=16000

## Recommend to do data prep in st1, then copy/soft link the dump directory:
if [ -e ../st1/dump ]; then
    if [ ! -e . ]; then
        ln -s ../st1/dump .
    fi
else 
    echo "run stages 1-5 of scale23/st1"
    # exit
fi
if [ -e ../st1/data ]; then
    if [ ! -e . ]; then
        mkdir -p data/${src_lang}_token_list
        cd data/${src_lang}_token_list && cp -r ../../../st1/data/all_eng_token_list/src_bpe_unigram16000 bpe_unigram16000 && cd -
    fi
else 
    echo "run stages 1-5 of scale23/st1"
    # exit
fi

./asr.sh \
    --skip_data_prep true \
    --audio_format "flac.ark" \
    --nj 40 \
    --inference_nj 40 \
    --lang ${src_lang} \
    --token_type "bpe" \
    --nbpe $nbpe \
    --feats_type raw \
    --speed_perturb_factors "0.9 1.0 1.1" \
    --asr_config "${asr_config}" \
    --inference_config "${inference_config}" \
    --train_set "${train_set}" \
    --valid_set "${train_dev}" \
    --test_sets "${test_set}" \
    --bpe_train_text "data/${train_set}/text" \
    --lm_train_text "data/${train_set}/text"  "$@" \
    --expdir exp_${domain}_${src_lang} \
    --bpe_nlsyms "[ara],[cmn],[kor],[rus],[spa]"
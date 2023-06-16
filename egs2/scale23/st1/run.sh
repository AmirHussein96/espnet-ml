#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
# set -e
# set -u
# set -o pipefail

domain=all      #all, cts, ood
src_lang=all
tgt_lang=eng

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

st_config=conf/tuning/train_st_conformer.yaml
inference_config=conf/tuning/decode_st_conformer.yaml

src_nbpe=16000
tgt_nbpe=8000

# tc: truecase
# lc: lowercase
# lc.rm: lowercase with punctuation removal
# lid: language id tag
src_case=tc.rm.lid
tgt_case=tc

./st.sh \
    --audio_format "flac.ark" \
    --nj 40 \
    --inference_nj 40 \
    --src_lang ${src_lang} \
    --tgt_lang ${tgt_lang} \
    --src_token_type "bpe" \
    --src_nbpe $src_nbpe \
    --tgt_token_type "bpe" \
    --tgt_nbpe $tgt_nbpe \
    --src_case ${src_case} \
    --tgt_case ${tgt_case} \
    --feats_type raw \
    --speed_perturb_factors "0.9 1.0 1.1" \
    --st_config "${st_config}" \
    --inference_config "${inference_config}" \
    --train_set "${train_set}" \
    --valid_set "${train_dev}" \
    --test_sets "${test_set}" \
    --src_bpe_train_text "data/${train_set}/text.${src_case}.${src_lang}" \
    --tgt_bpe_train_text "data/${train_set}/text.${tgt_case}.${tgt_lang}" \
    --lm_train_text "data/${train_set}/text.${tgt_case}.${tgt_lang}"  "$@" \
    --expdir exp_${domain}_${src_lang} \
    --src_bpe_nlsyms "[ara],[cmn],[kor],[rus],[spa]"

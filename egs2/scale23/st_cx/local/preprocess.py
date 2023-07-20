#!/usr/bin/env python3
# -*- encoding: utf8 -*-

"""
   TBD
"""

import argparse
import itertools
import os
import re
import sys

parser = argparse.ArgumentParser()
parser.add_argument(
    "--out",
    "-o",
    type=str,
    help="Path to output directory.",
)
parser.add_argument(
    "--set",
    type=str,
)
parser.add_argument(
    "--lang",
    type=str,
)
parser.add_argument(
    "--data",
    type=str,
)
args = parser.parse_args()


def time_to_hash(time_str):
    ret = "%08.3F" % float(time_str)
    return "".join(str(ret).split("."))


def stm_to_kaldi(st_stm, asr_stm, dst, lang):
    data = {"F": [], "C": [], "S": [], "BT": [], "ET": [], "text_sr": [], "text_st": []}
    with open(st_stm, "r", encoding="utf-8") as st_stm, open(
        asr_stm, "r", encoding="utf-8"
    ) as asr_stm:
        st_lines = st_stm.readlines()
        asr_lines = asr_stm.readlines()
        for i, (st_li, asr_li) in enumerate(zip(st_lines, asr_lines)):
            F, C, S, BT, ET, _, text_st = st_li.strip().split(" ", 6)
            F2, _, _, _, _, _, text_sr = asr_li.strip().split(" ", 6)
            if F != F2:
                sys.exit("ASR and ST STM files are not in the same order", F, F2)
            data["F"].append(F)
            data["C"].append(C)
            data["S"].append(S)
            data["BT"].append(BT)
            data["ET"].append(ET)
            data["text_sr"].append(text_sr)
            data["text_st"].append(text_st)

    with open(dst + "/wav.scp", "w", encoding="utf-8") as wav_scp, open(
        dst + "/utt2spk", "w", encoding="utf-8"
    ) as utt2spk, open(dst + "/segments", "w", encoding="utf-8") as segments, open(
        dst + "/text.eng", "w", encoding="utf-8"
    ) as text_eng, open(
        dst + "/text." + lang, "w", encoding="utf-8"
    ) as text_src, open(
        dst + "/reco2file_and_channel", "w", encoding="utf-8"
    ) as reco2file:
        for i in range(len(data["F"])):
            recid = data["F"][i].split("/")[-1].split(".")[0]
            uttid = (
                data["S"][i]
                + "_"
                + recid
                + "_"
                + time_to_hash(data["BT"][i])
                + "-"
                + time_to_hash(data["ET"][i])
            )
            sox_cmd = "sox -R -t wav - -t wav - rate 16000 dither |"
            wav_scp.write(
                " ".join(
                    [
                        recid,
                        "sph2pipe -f wav -p -c",
                        data["C"][i],
                        data["F"][i],
                        "|",
                        sox_cmd,
                    ]
                )
                + "\n"
            )
            utt2spk.write(" ".join([uttid, data["S"][i]]) + "\n")
            segments.write(
                " ".join([uttid, recid, data["BT"][i], data["ET"][i]]) + "\n"
            )
            text_eng.write(" ".join([uttid, data["text_st"][i]]) + "\n")
            text_src.write(" ".join([uttid, data["text_sr"][i]]) + "\n")
            # 2 channels are stored as separate sph, each with only 1 channel
            reco2file.write(" ".join([recid, recid, "A"]) + "\n")


if __name__ == "__main__":
    stm_to_kaldi(
        args.data + "/3-way/" + args.lang + "/st." + args.lang + "-eng." + args.set + ".stm",
        args.data + "/3-way/" + args.lang + "/sr." + args.lang + "-" + args.lang + "." + args.set + ".stm",
        args.out,
        args.lang,
    )

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright 2019 Tobias Küchel <devel@zukuul.de>
# This piece of software is licensed under:
# SPDX-License-Identifier: GPL-3.0-or-later

import sys,os
import re
import gender_guesser.detector as gender
from unidecode import unidecode
#import unicodedata

regex= r"[0-9]+"
d = gender.Detector(case_sensitive=False)

with open("add.csv") as f:
    lines = f.readlines()

collected_classes = {}
for line in lines:
    data = line.split(";")
    if not data[0] in collected_classes:
        ## find number in classname
        restufe = re.search(regex, data[0])
        if not restufe:
            guess = None
        else:
            if restufe.group() == "2":
                guess = "13"
            elif restufe.group() == "1":
                guess = "12"
            else:
                guess = restufe.group()
        print("%s => %s : ok? oder andere Stufe eingeben. (Enter, 0-13)" % ( data[0], guess), end='')
        classname = input()
        if classname != "":
            collected_classes[data[0]] = classname
        else:
            collected_classes[data[0]] = guess
print(collected_classes)

final = []
for line in lines:
    data = line.split(";")
    surname = data[1]
    firstname = data[2]
    klasse = data[0]
    username = data[3]
    if not data[0] in collected_classes:
        print("Problem: Klassenstufenbezeichnung %s gefunden und keine Klasse dazu bekannt. Exit")
        sys.exit()
    else:
        stufe = collected_classes[data[0]]
    if not stufe:
        print("Ignoriere %s" % data)
        continue

    g = d.get_gender(firstname)
    if g in ["unknown", "andy", "mostly_male", "mostly_female"]:
        print(klasse, stufe, firstname, surname, g)
        g = input("Give gender on commandline m or f: ")
        #g = "m"
        if g == "m":
            g = "male"
        elif g == "f": 
            g = "female"
        else:
            g = "anonym"
    username = "hgk-" + unidecode(username).lower()  # + "-" + data[3].split(".")[0]
    passwd = unidecode(username).lower()
    final.append(",".join([klasse,stufe,firstname,surname,username,passwd,g]))

with open("schueler.biber.csv", "w") as f:
    f.writelines("%s\n" % l for l in final)


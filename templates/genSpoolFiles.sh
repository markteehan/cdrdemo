#!/bin/bash
DT=`date "+%Y-%m-%dT%H:%M:%S"`
DT2=`date "+%H%M"`
HOST=`hostname`
LINES=REPLACEME_LINES
FILES=REPLACEME_FILES
WORDS="Afghanistan Albania Algeria Andorra Angola Antigua&Deps Argentina Armenia Australia Austria Azerbaijan Bahamas Bahrain Bangladesh Barbados Belarus Belgium Belize Benin Bhutan Bolivia BosniaHerzegovina Botswana Brazil Brunei Bulgaria Burkina Burundi Cambodia Cameroon Canada CapeVerde CentralAfricanRep Chad Chile China Colombia Comoros Congo CongoDemocraticRep CostaRica Croatia Cuba Cyprus CzechRepublic Denmark Djibouti Dominica DominicanRepublic EastTimor Ecuador Egypt ElSalvador EquatorialGuinea Eritrea Estonia Ethiopia Fiji Finland France Gabon Gambia Georgia Germany Ghana Greece Grenada Guatemala Guinea Guinea-Bissau Guyana Haiti Honduras Hungary Iceland India Indonesia Iran Iraq IrelandRepublic Israel Italy IvoryCoast Jamaica Japan Jordan Kazakhstan Kenya Kiribati KoreaNorth KoreaSouth Kosovo Kuwait Kyrgyzstan Laos Latvia Lebanon Lesotho Liberia Libya Liechtenstein Lithuania Luxembourg Macedonia Madagascar Malawi Malaysia Maldives Mali Malta MarshallIslands Mauritania Mauritius Mexico Micronesia Moldova Monaco Mongolia Montenegro Morocco Mozambique MyanmarBurma Namibia Nauru Nepal Netherlands NewZealand Nicaragua Niger Nigeria Norway Oman Pakistan Palau Panama PapuaNewGuinea Paraguay Peru Philippines Poland Portugal Qatar Romania RussianFederation Rwanda StKitts&Nevis StLucia SaintVincent&theGrenadines Samoa SanMarino SaoTome&Principe SaudiArabia Senegal Serbia Seychelles SierraLeone Singapore Slovakia Slovenia SolomonIslands Somalia SouthAfrica SouthSudan Spain SriLanka Sudan Suriname Swaziland Sweden Switzerland Syria Taiwan Tajikistan Tanzania Thailand Togo Tonga Trinidad&Tobago Tunisia Turkey Turkmenistan Tuvalu Uganda Ukraine UnitedArabEmirates UnitedKingdom UnitedStates Uruguay Uzbekistan Vanuatu VaticanCity Venezuela Vietnam Yemen Zambia Zimbabwe"
QUEUED=/var/tmp/QUEUED_WIP
mkdir -p ${QUEUED}
chmod 777 ${QUEUED}

  for run in $(seq 1 ${LINES})
  do
    SMALL_R=$((RANDOM%10+1))
    MED_R=$((RANDOM%100+1))
    BIG_R=$((RANDOM%10000+1))
    WORD=`shuf -en1 ${WORDS}`
    L1="${WORD},${BIG_R},510897177718054,${SMALL_R},6,${RUN},4,${MED_R},510897177718054,6289665801120,8661960317518412,74940,6,4G,20947,20947,61314,7832,90,91,91,202.67.33.224,10.10.50.202,202.67.33.209,10.28.201.107,40439,161.117.98.145,80,313,1300,0,0,4,10,0,0,5014346,3062228,1562106689621679,1562106689609168,1562106704664717,1562106717169243,0,1562106689609168,1562106717169243,27560075,28,40,12,0,1,3,0,28358006,70728,494,0,0,53650,14,1562103926130934,0,5,-1,,,,3gprs,local,510-89-10719-110722-3,510-89,510-89,,,1562106689.609,,-1,64,8297500063272707160,1023496466"
    echo ${L1} >> ${QUEUED}/seed.TXT
  done

  THREAD=01
  for i in $(seq 1 ${FILES})
  do
    #each file is 27MB
     LOW=`echo |awk -v i=$i '{printf "%08d",50000*(i-1)}'`
    HIGH=`echo |awk -v i=$i '{printf "%08d",50000*(i)}'`
    size=`echo |awk -v i=$i '{printf "%06d",27*i}'`
    filen=`echo |awk -v i=$i '{printf "%03d",i}'`
    case $THREAD in
    "01")  cp ${QUEUED}/seed.TXT ${QUEUED}/${LOW}_to_${HIGH}__${size}mb_${HOST}__${filen}__task01.txt
           THREAD=02
           ;;
    "02")  cp ${QUEUED}/seed.TXT ${QUEUED}/${LOW}_to_${HIGH}__${size}mb_${HOST}__${filen}__task02.txt
           THREAD=03
           ;;
    "03")  cp ${QUEUED}/seed.TXT ${QUEUED}/${LOW}_to_${HIGH}__${size}mb_${HOST}__${filen}__task03.txt
           THREAD=04
           ;;
    "04")  cp ${QUEUED}/seed.TXT ${QUEUED}/${LOW}_to_${HIGH}__${size}mb_${HOST}__${filen}__task04.txt
           THREAD=05
           ;;
    "05")  cp ${QUEUED}/seed.TXT ${QUEUED}/${LOW}_to_${HIGH}__${size}mb_${HOST}__${filen}__task05.txt
           THREAD=01
           ;;
    esac
  done
rm ${QUEUED}/seed.TXT
mv /var/tmp/QUEUED_WIP/* /var/tmp/queued
rmdir /var/tmp/QUEUED_WIP

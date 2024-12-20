#! /bin/bash
# Asterisk voicemail attachment conversion script 
# Revision history :
# 22/11/2010 - V1.0 - Creation by N. Bernaerts
# 07/02/2012 - V1.1 - Add handling of mails without attachment (thanks to Paul Thompson)
# 01/05/2012 - V1.2 - Use mktemp, pushd & popd
# 08/05/2012 - V1.3 - Change mp3 compression to CBR to solve some smartphone compatibility (thanks to Luca Mancino)
# 01/08/2012 - V1.4 - Add PATH definition to avoid any problem (thanks to Christopher Wolff)
# 01/11/2024 - V1.4 - Copy this script from https://gist.github.com/dougbtv/3d820a597347396a6e8d

# set PATH
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# save the current directory 
pushd .
 
# create a temporary directory and cd to it 
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT
cd $TMPDIR || exit 1
 
# dump the stream to a temporary file 
cat >> stream.org 
 
# get the boundary 
BOUNDARY=`grep "boundary=" stream.org | cut -d'"' -f 2` 
 
# cut the file into parts 
# stream.part - header before the boundary 
# stream.part1 - header after the bounday 
# stream.part2 - body of the message 
# stream.part3 - attachment in base64 (WAV file) 
# stream.part4 - footer of the message 
awk '/'$BOUNDARY'/{i++}{print > "stream.part"i}' stream.org 
 
# if mail is having no audio attachment (plain text) 
PLAINTEXT=`cat stream.part1 | grep 'plain'` 
if [ "$PLAINTEXT" != "" ] 
then 
 
  # prepare to send the original stream 
  cat stream.org > stream.new 
 
# else, if mail is having audio attachment 
else 
 
  # cut the attachment into parts 
  # stream.part3.head - header of attachment 
  # stream.part3.wav.base64 - wav file of attachment (encoded base64) 
  sed '7,$d' stream.part3 > stream.part3.wav.head 
  sed '1,6d' stream.part3 > stream.part3.wav.base64 
 
  # convert the base64 file to a wav file 
  dos2unix -o stream.part3.wav.base64 
  base64 -di stream.part3.wav.base64 > stream.part3.wav 
 
  # convert wav file to mp3 file
  # -b 24 is using CBR, giving better compatibility on smartphones (you can use -b 32 to increase quality)
  # -V 2 is using VBR, a good compromise between quality and size for voice audio files
  lame -m m -V 6 stream.part3.wav stream.part3.mp3
  # convert wav file to mp3 file
  #  ffmpeg -i stream.part3.wav -codec:a aac -ac 1 -b:a 48k -strict experimental stream.part3.m4a
  # convert back mp3 to base64 file 
  base64 stream.part3.mp3 > stream.part3.mp3.base64 
 
  # generate the new mp3 attachment header 
  # change Type: audio/x-wav to Type: audio/mpeg 
  # change name="msg----.wav" to name="msg----.mp3" 
  sed 's/x-wav/mpeg/g' stream.part3.wav.head | sed 's/.wav/.mp3/g' > stream.part3.mp3.head
 
  # generate first part of mail body, converting it to LF only 
  mv stream.part stream.new 
  cat stream.part1 >> stream.new 
  cat stream.part2 >> stream.new 
  cat stream.part3.mp3.head >> stream.new 
  dos2unix -o stream.new 
 
  # append base64 mp3 to mail body, keeping CRLF 
  unix2dos -o stream.part3.mp3.base64 
  cat stream.part3.mp3.base64 >> stream.new 
 
  # append end of mail body, converting it to LF only 
  echo "" >> stream.tmp 
  echo "" >> stream.tmp 
  cat stream.part4 >> stream.tmp 
  dos2unix -o stream.tmp 
  cat stream.tmp >> stream.new 
 
fi 
 
# send the mail thru sendmail 
cat stream.new | sendmail -t 
 
# go back to original directory 
popd
#!/usr/bin/bash

if ! command -v ffmpeg &> /dev/null
then
    echo "FFmpeg not found"
    exit
fi

if ! command -v MP4Box &> /dev/null
then
    echo "GPAC (MP4Box) not found (sudo apt install gpac)"
    exit
fi

DIR=$(mktemp -d)
cd $DIR
pwd

wget http://ftp.nluug.nl/pub/graphics/blender/demo/movies/Sintel.2010.1080p.mkv

# 4300k 1080p
ffmpeg -y -i Sintel.2010.1080p.mkv -c:v libx264 \
  -r 24 -x264opts 'keyint=48:min-keyint=48:no-scenecut' \
  -vf scale=-2:1080 -b:v 4300k -maxrate 4300k \
  -movflags faststart -bufsize 8600k \
  -profile:v main -preset ultrafast -an "video_intermed_4300k.mp4"
  
# 1050k 480p
ffmpeg -y -i Sintel.2010.1080p.mkv -c:v libx264 \
  -r 24 -x264opts 'keyint=48:min-keyint=48:no-scenecut' \
  -vf scale=-2:480 -b:v 1050k -maxrate 1050k \
  -movflags faststart -bufsize 8600k \
  -profile:v main -preset ultrafast -an "video_intermed_1050k.mp4"

# 235k 320p
ffmpeg -y -i Sintel.2010.1080p.mkv -c:v libx264 \
  -r 24 -x264opts 'keyint=48:min-keyint=48:no-scenecut' \
  -vf scale=-2:320 -b:v 235k -maxrate 235k \
  -movflags faststart -bufsize 8600k \
  -profile:v main -preset ultrafast -an "video_intermed_235k.mp4"

# Audio 1
ffmpeg -y -i Sintel.2010.1080p.mkv -map 0:1 -vn -c:a aac -b:a 128k \
  -ar 48000 -ac 2 "audio1.m4a"

# Audio 2, flac without voices
wget https://download.blender.org/durian/movies/sintel-m%2be-st.flac

ffmpeg -y -i sintel-m+e-st.flac -map 0:0 -vn -c:a aac -b:a 128k -ar 48000 -ac 2 audio2.m4a

wget https://durian.blender.org/wp-content/content/subtitles/sintel_en.srt
wget https://durian.blender.org/wp-content/content/subtitles/sintel_es.srt
wget https://durian.blender.org/wp-content/content/subtitles/sintel_de.srt

ffmpeg -y -i sintel_en.srt sintel_en.vtt
ffmpeg -y -i sintel_es.srt sintel_es.vtt
ffmpeg -y -i sintel_de.srt sintel_de.vtt

MP4Box -add sintel_en.vtt:lang=en subtitle_en.mp4
MP4Box -add sintel_es.vtt:lang=es subtitle_es.mp4
MP4Box -add sintel_de.vtt:lang=de subtitle_de.mp4

mkdir dash

MP4Box -dash 4000 -frag 4000 -rap \
  -segment-name 'segment_$RepresentationID$_' -fps 24 \
  video_intermed_235k.mp4#video:id=240p \
  video_intermed_1050k.mp4#video:id=480p \
  video_intermed_4300k.mp4#video:id=1080p \
  audio1.m4a#audio:id=English:role=main \
  audio2.m4a#audio:id=Dubbed:role=dub \
  subtitle_en.mp4:role=subtitle \
  subtitle_es.mp4:role=subtitle \
  subtitle_de.mp4:role=subtitle \
  -out dash/playlist.mpd



#! /bin/bash
rm *.json

echo "Demux"
curl -H 'Content-Type: application/json' \
     -d '{"src": {"uri": "s3://my-bucket/big_buck_bunny_1080p_h264.mov", "blocksize": 4096000}, "sink": {"uri": "s3://my-bucket/demuxed/%u.mov"}}' \
     -o demux.json \
     http://localhost:8080/function/demux2

echo "Split Video in 3 min chunks"
video_uri=$(cat demux.json | jq -r '.medias[] | select(.mediaType=="video/x-h264") | .uri')
video_pattern=$(echo $video_uri | sed -e 's/demuxed/splitted/' -e 's/.mov$/%d.mov/')

curl -H 'Content-Type: application/json' \
     -d "{\"src\": {\"uri\": \"${video_uri}\", \"blocksize\": 4096000}, 
          \"sink\": {\"uri\": \"${video_pattern}\"}, \"params\": {\"maxSizeTime\": 180000000000}}" \
     -o split.json \
     http://localhost:8080/function/split2


for bitrate in 512; do
	for chunk in $(cat split.json | jq -r '.medias[] | .uri'); do 
		output=$(echo -n $chunk | sed -e "s/splitted/encoded/" -e "s/.mov$/-${bitrate}.mov/")
		curl -H 'Content-Type: application/json' \
		     -d "{\"src\": {\"media\": {\"uri\": \"${chunk}\"}, \"blocksize\": 4096000}, 
			  \"sink\": {\"uri\": \"${output}\"}, 
			  \"params\": {
			  \"fragmentDuration\": 2000, 
			  \"key-int-max\": 25,
			  \"pass\": \"qual\",
			  \"quantizer\": 20,
			  \"tune\": \"zerolatency\",
			  \"bitrate\": ${bitrate}}}" \
		-o "encode-$(basename -s .mov ${output}).json" \
		http://localhost:8080/function/encode
	done
done


echo "Stitch Video chunks"
stitched_uri=$(echo $video_uri | sed -e 's/demuxed/stitched/')
curl -H 'Content-Type: application/json' \
	-d "{\"src\": {\"medias\": [$(cat encode-*-${bitrate}.json  | jq -c  .media | paste -sd, -)]}, 
	\"sink\": {\"uri\": \"${stitched_uri}\"}, \"params\": {\"fragmentDuration\": 2000}}" \
	-o stiched.json \
	http://localhost:8080/function/stitch2

echo "Fragment Audio"
audio_uri=$(cat demux.json | jq -r '.medias[] | select(.mediaType=="audio/mpeg") | .uri')
stitched_uri=$(echo $video_uri | sed -e 's/demuxed/fragmented/')
curl -H 'Content-Type: application/json' \
	-d "{\"src\": {\"medias\": [{\"uri\": \"${audio_uri}\" }]},  \"sink\": {\"uri\": \"${stitched_uri}\"}, \"params\": {\"fragmentDuration\": 2000}}" \
	-o fragmented.json \
	http://localhost:8080/function/stitch2


echo "Generate DASH/HLS Manifest"
curl -H 'Content-Type: application/json' \
     -d "{\"src\":{\"medias\":[ {\"uri\": \"$(cat fragmented.json | jq -r .media.uri)\"}, {\"uri\": \"$(cat stiched.json | jq -r .media.uri)\"}]}, \"sink\": {\"uri\": \"s3://my-bucket/bentoed/\"}}" \
     http://localhost:8080/function/bento4


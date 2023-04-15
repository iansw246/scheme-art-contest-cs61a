#!/bin/sh

# Copy the original contest.scm file into contest-top.scm and contest-bottom.scm
# Set the height-segments to 2, and set height-segment-index to 0 and 1 in contest-bottom.scm and contest-top.scm, respectively.
# Next, run this script. FInally, merge the image with command below

nice time python scheme contest-top.scm --pillow-turtle --turtle-save-path output-top > top.log &
nice time python scheme contest-bottom.scm --pillow-turtle --turtle-save-path output-bottom

# Merge image with image magick:
# magick composite output-bottom.png -compose Screen -gravity center output-top.png merge.png

# Kill background task when this script exits
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
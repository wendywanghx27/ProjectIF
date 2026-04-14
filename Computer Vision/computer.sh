# Pull images to computer (just use python?)

sudo apt install inotify-tools

# Should watch for latest image and allow script to run
inotifywait -m -e create --format '%f' "/pic_shared" | while read NEWFILE
do
    image_path = "pic_shared/$NEWFILE"
    # Run a python script here? (run sam3 on image file)
    
done
Below are instructions on how to upload data to flywheel. 

First make sure you have a Flywheel token: you can find this on your Profile page in the Flywheel website. 
It will be something like bair.flywheel.io:XXXXXXXXXXXX.
Replace the --token flag in the command below with your own token.

Use upload_to_flywheel.py to upload the data. You should have python 3.6 installed.

Input arguments:
1. the path to the folder from which the data will be uploaded
2. the name of the folder on Flywheel (you have to create this first if it doesn't exist yet)

Example commands (in terminal):

To upload the entire folder:
python3 upload_to_flywheel.py /Volumes/server/Projects/BAIR/Data/BIDS/visual/ nyu --token bair.flywheel.io:XXXXXXXXXXXX  --log debug

To upload a single subject:
python3 upload_to_flywheel.py /Volumes/server/Projects/BAIR/Data/BIDS/visual/ nyu --subject sub-som648 --token bair.flywheel.io:XXXXXXXXXXXX  --log debug

Note that in both cases, the participants.tsv file on Flywheel will be updated with whatever is in the upload folder (It will in included as an attachment to the project).

For questions, email Iris Groen (ig24@nyu.edu) or Gio Piantoni (gio@gpiantoni.com).
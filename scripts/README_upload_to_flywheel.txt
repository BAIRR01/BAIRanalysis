Instructions on how to upload data to flywheel using the terminal.

Before uploading, you have to: 
* Download and install Flywheel's CLI (command line interface) and SDK (software development kit). Please follow instructions on the Flywheel website on how to set this up.
* Generate a Flywheel token: you can find this on your Profile page in the Flywheel website. It will be something like bair.flywheel.io:XXXXXXXXXXXX. Replace the --token flag in the command below with your own token.
* Have python 3.6 installed.

Use upload_to_flywheel.py to upload the data. The script is located on GitHub in the BairAnalysis repository https://github.com/BAIRR01/BAIRanalysis, inside 'scripts'.

Input arguments:
1. the path to the folder from which the data will be uploaded
2. the name of the folder on Flywheel (you have to create this first if it doesn't exist yet)

Example commands (in terminal):

To upload the entire folder:

python3 upload_to_flywheel.py /Volumes/server/Projects/BAIR/Data/BIDS/visual/ nyu --token bair.flywheel.io:XXXXXXXXXXXX  --log debug

To upload a single subject:

python3 upload_to_flywheel.py /Volumes/server/Projects/BAIR/Data/BIDS/visual/ nyu --subject sub-som648 --token bair.flywheel.io:XXXXXXXXXXXX  --log debug

Note that in both cases, the participants.tsv file on Flywheel will be updated with whatever is in the upload folder (It will be included as an attachment to the project).

For questions, email Iris Groen (iris.groen@nyu.edu) or Gio Piantoni (gio@gpiantoni.com).
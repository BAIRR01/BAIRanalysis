function bidsCreateBAIRSessionJsonAndTSV(projectDir, subject)

% This function writes a session.json and session.tsv file for a specific
% subject in the BAIR project based on the existing session folders in the
% subject folder. Besides the session name, the tsv file has columns
% resection, implantation and breathing challenge (see session.json for
% more info). Note that these columns default to 'n/a' and should be
% updated manually with the subject-specific information.
%
% Example
%   projectDir = '/Volumes/server/Projects/BAIR/Data/BIDS/motor';
%   subject = 'som705';
%   bidsCreateBAIRSessionJsonAndTSV(projectDir, subject)

% Generate session json file
json_options.indent = '    '; % this just makes the json file look prettier 

sessions_json.session_id.Description = "Unique session identifier";
sessions_json.resection.Description = "Resection";
sessions_json.resection.Levels.pre = "Before resection";
sessions_json.resection.Levels.post = "After resection";
sessions_json.implantation.Description = "Implantation";
sessions_json.implantation.Levels.yes = "Implantation";
sessions_json.implantation.Levels.no = "No implantation";
sessions_json.breathing_challenge.Description = "Breathing Challenge";
sessions_json.breathing_challenge.Levels.yes = "With breathing challenge";
sessions_json.breathing_challenge.Levels.no = "Without breathing challenge";

inDir = fullfile(projectDir, sprintf('sub-%s', subject));

 % Write sessions.json
sessions_json_fname = fullfile(inDir, sprintf('sub-%s_sessions.json', subject));    
jsonwrite(sessions_json_fname,sessions_json,json_options);

% Get the session names
D = dir(inDir);
D = D(contains({D.name}, 'ses') & [D.isdir] == 1);
nSessions = length(D);

session_id = {D.name}';
resection = repmat({'n/a'}, [nSessions 1]);
implantation = repmat({'n/a'}, [nSessions 1]);
breathing_challenge = repmat({'n/a'}, [nSessions 1]);

sessions_table = table(session_id, resection, implantation, breathing_challenge);

 % Write events.tsv file: 
sessions_tsv_fname = fullfile(inDir, sprintf('sub-%s_sessions.tsv', subject));
writetable(sessions_table, sessions_tsv_fname, 'FileType','text', 'Delimiter', '\t');
    
end
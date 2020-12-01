function bidsGetEvents(projectDir, subject, session, tasks, dryRun)
% Events files as written by CBI do not contain actual events. Get the
% events files from the stimulus outputfiles located in the 'stimuli'
% folder in projectDir and write them to the BIDS data folder.
%
% bidsGetEvents(projectDir, subject, [session] ,[tasks], [dryRun])
%
% Example 1:
%
%     projectDir     = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
%     subject        = 'wlsubj051';
%     session        = 'nyu3t01';
%     tasks          = [];
%     dryRun         = 1;
%
%    bidsGetEvents(projectDir, subject, session, tasks, dryRun)
%
% When dryRun = 1, no files will be written, only an list of the found
% files will be outputted.
%
% Note that a session input argument is needed if a subject has multiple
% sessions (see bidsSpecifyEPIs).
%
% IG, 2020
%

if ~exist('session', 'var'), session = []; end
if ~exist('tasks', 'var'), tasks = []; end
if ~exist('dryRun', 'var'), dryRun = 0; end

if dryRun
	fprintf('[%s] Dry run - not writing any files... \n', mfilename); 
end

% Set up paths
[session, tasks, runnums] = bidsSpecifyEPIs(projectDir, subject, session, tasks);

dataPath = fullfile(projectDir, sprintf('sub-%s',subject), sprintf('ses-%s',session), 'func');
stimPath = fullfile(projectDir, 'stimuli');

% Check if we have event files for each run
D = dir(fullfile(dataPath, '*events.tsv'));
assert(length(D) == length([runnums{:}]));

acq_label = bidsGet(D(1).name, 'acq');
d = 0;

% Find the corresponding stimulus mat file in the stimuli folder, and overwrite
% the existing events file with the tsv file from the stimulus mat.
for ii = 1:length(tasks)
    for jj = 1:length (runnums{ii})
        d = d+1;
        
        stimPrefix = sprintf('sub-%s_ses-%s_task-%s_run-%d.mat',...
            subject, session, tasks{ii},runnums{ii}(jj));
        
        % The stimulus files are not zero-padded, so this is not necessary
        %stimPrefixZeroPad = sprintf('sub-%s_ses-%s_task-%s*run-%02d.mat',...
        %    subject, session, tasks{ii},runnums{ii}(jj));
        
        S = dir(fullfile(stimPath, stimPrefix));
        % Check if the stimulus file exists, if not skip
        if isempty(S)
            warning('[%s] No stimulus file found for subject %s, session %s, task %s, run %d! Skipping \n', ...
                mfilename, subject, session, tasks{ii}, jj); 
        % Check if there are multiple stimulus files, if so skip
        elseif length(S)> 1
             warning('[%s] Multiple stimulus file found for subject %s, session %s, task %s, run %d! Skipping \n', ...
                mfilename, subject, session, tasks{ii}, jj); 
        else
            % List the found stimulus file
            fprintf('[%s] Found the following stimfile for subject %s, session %s, task %s, run %d: \n', ...
                    mfilename, subject, session, tasks{ii}, jj); 
            fprintf('[%s] %s \n', mfilename, fullfile(stimPath,S.name)); 
            % Overwrite events.tsv in data path with the one in the found stimulus file
            if ~dryRun
                fprintf('[%s] Loading stimfile... \n', mfilename); 
                logFile = load(fullfile(stimPath,S.name));
                if ~isfield(logFile.stimulus, 'tsv')
                    warning('[%s] No tsv field found in stimfile! Skipping \n', mfilename); 
                else             
                    tsvToWrite = logFile.stimulus.tsv;
                    writeName = sprintf('sub-%s_ses-%s_task-%s_acq-%s_run-%02d_events.tsv', ...
                        subject, session, tasks{ii}, acq_label, jj);
                    if ~isequal(writeName, D(d).name)
                        fprintf('[%s] To be written name does not match existing name! Skipping \n', mfilename); 
                    else
                        fprintf('[%s] Writing tsv to %s... \n', mfilename, fullfile(dataPath, writeName)); 
                        writetable(tsvToWrite, fullfile(dataPath, writeName),'FileType','text','Delimiter','\t');
                    end
                end 
            end
        end
    end
end
fprintf('[%s] Done! \n', mfilename);
end
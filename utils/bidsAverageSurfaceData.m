function bidsAverageSurfaceData (projectDir,subject, dataFolder, outputFolder,session, tasks, runnums)
% bidsAverageSurfaceData (projectDir,subject, dataFolder, outputFolder,[session], [tasks], [runnums])
%
% Computes (and writes) Averages  all runs by task for each hemisphere
% (assumes data is in .mgz format)
%
% Code assumes every other run uses the same stimulus order/stim file to
%  average over and will skip tasks that have 2 or less runs, i,e,:
%
%     temporalpattern_run-1 = temporalpattern_1.mat
%     temporalpattern_run-2 = temporalpattern_2.mat
%     temporalpattern_run-3 = temporalpattern_1.mat
%     temporalpattern_run-4 = temporalpattern_2.mat
%
% Example 1 :
%
%   subject      = 'wlsubj062';
%   projectDir   = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
%   dataFolder   = 'preprocessedUpsampledToSurface';
%   outputFolder = 'preprocessedUpsampledAveragedToSurface';
%
%   bidsAverageSurfaceData (projectDir,subject, dataFolder, outputFolder)
%
% Example 2 :
%
%   subject      = 'wlsubj062';
%   session      = 'nyu3t01';
%   projectDir   = '/Volumes/server/Projects/BAIR/Data/BIDS/visual';
%   dataFolder   = 'preprocessedUpsampledToSurface';
%   outputFolder = 'preprocessedRoundedTRToSurfaceAveraged_4runs';
%   tasks        = {'temporalpattern'};
%   runnums      = {1:4}; %for the sake of comparison to 12 runs
%
%   bidsAverageSurfaceData (projectDir,subject, dataFolder, outputFolder, session, tasks, runnums)

[session, tasks, runnums] = bidsSpecifyEPIs(projectDir, subject, session, tasks, runnums);

% Set paths for getting the data and saving the data
dataPath = fullfile (projectDir,'derivatives', dataFolder,...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));
saveDir = fullfile (projectDir,'derivatives', outputFolder,...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));
if ~exist(saveDir, 'dir'); mkdir(saveDir); end

for tt = 1:length(tasks)
    if ~(max(runnums{tt})/2 > 1)
        % skip this task is there aren't at least 3 runs
        fprintf(['Task-%s contains too few runs(%d), '...
            'skipping... \n'],tasks{tt},max(runnums{tt}));
    else
        for ii = 1:length(runnums{tt})
            % find all the Left hemisphere file names we're interested in
            fname(ii).l = sprintf('lh.sub-%s_ses-%s_task-%s*run-%d_preproc.mgz',...
                subject, session,tasks{tt}, ii);
            % find all the right hemisphere file names we're interested in
            fname(ii).r = sprintf('rh.sub-%s_ses-%s_task-%s*run-%d_preproc.mgz',...
                subject, session,tasks{tt}, ii);
        end
        
        % specify the scan number to start counting through the data
        % (i.e. Even(2) or Odd(1) scans)
        startNums = [1 , 2];
        for ll = 1:length(startNums)
            fprintf('Loading Data')
            count = 1;
            % check there are at least 2 odd or even scans to average
            if length(startNums(ll):2:length(runnums{tt})) == 1
                fprintf('Too few even or odd runs(%d)',length(startNums(ll):2:length(runnums{tt})))
            else
                % now loop through the even or odd run numbers
                for n = startNums(ll):2:length(runnums{tt})
                    % get the left and right hemi data
                    fprintf('.')
                    tmpLeft = MRIread(fullfile(dataPath, fname(n).l));
                    dataLeft(:,:,:,:,count) = tmpLeft.vol;
                    tmpRight = MRIread(fullfile(dataPath, fname(n).r));
                    dataRight(:,:,:,:,count) = tmpRight.vol;
                    count = count+1;
                end
                
                % average all the runs and write the left hemisphere files
                fprintf('\n Averaging left hemisphere - Run - %d...',startNums(ll))
                tmpLeft.vol = mean(dataLeft, 5);
                fprintf('\n Writing...')
                MRIwrite(tmpLeft, fullfile(saveDir, ...
                    sprintf('lh.sub-%s_ses-%s_task-%s_run-%d_preproc.mgz',subject, ...
                    session,tasks{tt}, startNums(ll))));
                
                % average all the runs and write the right hemisphere files
                fprintf('\n Averaging right hemisphere - Run - %d... ', startNums(ll))
                tmpRight.vol = mean(dataRight, 5);
                fprintf('\n Writing...')
                MRIwrite(tmpRight, fullfile(saveDir, ...
                    sprintf('rh.sub-%s_ses-%s_task-%s_run-%d_preproc.mgz',subject,...
                    session,tasks{tt}, startNums(ll))));
                
                % clear variables to lessen memory load
                clear tmpLeft tmpRight dataLeft dataRight
            end
        end
    end
end


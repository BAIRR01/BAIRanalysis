% for parsing continuous dataglove runs into individual task runs

dataDir = '/Volumes/server/Projects/BAIR/Data/BIDS/motor/stimuli';
subject = 'wlsubj100';
session = 'nyu3t01';
tasks   =  {'boldhand', 'fingermappingright', 'gestures', 'boldsat1', 'boldsat2' , 'boldsat3' , 'boldsat4' };
saveFile = true;

saveDir = fullfile(dataDir, 'correctedMatfiles');
if ~exist(saveDir, 'dir'), mkdir(saveDir), end

file = dir(fullfile(dataDir , sprintf('sub-%s_ses-%s_DataGlove_*', subject, session)));
datafile = importdata(fullfile(dataDir , file.name));

datagloveRaw = datafile.data;
% time in HH_MM_ss_FFF format which is what we will search for
datagloveSampleTimes = datafile.textdata;

for ii = 1: length(tasks)
    %load in the stimulus file
     load (fullfile (dataDir, sprintf('sub-%s_ses-%s_task-%s_run-1.mat', ...
        subject, session, tasks{ii})));
   
    %figure out when the experiment ended
    experimentEnd = params.experimentDateandTime;
    % split the date and time to make it easier to search by
    dateAndTime = strsplit(experimentEnd, 'T');
    time = regexp(dateAndTime{2}, '\w{1,2}', 'match');
    
    % figure out the moment when the experiment ends
    endIdx = find(contains(datagloveSampleTimes, sprintf('%s_%s_%s', time{1}, time{2}, time{3})));
    % we don't know exactly when it happened, so assume the middle of the range
    num = round(length(endIdx)/2); 
        
    % use that index and place the values into the stim file
    response.glove = datagloveRaw((endIdx(num)+0)-length(stimulus.seq):(endIdx(num)+0),:); %+0 for manually adjusting time
    response.datagloveSampleTime = datagloveSampleTimes(endIdx(num)-length(stimulus.seq):endIdx(num),:);
    
    %save it
    save (fullfile(saveDir, fname), 'params', 'pc', ... %'PTBTheWindowPtr'
    'pth', 'fname' ,'quitProg', 'rc', 'response', 'stimulus', 'time0', 'timeFromT0', 'timing');
    
    % plot to make sure everything looks okay
    figure
    plot(diff(response.glove))
    if contains (tasks{ii},{'gestures','fingermappingright'})
        hold on, plot(stimulus.seq*10)
    else
        hold on, plot(stimulus.fixSeq*10)
    end
    
    if saveFile
        print(fullfile(saveDir, sprintf('sub-%s_ses-%s_task-%s_run-1', ...
            subject, session, tasks{ii})), '-dpng')
    end
     
end

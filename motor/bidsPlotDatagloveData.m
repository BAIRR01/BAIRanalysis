function bidsPlotDatagloveData (projectDir, subject, session, tasks, useBlockMeans, saveFigs)
% plotDatagloveData (projectDir, subject, session, tasks, useBlockMeans, saveFigs)
%
% Uses stimulus files to load in dataglove responses to plot them after
% normalizing in one of two ways: 
%         1. Using the mean of each rest period to normalize each corresponding block
%         2. Using the overall mean of all rest periods to normalize all positions 
%
%    Note: Only the open hand position is used to normalize fingermapping
%    data if blocked means are not used
%
% example:
%   projectDir    = '/Volumes/server/Projects/BAIR/Data/BIDS/motor/';
%   subject       = 'ny705';
%   session       = 'nyumeg01';
%   tasks         = {'boldhand', 'fingermappingright', 'gestures', 'boldsat1', 'boldsat2' , 'boldsat3' , 'boldsat4' };
%   useBlockMeans = 'true'; 
%   saveFigs      = 'true';
%
% plotDatagloveData (projectDir, subject, session, tasks, useBlockMeans, saveFigs)


fingerOrder = {'thumb', 'index', 'middle', 'ring', 'little'};
for ii = 1: length(tasks)
    %load in the stimulus file
    load (fullfile (projectDir, 'stimuli' , sprintf('sub-%s_ses-%s_task-%s_run-1.mat', ...
        subject, session, tasks{ii})), 'stimulus', 'response');
    
    % find the values we need
    eventCategories       = stimulus.categories;
    rawGloveValues        = response.glove;
    onsets                = stimulus.onsets;
    % initialize some variables
    adjustedGloveValues   = zeros (size(rawGloveValues));
    gloveBaselines        = zeros(length(onsets),5);
    
    switch tasks{ii}
        case {'gestures' ,'boldhand' , 'boldsat1', 'boldsat2', 'boldsat3', 'boldsat4'}
            % Set some task specific event information
            if contains(tasks{ii},'gestures')
                events      = stimulus.seq;
                restNums    = max(events); % the blank is the highest number here
                makeSubplot = true;
            elseif contains(tasks{ii},{'boldhand' , 'boldsat'})
                events      = stimulus.fixSeq;
                eventNums   = unique(events);
                restNums    = eventNums(contains(eventCategories,'rest','IgnoreCase',true ));
                makeSubplot = false;
            end
            
            % Find the periods when the hand is relaxed and moving
            moveEndIdx = find(diff(events == restNums) == 1);
            restEndIdx = find(diff(events == restNums) == -1);
            
            % average the rest periods and subtract it from the raw values for that timeframe
            for jj = 1:length(restEndIdx)
                if jj == 1
                    gloveBaselines(jj,:) = mean(rawGloveValues(1:restEndIdx(jj),:),1);
                    adjustedGloveValues(1:moveEndIdx(jj),:) = rawGloveValues(1:moveEndIdx(jj),:) - gloveBaselines(jj,:);
                else
                    gloveBaselines(jj,:) = mean(rawGloveValues(moveEndIdx(jj-1):restEndIdx(jj),:),1);
                    
                    adjustedGloveValues(moveEndIdx(jj-1):moveEndIdx(jj),:) = ...
                        rawGloveValues(moveEndIdx(jj-1):moveEndIdx(jj),:) - gloveBaselines(jj,:);
                end
            end
            if ~useBlockMeans
                meanBaselines = mean(gloveBaselines, 1);
                adjustedGloveValues = rawGloveValues - meanBaselines;
            end
            if makeSubplot
                letters = eventCategories(events(restEndIdx(:)+1));
                % Note: refers to fingers that close during gesture
                fingerNumbers = {'1,3,4,5', '1,2', '1,4,5', '2,3,4'};
                
                % make a plot with subplots of each finger
                figure('Name',sprintf('sub-%s_ses-%s_Gestures',subject, session) );
                for ff = 1:5
                    fingerIdx =  contains ( fingerNumbers, string(ff));
                    theseLetters = contains (letters, eventCategories(fingerIdx));
                    otherLetters = ~theseLetters;
                    subplot(5,1, ff)
                    plot (adjustedGloveValues(:,ff)), hold on
                    plot ([onsets(theseLetters)' onsets(theseLetters)']*30,  [-300 300], 'k--*')
                    plot ([onsets(otherLetters)' onsets(otherLetters)']*30,  [-300 300], 'r--')
                    ylabel(fingerOrder(ff))
                    xticks (onsets'*30)
                    xticklabels([])
                end
                xticks (onsets'*30)
                xticklabels(letters)
                
                if saveFigs
                    print(fullfile(projectDir,'stimuli', 'summaryFigures', sprintf('sub-%s_ses-%s_task-%s_Subplots', ...
                        subject, session, tasks{ii})), '-dpng')
                end
            end
            
        case {'fingermappingright' , 'fingermappingleft'}
            % the order is the same for both MEG, ECoG and fMRI
            allMovements      = stimulus.tsv.trial_name;
            events            = stimulus.seq;
            eventNums         = stimulus.tsv.stim_file_index;
                                   
            % we want to use two conditions as baselines so find when this happens
            restNums        = unique(eventNums(contains(allMovements, {'open palm', 'closed palm'})));
            opnEndIdx       = find (diff(events == restNums(1)) == -1); % doesn't include the last one
            clsdBlockEndIdx = find (diff(events == restNums(1)) == 1);
            clsdEndIdx      = find (diff(events == restNums(2)) == -1);
            opnBlockEndIdx  = find (diff(events == restNums(2)) == 1);
            
            % Initialize some variables
            gloveBaselinesO = zeros(length(opnEndIdx),5);  % open
            gloveBaselinesC = zeros(length(clsdEndIdx),5); % closed
            
            for  jj = 1:length(opnEndIdx)
                if jj == 1
                    gloveBaselinesO(jj,:) = mean(rawGloveValues(1:opnEndIdx(jj),:),1);
                    gloveBaselinesC(jj,:) = mean(rawGloveValues(opnBlockEndIdx(jj):clsdEndIdx(jj),:),1);
                    
                    adjustedGloveValues(1:opnBlockEndIdx(jj),:) = rawGloveValues(1:opnBlockEndIdx(jj),:)-gloveBaselinesO(jj,:);
                    adjustedGloveValues(opnBlockEndIdx(jj):clsdBlockEndIdx(jj),:) = ...
                        rawGloveValues (opnBlockEndIdx(jj):clsdBlockEndIdx(jj),:) - gloveBaselinesC(jj,:);
                    
                else
                    gloveBaselinesO(jj,:) = mean(rawGloveValues(clsdBlockEndIdx(jj-1):opnEndIdx(jj),:),1);
                    gloveBaselinesC(jj,:) = mean(rawGloveValues(opnBlockEndIdx(jj):clsdEndIdx(jj),:),1);
                    
                    adjustedGloveValues(clsdBlockEndIdx(jj-1):opnBlockEndIdx(jj),:) = ...
                        rawGloveValues(clsdBlockEndIdx(jj-1):opnBlockEndIdx(jj),:)-gloveBaselinesO(jj,:);
                    adjustedGloveValues (opnBlockEndIdx(jj):clsdBlockEndIdx(jj),:)  = ...
                        rawGloveValues (opnBlockEndIdx(jj):clsdBlockEndIdx(jj),:) - gloveBaselinesC(jj,:);
                end
            end
            % fill in the values we missed
            adjustedGloveValues(clsdBlockEndIdx(end):end,:)= rawGloveValues(clsdBlockEndIdx(end):end,:) - gloveBaselinesO(end,:);
            
            if ~useBlockMeans
                % meanBaselines = mean(cat(1,gloveBaselinesO,gloveBaselinesC) , 1);
                meanBaselines = mean(gloveBaselinesO , 1);
                adjustedGloveValues = rawGloveValues - meanBaselines;
            end
            
            % make a plot with subplots of each finger
            figure('Name',sprintf('sub-%s_ses-%s_Fingermapping',subject, session) );
            for ff = 1:5
                subplot(5,1, ff)
                plot (adjustedGloveValues(:,ff)), hold on
                ylabel(fingerOrder(ff))
                % plot lines for individual fingers and check for old names
                fingerIdx = contains( allMovements, fingerOrder(ff));
                if sum(fingerIdx) == 0
                    fingerIdx = contains(allMovements, fingerOrderOld(ff));   
                end
                if sum(fingerIdx) ~=0
                    plot ([onsets(fingerIdx)' onsets(fingerIdx)']*30,  [-300 300], 'k--*')
                end 
                xticks (onsets(fingerIdx)'*30)
                xticklabels(onsets(fingerIdx)')  
            end 
            
            xlabel ('Time(s)')
            %sgtitle(sprintf('%s - %s - %s', subject, session, tasks{ii})) % matlab 2018b
            if saveFigs
                print(fullfile(projectDir,'stimuli', 'summaryFigures', sprintf('sub-%s_ses-%s_task-%s_Subplots', ...
                    subject, session, tasks{ii})), '-dpng')
            end
    end
    
    % now plot everything
    figure('Name',sprintf('sub-%s_ses-%s',subject, session))
    plot (adjustedGloveValues), hold on
    plot([onsets' onsets']*30,  [-300 300], 'k--')
    title (sprintf('sub-%s ses-%s task-%s datagloveCorrected', subject, session, tasks{ii}))
    xlabel('time')
    ylabel('displacement')
    
    if saveFigs
        print(fullfile(projectDir,'stimuli', 'summaryFigures', sprintf('sub-%s_ses-%s_task-%s_datagloveCorrected', ...
            subject, session, tasks{ii})), '-dpng')
    end
    
    clear normalizedDatagloveValues datagloveValuesRaw stimulus response
end

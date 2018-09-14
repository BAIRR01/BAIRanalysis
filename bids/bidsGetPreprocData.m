function[data, info] = bidsGetPreprocData(dataPath, tasks, runnums)
%
% Inputs
%   dataPath:   path to folder containing preprocessed data
%   tasks:      BIDS tasks, in cell array
%   runnums:    cell array of runnumbers, equal in length to tasks
%
% Output
%   data:       the time-series data for each run with dimensions 
%                X x Y x Z x time 
%   info:       nifti header for each run

numruns = sum(cellfun(@numel, runnums));

data = cell(1, numruns);
info = cell(1, numruns);

fprintf('Loading data')
scan = 1;
for ii = 1:length(tasks)
    for jj = 1:length(runnums{ii})
        fprintf('.')
        fnamePrefix  = sprintf('/*_task-%s_run-%d_preproc.nii*',tasks{ii},runnums{ii}(jj));
        fname         = dir([dataPath fnamePrefix]);
        assert(~isempty(fname));
        
        data{scan}    = niftiread(fullfile (dataPath, fname.name));
        info{scan}    = niftiinfo(fullfile (dataPath, fname.name));

        scan          = scan+1;
    end
end
fprintf('\n')
end
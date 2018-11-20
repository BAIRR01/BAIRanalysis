function [data, info] = bidsGetPreprocData(dataPath, tasks, runnums, usePreproc)
%
% Inputs
%   dataPath:   path to folder containing preprocessed data
%   tasks:      BIDS tasks, in cell array
%   runnums:    cell array of runnumbers, equal in length to tasks
%   usePreproc: boolean: if true, use preprocessed data from derivatives
%                       folder, else use data from func folder
%                       default: true
%
% Output
%   data:       the time-series data for each run with dimensions
%                X x Y x Z x time
%   info:       nifti header for each run

if ~exist('usePreproc', 'var') || isempty(usePreproc)
    usePreproc = true;
end

numruns = sum(cellfun(@numel, runnums));

data = cell(1, numruns);
info = cell(1, numruns);

fprintf('Loading data')
scan = 1;
for ii = 1:length(tasks)
    for jj = 1:length(runnums{ii})
        fprintf('.')
        
        if usePreproc
            fnamePrefix  = sprintf('*_task-%s*run-*%d_preproc*',...
                tasks{ii},runnums{ii}(jj));
        else
            fnamePrefix  = sprintf('*_task-%s*run-*%d_bold*',...
                tasks{ii},runnums{ii}(jj));
        end
        
        fname         = dir(fullfile(dataPath, fnamePrefix));
        assert(~isempty(fname));
        
        if length(fname) == 1  || ...
                length(fname) > 1 && length(unique ({fname.name})) > 1
            for ll = 1:length(fname)
                [~, ~, ext] = fileparts(fname(ll).name);
                switch ext
                    case {'.nii' '.gz'}
                        data{scan}    = niftiread(fullfile (dataPath, fname(ll).name));
                        info{scan}    = niftiinfo(fullfile (dataPath, fname(ll).name));
                    case '.mgz'
                        mgz           = MRIread(fullfile (dataPath, fname(ll).name));
                        data{scan}    = mgz.vol;
                        info{scan}    = rmfield(mgz, 'vol');
                    otherwise
                        error('Unrecognized file format %s', fname)
                end
                scan          = scan+1;
            end
        elseif length(fname) > 1 && length(unique ({fname.name})) == 1
            error ('More than one file found using BIDS prefix: %s',fnamePrefix) 
        end
    end
    fprintf('\n')
end
function startup
% add to matlab path of subdirs of current dir
% and launch spm (spm8 must be in the path)

persistent isinit;

if isempty(isinit)

    p = fileparts(mfilename('fullpath'));
    addpath(genpath(p),'-BEGIN');
    fprintf('SPM8 scripts are installed in %s.\n',p);

    try
        spm('defaults', 'FMRI'); % should check that is it spm8
    catch
        error('The script "spm" cannot be found in your Matlab path.');
    end
    fprintf('SPM8 is installed in %s.\n',spm('Dir'));
    
    %- Don't perform initialization again
    %-------------------------------------------------------
    isinit = 1;
end

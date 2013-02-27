%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generation of first level analysis batches
% 
% Time-stamp: <2013-02-27 09:58 christophe@pallier.org>

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% experiment-specific parameters

spm_path = '/i2bm/local/spm8';
%spm_path = '/home/pallier/Programs/spm/spm8';

root = get_rootdir();
subjects_dir = fullfile(root, 'Subjects')

% list the subjects directory in the variable "subjects"
[subjects] = textread(fullfile(subjects_dir, 'dirs.txt'),'%s');

fmridir =  'fMRI/acquisition1' ; % path of fMRI data (4D nifti) within subject directory
output_dir =  'analyses/hrf' ; % path where the SPM.mat will be created, within each subjects' dir
suffix = '_hrf'; 

TR = 2.4;


% see below if you want to modify the basis functions

% End of configuration section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% addpath(spm_path); % comment to run in compiled spm8
spm('defaults', 'FMRI');
spm_jobman('initcfg');


for s = 1:length(subjects)
     
    rootdir = fullfile(root, subjects{s});

    funcdir = spm_select('CPath','fMRI',rootdir);
    %funcfiles = cellstr(spm_select('List',funcdir, '^swn.*.nii$'));
    funcfiles = cellstr(spm_select('List',funcdir, '^sw.*.nii$'));

    nrun = size(funcfiles,1);
    clear matlabbatch

    matlabbatch{1}.spm.stats.fmri_spec.dir = cellstr(spm_select('CPath', output_dir, rootdir));
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
%%

    for n=1:nrun
      cfile = funcfiles{n};
      ff = spm_select('ExtFPList',funcdir, cfile, Inf);
      basename = cfile(3:length(cfile)-4);
      rpfile = sprintf('rp_%s.txt', basename);
      matfile_name = sprintf('%s%s.mat', basename, suffix)
      matfile = subdir(fullfile(root,matfile_name))
      matlabbatch{1}.spm.stats.fmri_spec.sess(n).scans = cellstr(ff);
      matlabbatch{1}.spm.stats.fmri_spec.sess(n).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});
      matlabbatch{1}.spm.stats.fmri_spec.sess(n).multi = { matfile.name };
      matlabbatch{1}.spm.stats.fmri_spec.sess(n).regress = struct('name', {}, 'val', {});
      matlabbatch{1}.spm.stats.fmri_spec.sess(n).multi_reg = cellstr(spm_select('CPath',rpfile,funcdir));
      matlabbatch{1}.spm.stats.fmri_spec.sess(n).hpf = 128;
    end

    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

    % bases functions [TODO: improve this part]
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
% Hrf simple
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [1 0];
% FIR:
%    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.length = 14.4;
%    matlabbatch{1}.spm.stats.fmri_spec.bases.fir.order = 12;

    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep;
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tname = 'Select SPM.mat';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).name = 'filter';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).value = 'mat';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).name = 'strtype';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).value = 'e';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).sname = 'fMRI model specification: SPM.mat File';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_output = substruct('.','spmmat');
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    batchname = fullfile(batch_dir, 'level1_', [ subjects{s} suffix '.mat' ]) 
    save(batchname,'matlabbatch')

end

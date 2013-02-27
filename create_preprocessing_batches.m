% Create spm job files for preprocessing single subject's fMRI data
%
% This script (and preprocess_job) contains 
% Christophe Pallier <christophe@pallier.org>
% Time-stamp: <2013-02-27 09:59 christophe@pallier.org>
%
% Usage: 
% This script must be launched from a directory containing a series of directories, one per subject. Each subject's directory must contain two subdirs 'anat' and 'fMRI' containing the relevant images files.
% The list of files to process must be in a file called 'dirs.txt'
% The ouput is a series of SPM job files (one .mat per subject), ready to be executed.
% They can be run either within matlab:
%     spm_jobman('serial', jobs, '', inputs{:});
% Or on the unix shell:
%     for f in preprocess*.mat; do (spm8 run $f &); done
% In the last case, you can benefit from multicore processors!
%
% BEWARE this only works on clean subject directories containing
% only the non processed anatomy and fMRI data. You may want to run the shell script
% 'clean_files.sh' to remove unnecessary files (and perhaps useful ones too :-(

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% experiment-specific parameters

spm_path = '/i2bm/local/spm8';

root = get_rootdir();
subjectsdir = fullfile(root, 'Subjects');
[subjects] = textread(fullfile(subjects, 'dirs.txt'), '%s')

funcdir = 'fMRI/acquisition1'
anatdir = 't1mri/acquisition1'

TR = 2.4;
nslices = 40;
TA = 2.34; % TR * (1-1/80)
slice_order = 1:nslices;
refslice = 1;
voxel_size = [3 3 3];
smoothing_kernel = [5 5 5];

% End of configuration section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%addpath(spm_path); % comment to run in compiled spm8
spm('defaults', 'FMRI');
spm_jobman('initcfg');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create one job per subject

nsubj = length(subjects) ;

jobs = cell(nsubj,1);
inputs = cell(0, nsubj);

for csubj = 1:nsubj
    subjdir = spm_select('CPath', subjects{csubj}, subjectsdir)
    
    adir =  spm_select('CPath', anatdir, subjdir);
    anatfile = spm_select('FPList', adir, '^anat.*\.nii')
    if isequal(anatfile,  '')
        warning(sprintf('No anat file found for %s', ...
                        subjects{csubj}))
        return
    end
    
    fdir =  spm_select('CPath', funcdir, subjdir);
    ffiles = spm_select('List', fdir, '^.*\.nii')
    nrun = size(ffiles,1);
    if nrun == 0
        warning(sprintf('No functional file found for %s', ...
                        subjects{csubj}))
        return
    end
    funcfiles = cell(nrun, 1);
    cffiles = cellstr(ffiles);
    for i = 1:nrun
        funcfiles{i} = cellstr(spm_select('ExtFPList', fdir, cffiles{i}, Inf));
    end

    clear matlabbatch

%%%%%%%%%%%%%%%%%
% preprocess_job 

display 'Creating preprocessing job'

nruns = length(funcfiles);

stage = 0;

% Slice timing
stage = stage + 1;
stage_slicetiming = stage;
matlabbatch{stage}.spm.temporal.st.scans = { funcfiles{:} };
matlabbatch{stage}.spm.temporal.st.nslices = nslices;
matlabbatch{stage}.spm.temporal.st.tr = TR;
matlabbatch{stage}.spm.temporal.st.ta = TA;
matlabbatch{stage}.spm.temporal.st.so = slice_order;
matlabbatch{stage}.spm.temporal.st.refslice = refslice;
matlabbatch{stage}.spm.temporal.st.prefix = 'a';


% Realigment of functional images 
stage = stage + 1;
stage_realign = stage;
for crn = 1:nruns
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1) = cfg_dep;
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).tname = 'Session';
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).tgt_spec{1}(1).name = 'filter';
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).tgt_spec{1}(1).value = 'image';
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).tgt_spec{1}(2).name = 'strtype';
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).tgt_spec{1}(2).value = 'e';
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).sname = sprintf('Slice Timing: Slice Timing Corr. Images (Sess %d)', crn);
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).src_exbranch = substruct('.','val', '{}',{stage_slicetiming}, '.','val', '{}',{1}, '.','val', '{}',{1});
    matlabbatch{stage}.spm.spatial.realign.estwrite.data{crn}(1).src_output = substruct('()',{crn}, '.','files');
end
matlabbatch{stage}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{stage}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{stage}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
matlabbatch{stage}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
matlabbatch{stage}.spm.spatial.realign.estwrite.eoptions.interp = 2;
matlabbatch{stage}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{stage}.spm.spatial.realign.estwrite.eoptions.weight = '';
matlabbatch{stage}.spm.spatial.realign.estwrite.roptions.which = [2 1];
matlabbatch{stage}.spm.spatial.realign.estwrite.roptions.interp = 4;
matlabbatch{stage}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{stage}.spm.spatial.realign.estwrite.roptions.mask = 1;
matlabbatch{stage}.spm.spatial.realign.estwrite.roptions.prefix = 'r';


% Coregistration anat -> mean EPI (Note AM: anat --> EPI et pas l'inverse !!)
stage = stage + 1;
stage_coregister = stage;
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1) = cfg_dep;
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).tname = 'Reference Image';
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).tgt_spec{1}(1).value = 'image';
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).tgt_spec{1}(2).value = 'e';
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).sname = 'Realign: Estimate & Reslice: Realigned Images (Sess 1)';
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).src_exbranch = substruct('.','val', '{}',{stage_realign}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{stage}.spm.spatial.coreg.estimate.ref(1).src_output = substruct('.','sess', '()',{1}, '.','cfiles');
matlabbatch{stage}.spm.spatial.coreg.estimate.source = { anatfile };
matlabbatch{stage}.spm.spatial.coreg.estimate.other = {''};
matlabbatch{stage}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{stage}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{stage}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{stage}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];


% Segmentation
stage = stage + 1;
stage_segmentation = stage;
matlabbatch{stage}.spm.spatial.preproc.data = { anatfile }
matlabbatch{stage}.spm.spatial.preproc.output.GM = [1 0 1];
matlabbatch{stage}.spm.spatial.preproc.output.WM = [1 0 1];
matlabbatch{stage}.spm.spatial.preproc.output.CSF = [0 0 0];
matlabbatch{stage}.spm.spatial.preproc.output.biascor = 1;
matlabbatch{stage}.spm.spatial.preproc.output.cleanup = 0;
greytpm = spm_select('CPath','tpm/grey.nii',spm_path);
whitetpm =  spm_select('CPath','tpm/white.nii',spm_path);
csftpm =  spm_select('CPath','tpm/csf.nii',spm_path);
matlabbatch{stage}.spm.spatial.preproc.opts.tpm = { greytpm, whitetpm, csftpm } ;
matlabbatch{stage}.spm.spatial.preproc.opts.ngaus = [2 2 2 4];
matlabbatch{stage}.spm.spatial.preproc.opts.regtype = 'mni';
matlabbatch{stage}.spm.spatial.preproc.opts.warpreg = 1;
matlabbatch{stage}.spm.spatial.preproc.opts.warpco = 25;
matlabbatch{stage}.spm.spatial.preproc.opts.biasreg = 0.0001;
matlabbatch{stage}.spm.spatial.preproc.opts.biasfwhm = 60;
matlabbatch{stage}.spm.spatial.preproc.opts.samp = 3;
matlabbatch{stage}.spm.spatial.preproc.opts.msk = {''};


% Spatial normalization of anat
stage = stage + 1;
stage_normalisationAnat = stage;
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1) = cfg_dep;
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).tname = 'Parameter File';
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(1).value = 'mat';
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).tgt_spec{1}(2).value = 'e';
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).sname = 'Segment: Norm Params Subj->MNI';
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).src_exbranch = substruct('.','val', '{}',{stage_segmentation}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{stage}.spm.spatial.normalise.write.subj.matname(1).src_output = substruct('()',{1}, '.','snfile', '()',{':'});
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep;
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).tname = 'Images to Write';
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).tgt_spec{1}(1).value = 'image';
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).tgt_spec{1}(2).value = 'e';
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).sname = 'Segment: Bias Corr Images';
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).src_exbranch = substruct('.','val', '{}',{stage_segmentation}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{stage}.spm.spatial.normalise.write.subj.resample(1).src_output = substruct('()',{1}, '.','biascorr', '()',{':'});
matlabbatch{stage}.spm.spatial.normalise.write.roptions.preserve = 0;
matlabbatch{stage}.spm.spatial.normalise.write.roptions.bb = [-78 -112 -50
                                                          78 76 85];
matlabbatch{stage}.spm.spatial.normalise.write.roptions.vox = [1 1 1];
matlabbatch{stage}.spm.spatial.normalise.write.roptions.interp = 1;
matlabbatch{stage}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
matlabbatch{stage}.spm.spatial.normalise.write.roptions.prefix = 'w';


% Spatial normalisation of EPIs
stage = stage + 1;
stage_normalisationEPI = stage;
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1) = cfg_dep;
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).tname = 'Parameter File';
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).tgt_spec{1}(1).value = 'mat';
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).tgt_spec{1}(2).value = 'e';
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).sname = 'Segment: Norm Params Subj->MNI';
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).src_exbranch = substruct('.','val', '{}',{stage_segmentation}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{stage}.spm.spatial.normalise.write.subj(1).matname(1).src_output = substruct('()',{1}, '.','snfile', '()',{':'});
for crn = 1:nruns
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn) = cfg_dep;
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).tname = 'Images to Write';
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).tgt_spec{1}(1).name = 'filter';
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).tgt_spec{1}(1).value = 'image';
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).tgt_spec{1}(2).name = 'strtype';
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).tgt_spec{1}(2).value = 'e';
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).sname = sprintf('Realign: Estimate & Reslice: Realigned Images (Sess %d)',crn);
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).src_exbranch = substruct('.','val', '{}',{stage_realign}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
    matlabbatch{stage}.spm.spatial.normalise.write.subj(1).resample(crn).src_output = substruct('.','sess', '()',{crn}, '.','cfiles');
end
matlabbatch{stage}.spm.spatial.normalise.write.roptions.preserve = 0;
matlabbatch{stage}.spm.spatial.normalise.write.roptions.bb = [-78 -112 -50
                                                          78 76 85];
matlabbatch{stage}.spm.spatial.normalise.write.roptions.vox = voxel_size;
matlabbatch{stage}.spm.spatial.normalise.write.roptions.interp = 1;
matlabbatch{stage}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
matlabbatch{stage}.spm.spatial.normalise.write.roptions.prefix = 'w';


% Smoothing
stage = stage + 1;
stage_smoothing = stage;
matlabbatch{stage}.spm.spatial.smooth.data(1) = cfg_dep;
matlabbatch{stage}.spm.spatial.smooth.data(1).tname = 'Images to Smooth';
matlabbatch{stage}.spm.spatial.smooth.data(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{stage}.spm.spatial.smooth.data(1).tgt_spec{1}(1).value = 'image';
matlabbatch{stage}.spm.spatial.smooth.data(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{stage}.spm.spatial.smooth.data(1).tgt_spec{1}(2).value = 'e';
matlabbatch{stage}.spm.spatial.smooth.data(1).sname = 'Normalise: Write: Normalised Images (Subj 1)';
matlabbatch{stage}.spm.spatial.smooth.data(1).src_exbranch = substruct('.','val', '{}',{stage_normalisationEPI}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{stage}.spm.spatial.smooth.data(1).src_output = substruct('()',{1}, '.','files');
matlabbatch{stage}.spm.spatial.smooth.fwhm = smoothing_kernel;
matlabbatch{stage}.spm.spatial.smooth.dtype = 0;
matlabbatch{stage}.spm.spatial.smooth.im = 0;
matlabbatch{stage}.spm.spatial.smooth.prefix = 's';

%%%%%%%%%%
    matfile = sprintf('preprocess_%s.mat', subjects{csubj});
    save(matfile,'matlabbatch');
    jobs{csubj} = matfile;
end

spm_jobman('serial', jobs, '', inputs{:});


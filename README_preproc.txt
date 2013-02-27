
Option A. You can run the preprocessing script *without* Matlab! To do this:
* Copy file "create_preprocess_batches.m" in "Subjects" directory.
* From there, execute this command:
 spm8 run create_preprocess_batches.m
The preprocessing will be executed using compiled SPM8 (available on Linux 
computers in NeuroSpin).

Option B. Using Matlab:
* Copy file "create_preprocess_batches.m" in "Subjects" directory.
* Run Matlab and then SPM8.
* Open file "create_preprocess_batches.m", *uncomment* this line and save .m file:
 addpath(spm_path); % comment to run in compiled spm8
* Run file "create_preprocess_batches.m".

Option C. Using Matlab and SPM8 interface:
* Copy file "create_preprocess_batches.m" in "Subjects" directory.
* Run Matlab and then SPM8.
* Open file "create_preprocess_batches.m" and *uncomment* this line:
 addpath(spm_path); % comment to run in compiled spm8
* *Comment* the last line and save .m file:
 spm_jobman('serial', jobs, '', inputs{:});
* Run file "create_preprocess_batches.m".
* Finally, launch SPM8 and, from the interface, press button "Batch", load 
preprocess*.mat file and run it.


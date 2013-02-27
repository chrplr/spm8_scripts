
subject = {'sub01_cm100138','sub02_vr100551','sub03_ac100065','sub04_mb110481','sub05_ar110122','sub06_cd100449',...
'sub07_jm100042','sub09_ah120096','sub10_pj100477','sub11_dm110482','sub12_mn080208','sub13_cd110379',...
'sub14_ml100548','sub15_cg120093','sub16_fd110104','sub17_hr090062', 'sub19_ml110339', 'sub20_cj100142','sub08_ib110406','sub18_rm080030'};


        
for suj = 1:length(subject)

 pathspmmat = fullfile('/neurospin/unicog/protocols/IRMf/ConstituantPriming_Pattamadilok_Pallier_2012/Subjects/', subject{suj}, 'analyses/FIR2', 'SPM.mat')
 D = mardo(pathspmmat);
 D = cd_images(D, fullfile('/neurospin/unicog/protocols/IRMf/ConstituantPriming_Pattamadilok_Pallier_2012/Subjects/', subject{suj}, 'fMRI'));
 save_spm(D);

end
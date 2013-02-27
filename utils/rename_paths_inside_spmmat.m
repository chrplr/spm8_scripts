
spmfile = '/neurospin/unicog/protocols/IRMf/ConstituantPriming_Pattamadilok_Pallier_2012/Group_analyses/CopyAmorce_silence/SPM.mat';

load(spmfile);

SPMori=SPM;

f=SPM.xY.P; 
mm=[]; 

for ligne=1:size(f,1); 
    mm=[mm;(strrep(f(ligne,:),',1',''))]; 
end; 

SPM.xY.P=mm;

cP=cellstr(SPM.xY.P);
[SPM.xY.VY(:).fname]=deal(cP{:});

save (spmfile,'SPM')


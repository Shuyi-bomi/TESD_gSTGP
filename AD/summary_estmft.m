% This is to summarize estimated mean function of time with fixed locations
% as functions of time

clear;
sufx={'','_mtimesx','_gpu'};
stgp_ver=['STGP',sufx{2}];
addpath('../util/');
% addpath(['../util/+',stgp_ver,'/']);
if contains(stgp_ver,'mtimesx')
    addpath('../util/mtimesx/');
end
addpath('../util/tight_subplot/');
% addpath(genpath('../util/boundedline-pkg/'));
% Random Numbers...
seedNO = 2018;
seed = RandStream('mt19937ar','Seed',seedNO);
RandStream.setGlobalStream(seed);

% data settings
types={'PET','MRI'};
typ=types{1};
groups={'CN','MCI','AD'};
L_grp=length(groups);
% grp=groups{2};
dur=[5,6,4];
stdtimes={[0:.5:1,2:3]',[0:.5:1.5,2:3]',[0:.5:1,2]'};
L=100;
d=2;
sec=48;
% model options
models={'kron_prod','kron_sum'};
L_mdl=length(models);
opthypr=false;
jtupt=false;
% intM=false;
alg_name='MCMC';
if opthypr
    alg_name=['opt',alg_name];
    if jtupt
        alg_name=['jt',alg_name];
    end
end

%% estimation

% estimate the mean from MCMC samples
% load data
folder = './summary/';
files = dir(folder);
nfiles = length(files) - 2;
for l=2:L_mdl
intM=true;
keywd = {[alg_name,'_',repmat('intM_',intM),models{l}],['_L',num2str(L),'_d',num2str(d)]};
f_name = ['estmft_',keywd{:}];
if exist([folder,f_name,'.mat'],'file')
    load([folder,f_name,'.mat']);
    fprintf('%s loaded.\n',[f_name,'.mat']);
else
    M_estm=cell(1,L_grp); M_estd=M_estm; Times=M_estm;
    for gr=1:L_grp
        grp=groups{gr}; J=dur(gr);
        keywd{3}=['_J',num2str(J)];
        found=false;
        for k=1:nfiles
            fname_k=files(k+2).name;
            if contains(fname_k,['_',grp,'_']) && contains(fname_k,keywd{1}) && contains(fname_k,keywd{2}) && contains(fname_k,keywd{3})
                load(strcat(folder, fname_k));
                fprintf('%s loaded.\n',fname_k);
                found=true; break;
            end
        end
        if found
            if size(samp_M,3)==2
                M_estm{gr}=samp_M(:,:,1); M_estd{gr}=samp_M(:,:,2);
            else
                M_estm{gr}=shiftdim(mean(samp_M,1)); M_estd{gr}=shiftdim(std(samp_M,0,1));
            end
            Times{gr}=t;
            % reshape
            if ~exist('imsz','var')
                imsz=sqrt(size(M_estm{gr},1)).*ones(1,2);
            end
            M_estm{gr}=reshape(M_estm{gr},imsz(1),imsz(2),[]); M_estd{gr}=reshape(M_estd{gr},imsz(1),imsz(2),[]);
        end
    end
    % save the estimation results
    save([folder,f_name,'.mat'],'M_estm','M_estd','Times','stdtimes');
end


%% summarize
sumry=cell(1,L_grp);
if exist([folder,f_name,'.mat'],'file')
    
    if ~isempty(M_estm{1})
        
        for gr=1:L_grp
            grp=groups{gr};
            M_gr=reshape(M_estm{gr},[],size(M_estm{gr},3));%.*32767;
            if ~isempty(M_gr)
                dat=dataset(M_gr);
                sumry{gr}=summary(dat);
            end
        end
        % save summary
        save([folder,'sumry_',f_name,'.mat'],'sumry');
    end
end

end
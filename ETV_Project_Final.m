%% ETV Project 
% This script loads ETV images, performes cluster analysis of floating
% particles, and evluates velocity of each particles
% Min Jae Kim (mkim@bwh.harvard.edu)
% Last Edited on: 12/19/2022
%% Overview 
% Important Variables: 
% (1) imstor: stores each image frames of loadedvideo
% (2) cntrd_cell: stores cluster coordinates & centroid of clusters per frame
% (3) ident_cell: stores cluster membership in each adjacent time-points
%% Variable Set 
vid_tit='f5150_iiiPost.mp4'; % 
filt_Y=1; % Apply gaussan filter
gaus_filt=2; % Degree of filter (this smoothes frame image)
thr_diff=0.85; % Threshold for diff image 
clust_size=100; % Minimum Cluster Membership
auto_lag_thr=4.7; %Maximum distance between temporal points (%) of entire pixel dimention
auto_corr=0.5; %Minimum correlation coefficient between clusters between temporal points
%% Step 0: Loading Video
vid=VideoReader(vid_tit); %Load Video file
numFrames = vid.NumberOfFrames;
n=numFrames;
imstor=cell(1,n);
 for i = 1:n
 frames = read(vid,i);
 gI = rgb2gray(frames); 
 K = mat2gray(gI);
 if filt_Y==1
    K = imgaussfilt(K,gaus_filt); 
 end 
 imstor{1,i}=K;         %each element of imstor is frames of the video
 end
"There are "+string(n)+" frames to process"
%% Step 1: Temporal Difference Map 
cntrd_cell=cell(numFrames,2);
vali=1:numFrames;

for i=2:numFrames  %length(vali)
    tic
   % figure
    val=imstor{1,vali(i)}-imstor{1,vali(i)-1};
    val = imgaussfilt(val,gaus_filt); 
    % Imposing Threshold
    maxi=max(val(:));
    mini=min(val(:));
    thr_val=mini+(abs(maxi-mini).*thr_diff);
    val(val<thr_val)=0;
    %% Step 2: Binarizaton of Difference Map 
    val(val>0)=1;
    %%
    [idxi_x,idxi_y]=find(val==1);
    
    if length(idxi_x)./(size(val,1)*size(val,2))*100 <=0.5 % Only chose frames below 0.5%
    euc_mat=[];
    for ii=1:length(idxi_x)
        coor=[idxi_x(ii),idxi_y(ii)];
        for jj=1:length(idxi_x)
            new_coor=[idxi_x(jj),idxi_y(jj)];
            euc=sqrt(sum((coor - new_coor) .^ 2));
            euc_mat(ii,jj)=euc;
        end 
    end
    %% Step 3: Hierchial Clustering
    Z = linkage(euc_mat);
   % dendrogram(Z)
    c = cluster(Z,'Cutoff',500,'Criterion','distance'); % Cluster Cutoff;
    max_clust=max(c);
    clust_cell=cell(max_clust,1);
    for hh=1:max_clust
        idxi=find(c==hh);
        sel_x=idxi_x(idxi);
        sel_y=idxi_y(idxi);
        sel_cor=[sel_x,sel_y];
        clust_cell{hh,1}=sel_cor;
    end 
    %% Step 4: Cluster Post-Processing
    del_idxi=[];
    for hh=1:max_clust
        mem_size=size(clust_cell{hh,1},1);
        if mem_size<clust_size
            del_idxi=[del_idxi;hh];
        end 
    end 
    clust_cell(del_idxi)=[];
    %% Step 5: Centroid Extraction
    max_clust=length(clust_cell); %revised cluster numbers
    cntrd_col=[];
    for hh=1:max_clust
        clust_idxi=clust_cell{hh,1};
        cntrd_val=[round(mean(clust_idxi(:,1))),round(mean(clust_idxi(:,2)))];
        cntrd_col=[cntrd_col;cntrd_val];
    end 
    cntrd_cell{i,1}=cntrd_col;
    cntrd_cell{i,2}=clust_cell;
    end 
    i
    toc
end 
%% Step 6: Time-Variant Cluster Membership Confirmation
%% N.B!!: index (ii) of ident_col is from cluster membership from ii <-- ii-1
% E.g: cluster membership of 3 of indent_col is from timepoint 2 -->
% timepoint 3
ident_col=cell(length(cntrd_cell),1);
for i=1:size(cntrd_cell,1)
    if ~isempty(cntrd_cell{i,2}) && ~isempty(cntrd_cell{i+1,1})
    val_1=cntrd_cell{i,2};
    ident_cell=cell(size(val_1,1),1);
    for ii=1:size(val_1,1)
        vec=val_1{ii};
        temp_1=zeros(size(K));
        temp_1(vec(:,1),vec(:,2))=1;
        %
        val_2=cntrd_cell{i+1,2};
        %
        r_vec=[];
        dist_vec=[];
        ident_vec=[];
        %
        for jj=1:size(val_2,1)
            vec_2=val_2{jj};
            temp_2=zeros(size(K));
            temp_2(vec_2(:,1),vec_2(:,2))=1;
            
            [r,lags] = xcorr(temp_1(:),temp_2(:),'normalized');
            
            r_max=max(r);
            lag=abs(median(lags(find(r==r_max))));
            % cluster t=0 is equal to cluster t=1 under spatial constraint
            % correlation of cluster volumes under auto-correlation 
             if lag./max(lags)*100 <= auto_lag_thr && r_max >= auto_corr
                 ident_vec=[ident_vec;1]; 
                 r_vec=[r_vec;r_max];
                 dist_vec=[dist_vec;lag];
             else 
                 ident_vec=[ident_vec;0];  
                 r_vec=[r_vec;r_max];
                 dist_vec=[dist_vec;lag];
             end 
        end 
        % This code is when one cluster at t=0 divides into 2 (or more) at t=1
        % Forces one cluster to produce one cluster (no multiple cluster) 
        if length(find(ident_vec==1))>1 % [1,1] repeat
            idxi_r=find(r_vec==max(r_max));
            ident_vec(ident_vec~=idxi_r)=0;            
        end 
     
        ident_cell{ii,1}=ident_vec;
    end 
    ident_col{i+1,1}=ident_cell;
    end 
end 
%% Step 4: Cluster Membership Streamline: Follow the One!
%%
updt_col=cell(size(ident_col,1),1);
for i=2:size(ident_col,1)
    clust_mem=ident_col{i,1};
    %% CASE 1: when idx=i-1 (previous) has 1 cluster
    if size(clust_mem,1)==1 
        old_coor=cntrd_cell{i-1,1}; %idx=i-1 (previous) cluster centroid
        updt_coors=cell(1,1);
        post_clust=clust_mem{1,1};
        if length(post_clust)==1 %% 1 --> 1 mapping
            post_clust_idxi=find(post_clust==1);
            cndtes=cntrd_cell{i,1};
            new_coor=cndtes(post_clust_idxi,:);
        elseif length(post_clust)>1 %1 --> many mapping 
            post_clust_idxi=find(post_clust==1); %idxi=i (post) cluster centroid
            cndtes=cntrd_cell{i,1};
            new_coor=cndtes(post_clust_idxi,:);
        end  
        updt_coors{1,1}=[old_coor;new_coor];
        updt_col{i,1}=updt_coors;
    %% CASE 2:  %when idx=i-1 (previous) has more than cluster i=8
    elseif size(clust_mem,1)>1 
        old_coors=cntrd_cell{i-1,1}; %idx=i-1 (previous) cluster centroid
        updt_coors=cell(size(clust_mem,1),1);
        for jj=1:size(clust_mem,1) 
            old_coor=old_coors(jj,:);
            post_clust=clust_mem{jj,1};
            post_clust_idxi=find(post_clust==1); %idxi=i (post) cluster centroid
            cndtes=cntrd_cell{i,1};
            new_coor=cndtes(post_clust_idxi,:);
            updt_coors{jj,1}=[old_coor;new_coor];
        end 
        updt_col{i,1}=updt_coors;
    end 
    
    %updt_col{i,1}=updt_coors;
end 
%% 
exst=[];
empt=[];
for i=1:size(updt_col,1)
    if isempty(updt_col{i,1})
        empt=[empt;i];
    else
        exst=[exst;i];
    end 
end 
diffi=diff(empt);
diffi_2=diff(exst);
brdn=empt(find(diffi>1)); %brdn
brdn=[1;brdn];
brdn_exst=exst(find(diffi_2>1));
brdn_exst=brdn_exst+ones(size(brdn_exst));
empt_vec=sort([brdn;brdn_exst]);
if rem(length(empt_vec), 2)~=0
    empt_vec(end)=[];
end 
empt_vec = reshape(empt_vec,2,[])';


for i=1:size(empt_vec,1)
    idxi=empt_vec(i,1):empt_vec(i,2);
    for jj=idxi
        updt_col{jj,1}=updt_col{empt_vec(i,2)+1,1};
    end 
end 

%% Cluster Mapping & Timepoint Extraction
    ini_coor=updt_col{2,1}{1,1}; %2nd element;
    cnt=1; %counter cluster
    seed_epoch=cell(1,3); %cluster inventory: 1st clmn: seed, 2nd clmn: cntrd of clusters, 3rd clm: time 
    if size(ini_coor,1)
        seed_epoch{cnt,1}=ini_coor(1,:);
    else 
        seed_epoch{cnt,1}=ini_coor(2,:); %first seed
    end 
    seed_epoch{cnt,2}=ini_coor; %[updt]; %first cluster initialization
    seed_epoch{cnt,3}=[1;2];
    %updt=seed_epoch{cnt,1}; %first seed initialization
    
    
    for jj=3:size(updt_col,1)
        updts=updt_col{jj,1}; %fist updts 
        if ~isequal(updts,updt_col{jj-1,1})
            for hh=1:size(updts,1)
                candi=updts{hh,1}; %first updts confirming
                if size(candi,1)==2 
                    %% Removing Repeats
                    updt_cols=[];
                    for kk=1:cnt
                        updt_cols=[updt_cols;seed_epoch{kk,1}];
                    end 
                %% 
                    for kk=1:cnt
                        updt=seed_epoch{kk,1};  
                    %% Case 1: Branching of Continuing Connection
                        if isequal(candi(1,:),updt) %estalishing last link (pre) to new link (post)
                            clust_cnt=seed_epoch{kk,2}; %loading exising cluster
                            clust_cnt=[clust_cnt;candi(2,:)]; %updated cluster cntrd
                            updt=candi(2,:); %update seed 
                            t_1=seed_epoch{kk,3};
                            t_1=[t_1;jj];
                        
                            seed_epoch{kk,1}=updt; 
                            seed_epoch{kk,2}=clust_cnt;
                            seed_epoch{kk,3}=t_1;
                       %% Case 2: Starting New Connection
                        %elseif ~isequal(candi(1,:),updt) %new connection
                        elseif ~ismember(candi(1,:),updt_cols)==ones(1,2) % ~isequal(candi(1,:),updt) %new connection
                            new_clust_cnt=[];
                            new_clust_cnt=[new_clust_cnt;candi]; %updated cluster cntrd
                            cnt=cnt+1; %Updating cnt (forming new branch)
                            seed_epoch{cnt,1}=candi(2,:); %updated seed
                            seed_epoch{cnt,2}=new_clust_cnt; %updated seed
                            seed_epoch{cnt,3}=[jj-1;jj];
                        end 
                        
                        if cnt>=2 %Removing repeats
                            if isequal(seed_epoch{cnt,1},seed_epoch{cnt-1,1}) && isequal(seed_epoch{cnt,2},seed_epoch{cnt-1,2})
                                cnt=cnt-1;
                            end 
                        end 
 
                    end 
                end 
            end
        end
        jj
    end 
%% Plotting & Saving Variables
sv_tit=erase(vid_tit,".mp4");

% Removing clusters with membership < 3
rmv=[];
for i=1:size(seed_epoch,1)
    if size(seed_epoch{i,2},1)<3
        rmv=[rmv;i];
    end 
end 
seed_epoch(rmv,:)=[];
save(sv_tit,"seed_epoch");

%{
for i=1:40; %size(seed_epoch,1)
RGB=[rand,rand,rand];
vec=seed_epoch{i,2};
Y=vec(:,1);
X=vec(:,2);
Y=vid.Height-Y;
Spatio=[X,Y]; %swiw
for jjj=1:length(X)
    vec=Spatio(jjj,:);
    plot(vec(1),vec(2),'--o','MarkerSize',10,'MarkerEdgeColor',RGB,'MarkerFaceColor',RGB);
    axis([1 vid.Width 1 vid.Height])
    xlabel('X-Pixels of Scope');
    ylabel('Y-Pixels of Scope');
    title('Spatial Location of Particle Trajectory | dt= 0.03 sec ');
    hold on
    pause(0.5)
end
hold off
end 
%}
clear all

   




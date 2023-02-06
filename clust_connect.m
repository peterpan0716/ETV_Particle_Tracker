function [vec]=clust_connect(seed,i,cntrd_cell)
if length(cell2mat(seed))==1 % one cluster --> one cluster mapping
    vec=[cntrd_cell{i-1,1};cntrd_cell{i,1}];
elseif length(cell2mat(seed))>1 % many cluster --> one cluster mapping
    for j=1:length(seed)
        if sum(seed{j,1})==1 
            seed_2nd=find(seed{j,1}==1);
            vec=[cntrd_cell{i-1, 1}(j,:);cntrd_cell{i,1}(seed_2nd,:)];
        end
    end 
end 
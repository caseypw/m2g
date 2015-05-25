% W Gray Roncal
% 01.14.2015
% Greg Kiar
% 05.04.2015
% Script to compare KKI42 test retest data and plot result
% Scans are reordered so that both scans for each subject appear together
% Data (covariates and small graphs are from the public ftp site)
% openconnecto.me/data/public/MR/MIGRAINE_v1_0/KKI-42/

%% Load files
files = dir('*.mat');
temp = importdata('kki42_subjectinformation.csv');

for i = 2:length(temp)
    reorderIdx(i-1) = str2num(temp{i}(end-1:end));
end

c = 1;
for i = reorderIdx
    temp = load(files(i).name);
    tgraph = (full(temp.graph)); % log10
    tgraph(isinf(tgraph))=0;
    %     tgraph=full(temp.graph);
    smg(:,:,c) = tgraph;
    
    c = c+1;
end

%% Compute Graph Differences
for i = 1:size(smg,3)
    for j = 1:size(smg,3)
        gErr(i,j) = norm(smg(:,:,i)-smg(:,:,j),'fro');
        %         gErr(i,j) = sum(sum(abs(smg(:,:,i)-smg(:,:,j))));
    end
end

%% Compute TRT
figure(1), imagesc(gErr), colorbar
matches = 0;
intra = 0; inter = 0;
intravec = [];
intervec = [];
for i = 1:1:size(gErr,1)
    temp = sort(gErr(i,:));
    q = i-1+2*mod(i,2);
    matches = matches + (temp(2)==gErr(i,q));
    intra = intra + gErr(i,q);
    temp2 = sum([gErr(i,1:q-1), gErr(i,q+1:end)])/40; %40 bc 1 is intra, 1 is me
    inter = inter + temp2;
    intravec = [intravec, gErr(i,q)];
    if i < q
        if i > 1
            intervec = [intervec, gErr(i,q-2), gErr(i,q+1:end)];
        else
            intervec = [intervec, gErr(i,q+1:end)];
        end
    else
        if i > 2
            intervec = [intervec, gErr(i,q-1), gErr(i,q+2:end)];
        else
            intervec = [intervec, gErr(i,q+2:end)];
        end
    end
end
intra = intra/42;
inter = inter/42;
title(strcat('correct matches=', num2str(matches),'/', num2str(size(smg,3))));

%% Compute Hellinger Distance
figure(3)
[~, x_intra] = ksdensity(intravec);
[~, x_inter] = ksdensity(intervec);
lims = [min([x_intra,x_inter]), max([x_intra, x_inter])]; %innefficient but works...
xrange = lims(1):range(lims)/300:lims(2);

[f_intra] = ksdensity(intravec, xrange);
[f_inter] = ksdensity(intervec, xrange);

H = norm(sqrt(f_intra)- sqrt(f_inter),2)/sqrt(2);

plot(xrange, f_intra, xrange, f_inter);
legend('Intra Subject Kernel Esimate', 'Inter Subject Kernel Estimate');
title(strcat('Hellinger Distance=', num2str(H)));

%% Compute Null Distribution and Hellinger
%{
hperm = [];
for ii = 1:10000
    N = randperm(42);
    tempg = gErr(N, N);
    %     figure(4); imagesc(tempg)
    
    n_intravec = [];
    n_intervec = [];
    for i = 1:1:size(gErr,1)
        temp = sort(tempg(i,:));
        q = i-1+2*mod(i,2);
        
        n_intravec = [n_intravec, tempg(i,q)];
        if i < q
            if i > 1
                n_intervec = [n_intervec, tempg(i,q-2), tempg(i,q+1:end)];
            else
                n_intervec = [n_intervec, tempg(i,q+1:end)];
            end
        else
            if i > 2
                n_intervec = [n_intervec, tempg(i,q-1), tempg(i,q+2:end)];
            else
                n_intervec = [n_intervec, tempg(i,q+2:end)];
            end
        end
        
    end
    
    [~, nx_intra] = ksdensity(n_intravec);
    [~, nx_inter] = ksdensity(n_intervec);
    lims = [min([nx_intra,nx_inter]), max([nx_intra, nx_inter])]; %innefficient but works...
    nxrange = lims(1):range(lims)/300:lims(2);
    
    [nf_intra] = ksdensity(n_intravec, nxrange);
    [nf_inter] = ksdensity(n_intervec, nxrange);
    
    hperm = [hperm, norm(sqrt(nf_intra)- sqrt(nf_inter),2)/sqrt(2)];
    %     figure(3); plot(nxrange, nf_intra, nxrange, nf_inter);
    %     pause
end

pval = sum(hperm >= H) ./ length(hperm)

%}
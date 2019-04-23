% =======================<info>=======================
% Title:   Data_Analysis
% Date:    21-Mar-19
% Author:  ALONELUR
% ====================================================

clc
clear
Date = '19-Mar-2019';
PersonName = 'YWH_road';
GroupName = {'1','noisy','reality','simulate'};

Samplefrq = 500; %²ÉÑùÆµÂÊ
harmNum = 5;
filterNum = 5;
Datalength = 750;

figure(1);
axTrg = axes;
figure(2);
axP = axes;

Judge = cell(1,4);
averJudge = zeros(1,4);
for iGroup = 1:4
    DataDir = [Date '\' PersonName '\' GroupName{iGroup} '\' '*.mat'];
    Datafile_list = dir(DataDir);
    DataN = length(Datafile_list);
    
    Judge{iGroup} = zeros(1,DataN);
    for iD = 1:DataN
        Data = load([Datafile_list(iD).folder, '\', Datafile_list(iD).name]);
        Targetfre = Data.data(1,:);
        Signal = Data.timedata';
        rho = Analysis(Samplefrq, Targetfre, Signal, harmNum, filterNum);
        [index, p] = Sigmod(rho);
        contrast = GorR(rho,index);
        Judge{iGroup}(1,iD) = contrast;

        % plot(axTrg, 1:size(Targetfre,2), rho)
        % plot(axP, 1:size(Targetfre,2), p)
    end

    averJudge(1,iGroup) = mean(Judge{iGroup});
end

function  rho = Analysis(Samplefrq, Targetfre, Signal, harmNum, filterNum)
%myFun - Description
%
% Syntax:  = Analysis(Samplefrq, Targetfre, Signal, harmNum, filterNum)
%
% Long description
    Testdata = notch_filter(Signal, Samplefrq / 2);
    rho = test_fbcca_total(Testdata, Targetfre, Samplefrq ./ 2, harmNum, filterNum);
    rho = rho(1,:);
end

function [index,p] = Sigmod(input)
    %Sigmod - Description
    %
    % Syntax: [index] = Sigmod(input)
    %
    % Long description
        num = exp(input);
        dec = sum(num);
        p = num ./ dec;
        [~,index] = max(p);
        index = index(1);
end

function result = GorR(p, index)
%GorR - Description
%
% Syntax: Judge = GorR(p, index)
%
% Long description
    MAX = p(index);
    TargetN = size(p,2);
    Average = (sum(p) - MAX) / (TargetN - 1);

    result = 1 - Average/MAX;
end
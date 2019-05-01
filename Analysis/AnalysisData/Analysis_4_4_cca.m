clc
clear
addpath('../function');
Analysis_4_10_readAll;

sampleRate1 = 250;
sampleRate2 = 500;
T1 = 1/sampleRate1;
T2 = 1/sampleRate2;

dataTime = 3;
dataLength = size(DATA{1}.timedata,2);
Target = DATA{1}.target;
DATANum = length(DATA);

t = linspace (0, 3-T1, 750);
startTime = 0;
startIndex = fix(startTime / T1)+1;
endTime = 0.5;
endIndex = fix(endTime / T1);
indexList = endIndex:62:dataLength;

fre = 3:0.25:25;
freNum = length(fre);
cca = zeros(DATANum,freNum,length(indexList));
for iT = 1:length(indexList)
    for iD = 1:DATANum
        parfor iF = 1:freNum
            data = DATA{iD}.timedata(:,startIndex:indexList(iT));
            refdata = cca_reference(fre(iF), sampleRate1, indexList(iT), [-1,3]);
            data = notch_filter(data, sampleRate1);
            result = cca_analysis(data,refdata,fre(iF));
            cca(iD,iF,iT) = result;
        end
    end
end
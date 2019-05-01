clc
clear
addpath('../function');
Analysis_4_10_readAll;

sampleRate1 = 250;
sampleRate2 = 500;
T1 = 1/sampleRate1;
T2 = 1/sampleRate2;
dataLength = 750;
dataTime = 3;

Target = DATA{1}.target;
TargetNum = length(Target);
DATANum = length(DATA);
refdata = cca_reference(Target, sampleRate1, size(DATA{1}.timedata,2), 5);

t = linspace (0, 3-T1, 750);

startTime = 0;
startIndex = fix(startTime / T1)+1;
endTime = 0.5;
endIndex = fix(endTime / T1);

indexList = endIndex:5:dataLength;
sampleNum = length(indexList);
counter = zeros(TargetNum + 1,sampleNum);
wrong = zeros(TargetNum + 1,sampleNum);
predict = zeros(sampleNum, TargetNum);

for iC = 1:sampleNum
    endIndex = indexList(iC);
    for iD = 1:DATANum
       data = DATA{iD}.timedata(:,startIndex:endIndex);
        data = notch_filter(data, sampleRate1);
        predict(iC,:) = test_fbcca_YWH(data,refdata(:,startIndex:endIndex,:),Target,sampleRate1, 5);

        [result, indexMax, contrast] = Contrast(predict(iC,:));
       if result
           counter(indexMax,iC) = counter(indexMax,iC) + 1;
       else
           counter(end,iC) = counter(end,iC) + 1;
       end

       if result && ~sum(DATA{iD}.label)
           wrong(indexMax,iC) = wrong(indexMax,iC) +1;
       elseif result == 0 && sum(DATA{iD}.label)
           wrong(end,iC) = wrong(end,iC) + 1;
       end
    end
end
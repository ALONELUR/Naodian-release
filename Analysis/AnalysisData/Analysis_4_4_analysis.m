clc
clear
addpath('../function');
Analysis_4_4_read;

sampleRate1 = 250;
sampleRate2 = 500;
T1 = 1/sampleRate1;
T2 = 1/sampleRate2;
dataLength = 750;
dataTime = 3;

Target = DATA{1}.target;
DATANum = length(DATA);



t = linspace (0, 3-T1, 750);

startTime = 0;
startIndex = fix(startTime / T1)+1;
endTime = 0.5;
endIndex = fix(endTime / T1);

indexList = endIndex:5:dataLength;
correctRate = zeros(length(DATA{1}.label),length(indexList));

for iC = 1:length(indexList)
    endIndex = indexList(iC);
    right = zeros(1,length(Target));
    wrong = zeros(1,length(Target));
    for iD = 1:DATANum
        data = DATA{iD}.timedata(:,startIndex:endIndex);
        refdata = cca_reference(Target, sampleRate1, size(data,2), 5);
        data = notch_filter(data, sampleRate1);
        result = test_fbcca_YWH(data,refdata,Target,sampleRate1, 5);
        [~,index] = max(result);
        [~,index2]= max(DATA{iD}.label);
        if index == index2
            right(index2) = right(index2) + 1;
        else
            wrong(index2) = wrong(index2) + 1;        
        end
    end
    correctRate(:,iC) = right' ./ (right'+wrong');
end
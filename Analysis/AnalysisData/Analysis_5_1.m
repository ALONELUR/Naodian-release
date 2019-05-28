clc
clear
addpath('../function');
Analysis_4_10_readAll;

sampleRate1 = 250;
T1 = 1/sampleRate1;
dataLength = size(DATA{1}.timedata,2);
Target = DATA{1}.target;
TargetNum = size(Target,2);
DATANum = length(DATA);

cca = zeros(DATANum,TargetNum);



% for iD = 1 : DATANum
%     for iT = 1:TargetNum
%         data = DATA{iD}.timedata;
%         % refdata = cca_reference(Target(iT), sampleRate1, dataLength, [-1,3]);
%         refdata = cca_reference(Target(iT), sampleRate1, dataLength, [-1,3]);
%         data = notch_filter(data, sampleRate1);
%         % result = cca_analysis(data,refdata,Target(iT));
%         result = cca_analysis(data,refdata,Target(iT));
%         cca(iT,iD) = result;
%     end
% end

for iD = 1 : DATANum
    data = DATA{iD}.timedata;
    % refdata = cca_reference(Target(iT), sampleRate1, dataLength, [-1,3]);
    refdata = cca_reference(Target, sampleRate1, dataLength, [1,4]);
    data = notch_filter(data, sampleRate1);
    result = cca_analysis(data,refdata,Target);
    cca(iD,:) = result;
end

[~,index ] = max(cca');
plot(index)
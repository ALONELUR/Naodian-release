clc
clear
addpath('../function');
Analysis_4_10_readAll;

% targetFre = [18.3 17 20.3 19 21 16.3 22.3 15.3];
targetFre = DATA{1}.target;
refdata = cca_reference(targetFre, 250, 750, [0,3]);
for iD = 1:length(DATA)
    data = DATA{iD}.timedata;
    data = notch_filter(data, 250);
    result = cca_analysis(data,refdata,targetFre);
    cca(iD,:) = result;
    temp = zeros(1,length(DATA{iD}.label));
    [~, index] = max(result);
    temp(index) = 1;
    predict(iD,:) = temp;
    answer(iD,:) = DATA{iD}.label;
end
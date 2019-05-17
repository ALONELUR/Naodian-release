clc
clear
Analysis_4_10_readAll;

DataNum = length(DATA);
TargetNum = length(DATA{1}.target);
counter = zeros(1,TargetNum + 1);
wrong = zeros(1,TargetNum + 1);
for iD = 1:DataNum
   predict = DATA{iD}.predict;
   [result, indexMax, contrast] = Contrast(predict);
   if result
       counter(indexMax) = counter(indexMax) + 1;
   else
       counter(end) = counter(end) + 1;
   end
   
   if result && ~sum(DATA{iD}.label)
       wrong(indexMax) = wrong(indexMax) +1;
   end
end
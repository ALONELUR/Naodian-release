function [result, indexMax, constract] = Contrast(predict)
%UNTITLED3 此处显示有关此函数的摘要
%   此处显示详细说明
threshold = 0.16;

if sum(predict) ~= 0
    [MAX, indexMax] = max(predict);
    TargetNum = length(predict);
    constract = MAX / ...
        (sum(predict) - predict(indexMax))/(TargetNum-1);
    if constract >= threshold
        result = 1;
    else
        result = 0;
    end
else
    result = 0;
    indexMax = 0;
    constract = 0;
end

end


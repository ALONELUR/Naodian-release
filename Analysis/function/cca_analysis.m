function result = cca_analysis(data,y_ref,targ_fre,varargin)
% cca_analysis - cca分析程序
%
% Syntax: result = cca_analysi(data,y_ref,targ_fre[,fs,fbs_num])
%
% Long description：
% 简化过后的cca分析程序，可以选择使不使用滤波器组。如果
    
%{
=========================================
Label   : 解析输入数据
-----------------------------------------
Explain : TargetNum：输入目标刺激频率的数目
    varargin:
        1:fs：采样频率
        2:
          
=========================================
%}
    TargetNum = length(targ_fre);

    if ~size(varargin)
%{
=========================================
Label   : cca分析——无滤波器组
-----------------------------------------
Explain : 
=========================================
%}
    result=zeros(1,TargetNum);
    % 初始化结果
    for iTar = 1:TargetNum
        refdata = squeeze(y_ref(:,:,iTar));
        [~,~,temp] = canoncorr(data', refdata');
        result(1,iTar) = temp(1,1);
    end
%{
=========================================
Label   : cca分析——有滤波器组
-----------------------------------------
Explain : 尚未完成，不要使用
=========================================
%}

    elseif size(varargin)
        error("filterbank函数未完成，不要使用！");
    end

end
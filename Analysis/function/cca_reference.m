function yef = cca_reference(targ_fre, fs, sample_num, harms)
%cca_reference - 生成参考信号
%
% Syntax: yef = cca_reference(targ_fre, fs, sample_num, harms)
%
% 

%{
=========================================
Label   : 解析输入参数
-----------------------------------------
Explain : TargetNum:目标刺激频率数量
          HarmList: 谐波列表
=========================================
%}
    TargetNum = size(targ_fre,2);
    if size(harms,2)~=2 || rem(harms(1),1) ~= 0 || rem(harms(2),1) ~= 0
        error("function: cca_regerence, 输入谐波次数应为整数");
    else
        HarmList = harms(1):1:harms(2);
    end
    harms_num = size(harms,2);

    t = linspace(0,sample_num/fs-1/fs,sample_num);

%{
=========================================
Label   : 生成参考信号
-----------------------------------------
Explain : 
=========================================
%}

    channelNum = 4;
    yef = zeros(channelNum, sample_num, TargetNum);
    %初始化函数输出 yef(# 输出谐波, # 采样长度，# 目标频率数量)
    t = repmat(t, channelNum, 1);
    for targ_i = 1:TargetNum
        temp = zeros(channelNum, sample_num);
        for harm_i = 1:harms_num
            temp = temp + exp(-0.7*abs(HarmList(harm_i)))*sin(2*pi*targ_fre(targ_i)*2^HarmList(harm_i)*t+2*pi*rand(channelNum, 1));
        end
        yef(:,:,targ_i) = temp;
    end
end
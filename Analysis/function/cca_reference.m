function yef = cca_reference(targ_fre, fs, sample_num, harms)
%cca_reference - ���ɲο��ź�
%
% Syntax: yef = cca_reference(targ_fre, fs, sample_num, harms)
%
% 

%{
=========================================
Label   : �����������
-----------------------------------------
Explain : TargetNum:Ŀ��̼�Ƶ������
          HarmList: г���б�
=========================================
%}
    TargetNum = size(targ_fre,2);
    if size(harms,2)~=2 || rem(harms(1),1) ~= 0 || rem(harms(2),1) ~= 0
        error("function: cca_regerence, ����г������ӦΪ����");
    else
        if harms(1)<=0
            harmNum = harms(2)-harms(1);
        else
            harmNum = harms(2)-harms(1)+1;
        end
        HarmList = zeros(1,harmNum);
        iHarm = 1;
        for Harm = harms(1):harms(2)
            if Harm < 0
                HarmList(iHarm) = 2^Harm;
            elseif Harm == 0
                continue;
            else
                HarmList(iHarm) = Harm;
            end
            iHarm = iHarm + 1;
        end
        
    end

    t = linspace(0,sample_num/fs-1/fs,sample_num);

%{
=========================================
Label   : ���ɲο��ź�
-----------------------------------------
Explain : 
=========================================
%}

    channelNum = harmNum*2;
    yef = zeros(channelNum, sample_num, TargetNum);
    %��ʼ��������� yef(# ���г��, # �������ȣ�# Ŀ��Ƶ������)
%     t = repmat(t, channelNum, 1);
    for targ_i = 1:TargetNum
        temp = zeros(channelNum, sample_num);
        for harm_i = 1:2:channelNum-1
            temp(harm_i:harm_i+1,:) = [sin(2*pi*targ_fre(targ_i)*HarmList((harm_i+1)/2)*t);cos(2*pi*targ_fre(targ_i)*HarmList((harm_i+1)/2)*t)];
        end
        yef(:,:,targ_i) = temp;
    end
end
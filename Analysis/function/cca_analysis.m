function result = cca_analysis(data,y_ref,targ_fre,varargin)
% cca_analysis - cca��������
%
% Syntax: result = cca_analysi(data,y_ref,targ_fre[,fs,fbs_num])
%
% Long description��
% �򻯹����cca�������򣬿���ѡ��ʹ��ʹ���˲����顣���
    
%{
=========================================
Label   : ������������
-----------------------------------------
Explain : TargetNum������Ŀ��̼�Ƶ�ʵ���Ŀ
    varargin:
        1:fs������Ƶ��
        2:
          
=========================================
%}
    TargetNum = length(targ_fre);

    if ~size(varargin)
%{
=========================================
Label   : cca�����������˲�����
-----------------------------------------
Explain : 
=========================================
%}
    result=zeros(1,TargetNum);
    % ��ʼ�����
    for iTar = 1:TargetNum
        refdata = squeeze(y_ref(:,:,iTar));
        [~,~,temp] = canoncorr(data', refdata');
        result(1,iTar) = temp(1,1);
    end
%{
=========================================
Label   : cca�����������˲�����
-----------------------------------------
Explain : ��δ��ɣ���Ҫʹ��
=========================================
%}

    elseif size(varargin)
        error("filterbank����δ��ɣ���Ҫʹ�ã�");
    end

end
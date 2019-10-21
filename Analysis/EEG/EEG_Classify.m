classdef EEG_Classify < handle
    %UNTITLED �˴���ʾ�йش����ժҪ
    %   �˴���ʾ��ϸ˵��
    
    % ˽�����ԣ�Ϊ�˵��Է�����ʱ����װ
    properties (Access = public)
        % ָʾ�����ĳһ��ʵ�����õķ������ı�ţ���֤ͬһʵ���Ĳ�ͬ���ò���ʹ�ò�ͬ�ķ��෽��
        IsUsed;
        % ���෽����Ҫ��������ݳ���
        DataLength;
        % ���෽�����������
        Data;
        
    end

    % ��������
    properties(Access = public)
        % ��ʱ����
        Timers;
        % ��������
        Countors;
        % �������
        Params;

    end
    
    methods (Access = public)
        function obj = EEG_Classify
            %EEG_CLASSIFY ��������ʵ��
            %   ���������ֱ�ӵ���ʵ���Ĳ�ͬ�����Ϳ���ʵ�ֲ�ͬ�ķ��෽��
        end

        function  Clear(obj)
        %Clear - �������
        %
        % Syntax:  = Clear(obj)
        %
            obj.Timers = [];
            obj.Countors = [];
            obj.Params = [];
            obj.Data = [];
            obj.DataLength = [];
            obj.IsUsed = [];
        end

        function  AddTimer(obj,name)
        %ADDTIMER ��Ӽ�ʱ������ʱ����
        %
        % Syntax:  AddTimer(name)
        %
            if isempty(obj.Timers)
                obj.Timers(1).Name = name;
            else
                obj.Timers(end+1).Name = name;
            end
        end

        function  StartTimer(obj,name)
        %STARTTIMER - ��ʼĳһ����ʱ��
        %
        % Syntax:  = StartTimer(obj,name)
        %
            index = -1;
            for iTimer = 1:length(obj.Timers)
                if strcmp(name,obj.Timers(iTimer).Name)
                    index = iTimer;
                    break
                end
            end

            if index == -1
                error('û����Ӧ�Ķ�ʱ��')
            end

            obj.Timers(index).StartTime = tic;
        end

        function output = ReadTimer(obj,name)
        %ReadTimer - ������ʱ���ӿ�ʼ����ʱ��ֵ
        %
        % Syntax: output = ReadTimer(obj,name)
        %
            index = -1;
            for iTimer = 1:length(obj.Timers)
                if strcmp(name,obj.Timers(iTimer).Name)
                    index = iTimer;
                    break
                end
            end

            if index == -1
                error('û����Ӧ�Ķ�ʱ��')
            end

            output = toc(obj.Timers(index).StartTime);
        end

        function  ResetTimer(obj,name)
        %ResetTimer - ���ü�ʱ��
        %
        % Syntax:  = ResetTimer(obj,name)
        %
            index = -1;
            for iTimer = 1:length(obj.Timers)
                if strcmp(name,obj.Timers(iTimer).Name)
                    index = iTimer;
                    break
                end
            end

            if index == -1
                error('û����Ӧ�Ķ�ʱ��')
            end

            obj.Timers(index).StartTime = 0;
        end

        function  AddCountor(obj,name)
        %ADDCOUNTOR - ��Ӽ���������������
        %
        % Syntax:  = AddCountor(obj,name)
        %
            if isempty(obj.Countors)
                obj.Countors(1).Name = name;
                obj.Countors(1).Value = 0;
            else
                obj.Countors(end+1).Name = name;
                obj.Countors(end+1).Value = 0;
            end

            
        end

        function  CountorReset(obj,name)
        %COUNTORRESET - ������+1
        %
        % Syntax:  = CountorReset(obj,name)
        %
            index = -1;
            for iCountor = 1:length(obj.Countors)
                if strcmp(name,obj.Countors(iCountor).Name)
                    index = iCountor;
                    break
                end
            end

            if index == -1
                error('û����Ӧ�Ķ�ʱ��')
            end

            obj.Countors(index).Value = 0;
        end

        function  CountorAdd(obj,name)
        %COUNTORADD - ������+1
        %
        % Syntax:  = CountorAdd(obj,name)
        %
            index = -1;
            for iCountor = 1:length(obj.Countors)
                if strcmp(name,obj.Countors(iCountor).Name)
                    index = iCountor;
                    break
                end
            end

            if index == -1
                error('û����Ӧ�Ķ�ʱ��')
            end

            obj.Countors(index).Value = obj.Countors(index).Value + 1;
        end

        function  CountorSub(obj,name)
        %COUNTORSUB - ������-1
        %
        % Syntax:  = CountorSub(obj,name)
        %
            index = -1;
            for iCountor = 1:length(obj.Countors)
                if strcmp(name,obj.Countors(iCountor).Name)
                    index = iCountor;
                    break
                end
            end

            if index == -1
                error('û����Ӧ�Ķ�ʱ��')
            end

            obj.Countors(index).Value = obj.Countors(index).Value - 1;
        end

        function output = ReadCountor(obj,name)
        %READCOUNTOR - ����������ֵ
        %
        % Syntax: output = ReadCountor(obj,name)
        %
            index = -1;
            for iCountor = 1:length(obj.Countors)
                if strcmp(name,obj.Countors(iCountor).Name)
                    index = iCountor;
                    break
                end
            end

            if index == -1
                error('û����Ӧ�Ķ�ʱ��')
            end

            output = obj.Countors(index).Value;
        end

        function  AddParam(obj,name)
        %AddParam - ���ʵ�����
        %
        % Syntax:  AddParam(obj,name)
        %
            if isempty(obj.Params)
                obj.Params(1).Name = name;
            else
                obj.Params(end+1).Name = name;
            end
        end

        function   setParam(obj,name,value)
        %setParam - ���ò�����ֵ
        %
        % Syntax:   setParam(obj,name,value)
        %
            index = -1;
            for iParam = 1:length(obj.Params)
                if strcmp(name,obj.Params(iParam).Name)
                    index = iParam;
                    break
                end
            end

            if index == -1
                error('û����Ӧ��ʵ�����')
            end

            obj.Params(index).Value = value;
        end

        function output = getParam(obj,name)
        %getParam - ��ò�����ֵ
        %
        % Syntax: output = getParam(obj,name)
        %
            index = -1;
            for iParam = 1:length(obj.Params)
                if strcmp(name,obj.Params(iParam).Name)
                    index = iParam;
                    break
                end
            end

            if index == -1
                error('û����Ӧ��ʵ�����')
            end

            output = obj.Params(index).Value;
        end

    end

    % ��ֵ�������෨
    methods (Access = public)
        function FengZhiYanXuInit(obj, dataLength, iThreshold, lThreshold)
            %FENGZHIYANXUINIT ��ֵ�������෨��ʼ��
            %  
            % Syntax: output = obj.FengZhiYanXuInit(dataLength, iThreshold, lThreshold)
            %                                       ���ݳ���(����)��ǿ����ֵ�� �ײ���ֵ

            % ���֮ǰ������
            obj.Clear();

            obj.IsUsed = 1;

            obj.DataLength = dataLength;

            obj.AddParam('iThreshold');
            obj.setParam('iThreshold',iThreshold);

            obj.AddParam('lThreshold');
            obj.setParam('lThreshold',lThreshold);

            obj.AddParam('PreMaxIndex');
            obj.setParam('PreMaxIndex',0);

            obj.AddCountor('Countor');

        end

        function outputArg = FengZhiYanXu(obj, newData)
            %FENGZHIYANXU ��ֵ�������෨
            %   Syntax: outputArg = obj.FengZhiYanXu(newData)
            %                                        �µ��жϽ��

            if obj.IsUsed ~= 1
                error('ͬһʵ��ʹ���˲�ͬ���෽��');
            end

            % newDataת��Ϊ������
            if size(newData,1) == 1
                newData = newData';
            end

            % if size(obj.Data,2) <= obj.DataLength
            %     %Ԥ�洢�����0
            %     obj.Data = [obj.Data, [newData; mean(newData)]];
            %     obj.setParam('PreMaxIndex',0);
            %     outputArg = 0;
            %     return
            % else
            %     obj.Data(:,1:end-1) = obj.Data(:,2:end);
            %     obj.Data(:,end) = [newData; mean(newData)];
            % end

            [Max,MaxIndex] = max(newData);
            Max = Max - mean(newData);

            % Max�Ƿ�Ⱦ�ֵ���������ֵ��������������0���������������
            if Max < obj.getParam('lThreshold')
                obj.CountorReset('Countor');
                obj.setParam('PreMaxIndex',0);
                outputArg = 0;
                return
            end

            % ͳ��ĳĿ���������ִ���
            PreMaxIndex = obj.getParam('PreMaxIndex');
            obj.setParam('PreMaxIndex',MaxIndex);

            if PreMaxIndex ~= MaxIndex
                obj.CountorReset('Countor');
            else
                obj.CountorAdd('Countor');
            end

            % Max����Ѿ�����ǿ����ֱֵ��������
            if Max >= obj.getParam('iThreshold') && obj.ReadCountor('Countor') >= 0.5*obj.DataLength
                obj.setParam('PreMaxIndex',MaxIndex);
                outputArg = MaxIndex;
                return
            end

            % ����ʼ�ж��Ƿ������������
            if obj.ReadCountor('Countor') >= obj.DataLength-1
                outputArg = MaxIndex;
            else
                outputArg = 0;
            end
        end
    end
end


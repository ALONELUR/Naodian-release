classdef EEG_Classify < handle
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    % 私有属性，为了调试方便暂时不封装
    properties (Access = public)
        % 指示该类的某一个实例调用的分类器的编号，保证同一实例的不同调用不能使用不同的分类方法
        IsUsed;
        % 分类方法需要缓存的数据长度
        DataLength;
        % 分类方法缓存的数据
        Data;
        
    end

    % 共有属性
    properties(Access = public)
        % 计时器组
        Timers;
        % 计数器组
        Countors;
        % 分类参数
        Params;

    end
    
    methods (Access = public)
        function obj = EEG_Classify
            %EEG_CLASSIFY 构造此类的实例
            %   无需参数，直接调用实例的不同函数就可以实现不同的分类方法
        end

        function  Clear(obj)
        %Clear - 清空数据
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
        %ADDTIMER 添加计时器到计时器组
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
        %STARTTIMER - 开始某一个定时器
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
                error('没有相应的定时器')
            end

            obj.Timers(index).StartTime = tic;
        end

        function output = ReadTimer(obj,name)
        %ReadTimer - 读出定时器从开始到此时的值
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
                error('没有相应的定时器')
            end

            output = toc(obj.Timers(index).StartTime);
        end

        function  ResetTimer(obj,name)
        %ResetTimer - 重置计时器
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
                error('没有相应的定时器')
            end

            obj.Timers(index).StartTime = 0;
        end

        function  AddCountor(obj,name)
        %ADDCOUNTOR - 添加计数器到计数器组
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
        %COUNTORRESET - 计数器+1
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
                error('没有相应的定时器')
            end

            obj.Countors(index).Value = 0;
        end

        function  CountorAdd(obj,name)
        %COUNTORADD - 计数器+1
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
                error('没有相应的定时器')
            end

            obj.Countors(index).Value = obj.Countors(index).Value + 1;
        end

        function  CountorSub(obj,name)
        %COUNTORSUB - 计数器-1
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
                error('没有相应的定时器')
            end

            obj.Countors(index).Value = obj.Countors(index).Value - 1;
        end

        function output = ReadCountor(obj,name)
        %READCOUNTOR - 读计数器的值
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
                error('没有相应的定时器')
            end

            output = obj.Countors(index).Value;
        end

        function  AddParam(obj,name)
        %AddParam - 添加实验参数
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
        %setParam - 设置参数的值
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
                error('没有相应的实验参数')
            end

            obj.Params(index).Value = value;
        end

        function output = getParam(obj,name)
        %getParam - 获得参数的值
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
                error('没有相应的实验参数')
            end

            output = obj.Params(index).Value;
        end

    end

    % 峰值延续分类法
    methods (Access = public)
        function FengZhiYanXuInit(obj, dataLength, iThreshold, lThreshold)
            %FENGZHIYANXUINIT 峰值延续分类法初始化
            %  
            % Syntax: output = obj.FengZhiYanXuInit(dataLength, iThreshold, lThreshold)
            %                                       数据长度(个数)，强度阈值， 底部阈值

            % 清空之前的数据
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
            %FENGZHIYANXU 峰值延续分类法
            %   Syntax: outputArg = obj.FengZhiYanXu(newData)
            %                                        新的判断结果

            if obj.IsUsed ~= 1
                error('同一实例使用了不同分类方法');
            end

            % newData转置为列向量
            if size(newData,1) == 1
                newData = newData';
            end

            % if size(obj.Data,2) <= obj.DataLength
            %     %预存储，输出0
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

            % Max是否比均值高于最低阈值，如果低于则输出0，并且置零计数器
            if Max < obj.getParam('lThreshold')
                obj.CountorReset('Countor');
                obj.setParam('PreMaxIndex',0);
                outputArg = 0;
                return
            end

            % 统计某目标连续出现次数
            PreMaxIndex = obj.getParam('PreMaxIndex');
            obj.setParam('PreMaxIndex',MaxIndex);

            if PreMaxIndex ~= MaxIndex
                obj.CountorReset('Countor');
            else
                obj.CountorAdd('Countor');
            end

            % Max如果已经高于强度阈值直接输出结果
            if Max >= obj.getParam('iThreshold') && obj.ReadCountor('Countor') >= 0.5*obj.DataLength
                obj.setParam('PreMaxIndex',MaxIndex);
                outputArg = MaxIndex;
                return
            end

            % 否则开始判断是否满足连续输出
            if obj.ReadCountor('Countor') >= obj.DataLength-1
                outputArg = MaxIndex;
            else
                outputArg = 0;
            end
        end
    end
end


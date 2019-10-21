classdef  EEG_Com < handle

    properties 
        CallBackMap = containers.Map;
        TriggerMap =  containers.Map;
    end

    methods 
        function obj = EEG_Com()
            
        end

        function delete(obj)
        %delete - 析构函数
        %
        % Syntax:  = delete(obj)
        %
            delete(obj);
        end
    end
end
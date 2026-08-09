
classdef dataReceiver < handle
    methods (Abstract)
        open(obj, params) %[N x 5] mátrix.
        dataMatrix = readData(obj)
        close(obj)
    end
end
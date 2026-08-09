% Leírás
% A fügvény egy 3D test csúcsait és oldalait adja vissza

function [V, F] = boxGeometry(dimension)
    
    % Méretei
    lenght = dimension(1)/2;    % X tengely
    width = dimension(2)/2;     % Y tengely
    height = dimension(3)/2;    % Z tengely
    
    % Lokális csúcsok
    V = [
        -lenght -width -height;
        lenght -width -height;
        lenght width -height;
        -lenght width -height;
        -lenght -width height;
        lenght -width height;
        lenght width height;
        -lenght width height
    ];
    
    % Oldalak
    F = [
        1 2 3 4;   % Hátsó oldal
        5 6 7 8;   % Elülső oldal
        1 2 6 5;   % Alsó oldal
        2 3 7 6;   % Bal oldal
        3 4 8 7;   % Felső oldal
        4 1 5 8    % Jobb oldal
    ];
end
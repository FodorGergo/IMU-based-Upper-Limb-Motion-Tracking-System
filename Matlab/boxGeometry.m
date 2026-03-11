% Leírás
% A fügvény egy 3D test csúcsait és oldalait adja vissza

function [V, F] = boxGeometry(dimension)
    
    % Méretei
    size_x = dimension(1)/2;
    size_y = dimension(2)/2;
    size_z = dimension(3)/2;
    
    % Lokális csúcsok
    V = [
        -size_x -size_y -size_z;
        size_x -size_y -size_z;
        size_x size_y -size_z;
        -size_x size_y -size_z;
        -size_x -size_y size_z;
        size_x -size_y size_z;
        size_x size_y size_z;
        -size_x size_y size_z
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

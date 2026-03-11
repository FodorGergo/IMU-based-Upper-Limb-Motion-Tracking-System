function R_out = clampJointRotation(R_in, jointType)
    % Leírás: Ízületi szöghatárok  alkalmazása
    
    %% Euler szögek 
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX'));
    szog_Z = eul_deg(1);  % Z-tengely körüli forgás (Flexió / Extenzió)
    szog_Y = eul_deg(2);  % Y-tengely körüli forgás (Abdukció / Addukció)
    szog_X = eul_deg(3);  % X-tengely körüli forgás (Kirotáció / Berotáció)
    
    %% Szöghatárok 
    if strcmp(jointType, 'shoulder')
        
        % Határok
        Z_MAX = 150; Z_MIN = -50;  
        Y_MAX = 180; Y_MIN = -50;  
        X_MAX = 90;  X_MIN = -70;  
        
        % Korlátozás (Clamp)
        szog_Z = max(Z_MIN, min(Z_MAX, szog_Z));
        szog_Y = max(Y_MIN, min(Y_MAX, szog_Y));
        szog_X = max(X_MIN, min(X_MAX, szog_X));
    end
    
    %% Visszakonvertálás forgatási mátrixszá
    clamped_eul_rad = deg2rad([szog_Z, szog_Y, szog_X]);
    R_out = eul2rotm(clamped_eul_rad, 'ZYX');
end
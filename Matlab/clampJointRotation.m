function R_out = clampJointRotation(R_in, jointType)
    % Leírás

    %% Euler szögek
    % ZYX
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX'));
    yaw_Z   = eul_deg(1);  % Z (Abdukció)
    roll_Y  = eul_deg(2);  % Y (Rotáció)
    pitch_X = eul_deg(3);  % X (Flexió)

    %% Szöghatárok
    % Váll
    if strcmp(jointType, 'shoulder')
        % Még nem 100%-os értékek
        Z_MAX = 180; Z_MIN = -50;  % Kar emelése oldalra (Abdukció)
        Y_MAX = 90;  Y_MIN = -70;  % Kar csavarása (Kirotáció / Berotáció)
        X_MAX = 150; X_MIN = -50;  % Kar emelése előre/hátra (Flexió / Extenzió)

        yaw_Z   = max(Z_MIN, min(Z_MAX, yaw_Z));
        roll_Y  = max(Y_MIN, min(Y_MAX, roll_Y));
        pitch_X = max(X_MIN, min(X_MAX, pitch_X));
    end

    %% Konvertálás forgatási mátrixá
    clamped_eul_rad = deg2rad([yaw_Z, roll_Y, pitch_X]);
    R_out = eul2rotm(clamped_eul_rad, 'ZYX');
end
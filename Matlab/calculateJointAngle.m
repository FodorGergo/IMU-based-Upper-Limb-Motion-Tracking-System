% Leírás: Kiszámolja két test (ízület) által bezárt valós térszöget skaláris szorzattal
function angle_deg = calculateJointAngle(R_parent, R_child)
    % Irányvektorok kinyerése (X tengely)
    v_parent = R_parent(:, 1); 
    v_child  = R_child(:, 1); 
    
    % Skaláris szorzat számítása
    cos_theta = dot(v_parent, v_child);
    
    % Számítási pontatlanságokból eredő hibák (lebegőpontos túlcsordulás) kivédése
    cos_theta = max(-1, min(1, cos_theta));
    
    % Visszatérés a fokkal
    angle_deg = real(rad2deg(acos(cos_theta)));
end
function switchMode(dropdown, gridParent)
    mode = dropdown.Value;
    
    % Megkeressük a gyerek elemeket a rácsban
    children = gridParent.Children;
    
    if strcmp(mode, 'Soros port')
        % Soros módnál: SerialGroup ON, WifiGroup OFF
        for i = 1:length(children)
            if strcmp(children(i).Tag, 'SerialGroup')
                children(i).Visible = 'on';
            elseif strcmp(children(i).Tag, 'WifiGroup')
                children(i).Visible = 'off';
            end
        end
    else
        % Wifi módnál: WifiGroup ON, SerialGroup OFF
        for i = 1:length(children)
            if strcmp(children(i).Tag, 'WifiGroup')
                children(i).Visible = 'on';
            elseif strcmp(children(i).Tag, 'SerialGroup')
                children(i).Visible = 'off';
            end
        end
    end
end
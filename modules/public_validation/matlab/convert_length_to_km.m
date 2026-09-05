function x = convert_length_to_km(value,unit)
%CONVERT_LENGTH_TO_KM Convert route/run length to kilometres.
x = double(value); u = lower(strtrim(char(string(unit))));
if strcmp(u,'mm') || contains(u,'millimeter') || contains(u,'millimetre')
    x = x/1e6;
elseif strcmp(u,'cm') || contains(u,'centimeter') || contains(u,'centimetre')
    x = x/1e5;
elseif isempty(u) || strcmp(u,'km') || contains(u,'kilometer') || contains(u,'kilometre')
    return;
elseif strcmp(u,'m') || contains(u,'meter') || contains(u,'metre')
    x = x/1000;
elseif strcmp(u,'mi') || contains(u,'mile')
    x = x*1.609344;
elseif strcmp(u,'ft') || contains(u,'feet') || contains(u,'foot')
    x = x*0.0003048;
else
    warning('Unknown length unit "%s"; treating as kilometres.',u);
end
end

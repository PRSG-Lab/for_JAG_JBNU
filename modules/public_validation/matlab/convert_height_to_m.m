function x = convert_height_to_m(value,unit)
%CONVERT_HEIGHT_TO_M Convert a height difference to metres.
x = double(value); u = lower(strtrim(char(string(unit))));
if strcmp(u,'mm') || contains(u,'millimeter') || contains(u,'millimetre')
    x = x/1000;
elseif strcmp(u,'cm') || contains(u,'centimeter') || contains(u,'centimetre')
    x = x/100;
elseif isempty(u) || strcmp(u,'m') || contains(u,'meter') || contains(u,'metre')
    return;
elseif strcmp(u,'ft') || contains(u,'feet') || contains(u,'foot')
    x = x*0.3048;
else
    warning('Unknown height unit "%s"; treating as metres.',u);
end
end

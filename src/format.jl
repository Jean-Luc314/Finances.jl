# COMBAK: format() does not work as intended for large numers (scientific notation)
function format(prefix :: String = "", suffix :: String = "", digits :: Integer = 1, scale :: Real = 1, delim :: String = ",") :: Function
    int_round(x, r) = r ? Int(x) : x
    x -> prefix * replace(string(int_round(round(x * scale, digits = digits), digits == 0)), r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => delim) * suffix
end
function format(c :: Currency, digits = 2, delim = ",", prepend_cur :: Bool = true) :: Function
    cur = string(get_cur(c))
    if prepend_cur
        format(cur, "", digits, 1, delim)
    else
        format("", cur, digits, 1, delim)
    end
end
export format
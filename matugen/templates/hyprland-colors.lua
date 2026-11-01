-- Generated with Matugen — do not edit by hand
return {
<* for name, value in colors *>
    {{name}} = "0xff{{value.default.hex_stripped}}",
<* endfor *>
}

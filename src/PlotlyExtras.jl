module PlotlyExtras

using JSON 

export to_html

const CDN = """    <script src="https://cdn.plot.ly/plotly-2.20.0.min.js" charset="utf-8"></script>"""
const LOCAL = "    <script src='plotly-2.20.0.min.js'></script>"

f_helper(x) = x
f_helper(d::Dict) = Dict(Symbol(k) => f_helper(v) for (k, v) in d)
symbol_dict(d::Dict) = f_helper(d)

function getlayout(template)
    io = open(template, "r")
    s = read(io) |> String
    temp = JSON.parse(s)
    close(io)

    symbol_dict(temp)
end

function to_html(file, plots; template="plotly_white.json", use_CDN = true)
    io = open("tmp.html", "w")
    header = (use_CDN == true) ? CDN : LOCAL

    print(
        io,
        """
<!DOCTYPE html>
<html>

<head>
    $(header)
    <meta name="viewport" content="width=device-width, initial-scale=1">
</head>

<body>
""")
    ids = map(x -> split(string(x.divid), "-")[1], plots)

    map(plots, ids) do p, i
        print(io, """    <div id="$i"></div>\n""")
    end
    print(io, "    <script>")
    map(plots, ids) do p, i
        js = JSON.lower(p)
        setindex!(js[:config], false, :displayModeBar)

        print(io, "\n")
        print(io, "        const data_$(i) = $(json(js[:data]))")
        print(io, "\n")
        print(io, "        const layout_$(i) = $(json(js[:layout]))")
        print(io, "\n")
        print(io, "        const config_$(i) = $(json(js[:config]))")
        print(io, "\n")
    end

    print(io, "\n")

    map(plots, ids) do p, i
        print(io, """        Plotly.newPlot("$i", data_$i, layout_$i, config_$i)\n""")
    end
    print(io, "\n")
    print(io, "    </script>\n   </body>\n</html>")
    close(io)

    cp("tmp.html", file; force=true)
end

end 

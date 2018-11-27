package.cpath = package.cpath .. ";../bin/?.so" .. ";../bin/?.dylib"
package.path = package.path .. ";../bin/?.lua"

function printheader(name)
    print("----- Testing " .. name .. " -----")
end

function printok()
    print("----- Ok")
end

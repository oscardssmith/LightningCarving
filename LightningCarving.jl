using Images

@views function carve_seam(data)
    T = typeof(data)
    data[:, 1] .= Inf
    data[:, end] .= Inf
    for i in 2:size(data, 1)
        for j in 2:size(data, 2)-1
            data[i, j] += min(data[i-1, j-1], data[i-1, j], data[i-1, j+1])
        end
    end
    seam = argmin(data[end, :])
    for i in size(data,1):-1:1
        seam += argmin((data[i, seam-1], data[i, seam], data[i, seam+1])) - 2
        data[i, begin:(seam-1)] .= 0
        data[i, seam] = 1
        data[i, (seam+1):end] .= 0
    end
    return data
end

n = 1000
init = rand(UInt8, n, n)'
carve_seam(init)


light_color = RGB{N0f8}((0xBB,0xC8,0xD6)./256...)
base_color = RGB{N0f8}((0x06,0x0F,0x3B)./256...)

im = fill(base_color, n, n)
im .+= (light_color-base_color).*(init.>0)

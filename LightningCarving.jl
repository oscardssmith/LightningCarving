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

function make_lightning(width, height)
    init = rand(width, height)'
    carve_seam(init)
    light_color = RGB{N0f8}(0.729,0.78,0.835)
    base_color = RGB{N0f8}(0.024,0.059,0.231)

    img = fill(base_color, height, width)
    img .+= (light_color-base_color).*(init.>0)
    return img
end

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

const base_color = RGB{N0f8}(0.024,0.059,0.231)
const light_color = RGB{N0f8}(0.729,0.78,0.835)

draw_empty(width, height) = fill(base_color, width, height)
function draw_lightning(width, height, start_pt, end_pts)
    noise = rand(width, height)'
    noise[reverse(start_pt)...] = -100_000
    bolts = zeros(width, height)'
    for end_pt in end_pts
        row_bounds = start_pt[2]:end_pt[2]
        tmp_noise = copy(noise[row_bounds, :])
        tmp_noise[end, end_pt[1]] = -100_000
        carve_seam(tmp_noise)
        bolts[row_bounds, :] .+= tmp_noise
        noise[row_bounds, :] .-= .05*tmp_noise
    end

    img = draw_empty(width, height)
    img .+= (light_color-base_color).*(bolts'.>0)
    return img[end:-1:begin, :]
end

using Images

function argranddiff(strength, args)
    return argmin(args .+ strength .* rand.()) - (length(args)+1) ÷ 2
end

function compute_costs(data)
    T = typeof(data)
    data[:, 1] .= Inf
    data[:, end] .= Inf
    for i in size(data, 1)-1:-1:1
        for j in 2:size(data, 2)-1
            data[i, j] += min(data[i+1, j-1], data[i+1, j], data[i+1, j+1])
        end
    end
    return data
end

function carve_seam(data, start_pt)
    pty, startx = start_pt
    output = zeros(reverse(size(data))...)'
    bolts = Set{Int}(startx)
    new_bolts = Set{Int}()
    while !isempty(bolts)
        empty!(new_bolts)
        for ptx in bolts
            if data[pty, ptx] > 0
                continue
            end
            output[pty, ptx] = 1
            newx = ptx + argranddiff(20, (data[pty, ptx-1], data[pty, ptx], data[pty, ptx+1]))
            if rand() < pty^2*1e-7
                newdx = argmin((data[pty, newx-1], data[pty, newx+1]))*2 - 3
                push!(new_bolts, newx + newdx)
            end
            push!(new_bolts, newx)
        end
        pty += 1
        bolts, new_bolts = new_bolts, bolts
    end
    return output
end

const base_color = RGB{N0f8}(0.024,0.059,0.231)
const light_color = RGB{N0f8}(0.729,0.78,0.835)

draw_empty(width, height) = fill(base_color, width, height)
function draw_lightning(width, height, start_pt, end_pts)
    start_pt = reverse(start_pt)
    end_pts = reverse.(end_pts)
    noise = rand(width, height)'
    
    for end_pt in end_pts
        noise[end_pt...] = -100_000
    end
    compute_costs(noise)
    #display(heatmap(noise))
    #return draw_empty(width, height)
    bolts = carve_seam(noise, start_pt)

    img = draw_empty(width, height)
    img .+= (light_color-base_color).*(bolts'.>0)
    return img[:, end:-1:begin]
end

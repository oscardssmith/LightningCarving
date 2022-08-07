using GLFW
using ModernGL
using Images

include("util.jl")
include("LightningCarving.jl")

function make_window(width=500, height=1000)
    GLFW.Init()

    window = GLFW.CreateWindow(width, height, "GLFW.jl")

    GLFW.MakeContextCurrent(window)
    GLFW.ShowWindow(window)
    GLFW.SetWindowSize(window, width, height)
    GLFW.SwapInterval(1)
    glViewport(0, 0, width, height)
    return window
end

function make_square_and_shader()
    createcontextinfo()
    # The data for our triangle
    data = GLfloat[
        -1.0, -1.0,     0.0, 0.0,
        1.0, -1.0,      1.0, 0.0,
        1.0,1.0,        1.0, 1.0,
        -1.0, -1.0,       0.0, 0.0,
        -1.0, 1.0,      0.0, 1.0,
        1.0, 1.0,     1.0, 1.0,
    ]

    # Generate a vertex array and array buffer for our data
    vao = glGenVertexArray()
    glBindVertexArray(vao)
    vbo = glGenBuffer()
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW)
    
    vsh = """
    $(get_glsl_version_string())
    in vec2 position;
    in vec2 texcoord;

    out vec2 tex;
    void main() {
        gl_Position = vec4(position, 0.0, 1.0);
        tex = texcoord;
    }
    """
    fsh = """
    $(get_glsl_version_string())
    in vec2 tex;

    uniform sampler2D ourTexture;
    out vec4 outColor;
    void main() {
        outColor = texture(ourTexture, tex);
    }
    """
    vertexShader = createShader(vsh, GL_VERTEX_SHADER)
    fragmentShader = createShader(fsh, GL_FRAGMENT_SHADER)
    program = createShaderProgram(vertexShader, fragmentShader)
    glUseProgram(program)
    positionAttribute = glGetAttribLocation(program, "position");
    textureAttribute = glGetAttribLocation(program, "texcoord");
    glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, false, 4*sizeof(GLfloat), C_NULL)
    glVertexAttribPointer(textureAttribute, 2, GL_FLOAT, false, 4*sizeof(GLfloat), C_NULL+2*sizeof(GLfloat))
    glEnableVertexAttribArray(positionAttribute)
    glEnableVertexAttribArray(textureAttribute)
    return nothing
end

function initialize_texture()
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    return glGenTexture()
end

@Base.kwdef mutable struct LightningState
    startpoint::Tuple{Int,Int} = (0,0)
    endpoints::Vector{Tuple{Int, Int}} = Tuple{Int, Int}[]
    mouse_down::Bool = false
end


function make_mouse_button_callback(state::LightningState)
    return function mouse_button_callback(window, button, action, mods)
        println(action)
        println(button)
        if button == GLFW.MOUSE_BUTTON_LEFT
            if action == GLFW.PRESS
                state.mouse_down = true
            end
            if action == GLFW.RELEASE
                state.mouse_down = false
            end
        end
        if button == GLFW.MOUSE_BUTTON_RIGHT
            if action == GLFW.PRESS
                coords = GLFW.GetCursorPos(window)
                push!(state.endpoints, (round.(Int, coords.x), round.(Int, coords.y)))
            end
        end
    end
end

function compute_frame(state, width, height)
    if isempty(state.endpoints) || !state.mouse_down
        return draw_empty(width,height)
    end
    return draw_lightning(width, height, state.startpoint, state.endpoints)
end

function bind_matrix_to_texture(matrix::Matrix{RGB{N0f8}}, texture_addr)
    glBindTexture(GL_TEXTURE_2D, texture_addr);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, size(matrix)..., 0, GL_RGB, GL_UNSIGNED_BYTE, matrix);
    glGenerateMipmap(GL_TEXTURE_2D);
end

function render(compute_frame, width=500, height=1000)
    window = make_window(width, height)
    try
        make_square_and_shader()
        texture_addr = initialize_texture()
        state = LightningState()
        GLFW.SetMouseButtonCallback(window, make_mouse_button_callback(state));

        # Loop until the user closes the window
        while !GLFW.WindowShouldClose(window)
            # Render here
            glClearColor(0.024, 0.059, 0.231, 1.0)
            glClear(GL_COLOR_BUFFER_BIT)
            coords = GLFW.GetCursorPos(window)
            state.startpoint = (round.(Int, coords.x), round.(Int, coords.y))
            frame = compute_frame(state, width, height)
            bind_matrix_to_texture(frame, texture_addr)

            # Draw our triangle
            glDrawArrays(GL_TRIANGLES, 0, 6)
            # Swap front and back buffers
            GLFW.SwapBuffers(window)

            # Poll for and process events
            GLFW.PollEvents()
        end
    finally
        GLFW.DestroyWindow(window)
    end
end

render(compute_frame, 500, 1000)

import GLFW
using ModernGL

include("util.jl")
include("LightningCarving.jl")


GLFW.Init()
width =500
height =1000

window = GLFW.CreateWindow(width, height, "GLFW.jl")

GLFW.MakeContextCurrent(window)
GLFW.ShowWindow(window)
GLFW.SetWindowSize(window, width, height)
GLFW.SwapInterval(1)
glViewport(0, 0, width, height)
println(createcontextinfo())
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


glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
texture = glGenTexture()

# Create and initialize shaders
const vsh = """
$(get_glsl_version_string())
in vec2 position;
in vec2 texcoord;

out vec2 tex;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    tex = texcoord;
}
"""
const fsh = """
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

# Loop until the user closes the window


i=0
mouse_coords = (0,0)
mouse_down = false
#push!(a, (5,6))

endpoints = Tuple{Int, Int}[]

function mouse_button_callback(window, button, action, mods)
    global mouse_down
    global endpoints
    println(action)
    println(button)
    if button == GLFW.MOUSE_BUTTON_LEFT
        if action == GLFW.PRESS
            println("left click")
            mouse_down = true
        end
        if action == GLFW.RELEASE
            println("released")
            mouse_down = false
        end
    end
    if button == GLFW.MOUSE_BUTTON_RIGHT
        if action == GLFW.PRESS
            println("right click")
            coords = GLFW.GetCursorPos(window)

            push!(endpoints, (Int(coords.x), Int(coords.y)))
        end
    end

end

GLFW.SetMouseButtonCallback(window, mouse_button_callback);

while !GLFW.WindowShouldClose(window)
    global i += 1
    global endpoints
    global mouse_down
	# Render here
	glClearColor(0.024, 0.059, 0.231, 1.0)
	glClear(GL_COLOR_BUFFER_BIT)

    #lightning_points = Tuple{Int, Int}[]
    #push!(lightning_points, mouse_coords)
    @show mouse_down, endpoints
    if mouse_down && !isempty(endpoints)
        coords = GLFW.GetCursorPos(window)
        startpoint = (Int(coords.x), Int(coords.y))
        lightning = draw_lightning(width, height, startpoint, endpoints)
    else
        lightning = draw_empty(width,height)
    end
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, lightning);
    glGenerateMipmap(GL_TEXTURE_2D);

	# Draw our triangle
	glDrawArrays(GL_TRIANGLES, 0, 6)
	# Swap front and back buffers
	GLFW.SwapBuffers(window)

	# Poll for and process events
	GLFW.PollEvents()
end

GLFW.DestroyWindow(window)

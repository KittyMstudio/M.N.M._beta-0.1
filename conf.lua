function love.conf(t)
    t.window.title = "M.N.M."
    t.window.width = 800
    t.window.height = 600
    -- Setează filtrul implicit la "nearest" pentru a evita orice blur
    t.window.minstear = "nearest"
    t.window.magstear = "nearest"
    t.window.vsync = true
end

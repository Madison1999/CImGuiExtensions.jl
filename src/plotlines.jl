struct PlotlinesModel{T₁ <: AbstractVector} <: AbstractModel
    data::T₁
end

mutable struct PlotlinesControl <: AbstractControl
    isenabled::Bool
end

struct PlotContext{T₁ <: AbstractControl,   T₂ <: AbstractModel,  T₃ <: AbstractDisplayProperties} <: AbstractPlotContext
    control::T₁
    model::T₂
    display_properties::T₃
end

function (context::PlotContext{<: PlotlinesControl,   <: PlotlinesModel,  <: PlotlinesDisplayProperties})()
        control = context.control
        model = context.model
        display_properties = context.display_properties
        CImGui.Begin("Main",C_NULL, CImGui.ImGuiWindowFlags_NoBringToFrontOnFocus)
            isenabled(control) ? control(model, display_properties) : nothing
        CImGui.End()
end

function get_data(model::PlotlinesModel)
    model.data
end

function (control::PlotlinesControl)(model::PlotlinesModel, properties::PlotlinesDisplayProperties)
    id = get_id(properties)
    caption = get_caption(properties)
    col = get_col(properties)
    rectangle = get_layout(properties)
    pos = get_pos(rectangle)
    totalwidth = get_width(rectangle)
    totalheight = get_height(rectangle)
    padding = get_padding(properties)
    data = get_data(model)
    #CImGui.SetCursorPos(pos.x + padding[2], pos.y + padding[1])
    CImGui.Dummy(ImVec2(0, padding[1]))
    CImGui.Indent(padding[2])
    width = totalwidth - padding[2]
    height = totalheight
    CImGui.PlotLines(id, data , length(data), 0 , caption, minimum(data), maximum(data), (width, height))
    draw_horizontal_ticks(data, width, height, get_ytick(properties))
    draw_vertical_ticks(data, width, height, get_xtick(properties))
end

function draw_vertical_ticks(data, width, height, tick::Tickmark)
    if isenabled(tick)
        # Draw the x-axis
        draw_list = CImGui.GetWindowDrawList()
        black = Base.convert(ImU32, ImVec4(0,0, 0, 1))
        pos = CImGui.GetCursorScreenPos()
        CImGui.AddLine(draw_list, pos, ImVec2(pos.x + width, pos.y), black, get_thickness(tick));
        # Draw the concomitant tick marks.
        x = pos.x
        y = pos.y
        interpret = get_interpreter(tick)
        for xₙ in range(x, stop = x + width; length = floor(Int, width / get_spacing(tick)) )
            # This line represents the tick mark.
            CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y + get_length(tick)), black, get_thickness(tick)) #TODO add tick direction
            # Display value associated with that tickmark
            index = round(Int,stretch_linearly(xₙ, x,  x + width, 1, length(data)))
            # Convert the raw data to a text description after applying the
            # transformation associated with the value2text function.
            str = string(interpret(index))
            xoffset = div(length(str) * CImGui.GetFontSize(), 4)
            yoffset = get_length(tick) + 2
            CImGui.AddText(draw_list, ImVec2(xₙ - xoffset, y + yoffset), black, "$str",);
        end
    end
end

function draw_horizontal_ticks(data, width, height, tick::Tickmark)

    if isenabled(tick)
        draw_list = CImGui.GetWindowDrawList()
        black = Base.convert(ImU32, ImVec4(0,0, 0, 1))
        pos = CImGui.GetCursorScreenPos()
        # Draw the y-axis
        CImGui.AddLine(draw_list, pos, ImVec2(pos.x, pos.y - height), black, get_thickness(tick));
        minval = minimum(data)
        maxval = maximum(data)
        # Draw the concomitant tick marks.
        x = pos.x
        y = pos.y
        interpret = get_interpreter(tick)
        # TODO: Perhaps better to iterate over bonafide values and round pixel coordinates?
        for yₙ in range(y - height, stop = y; length = floor(Int, height / get_spacing(tick)))
            # This line represents the tick mark.
            CImGui.AddLine(draw_list, ImVec2(x, yₙ), ImVec2(x - get_length(tick), yₙ), black, get_thickness(tick)); #TODO add tick direction
            # Display value associated with that tickmark
            val = round(Int,stretch_linearly(yₙ, y,  y - height, minval, maxval))
            # Convert the raw data to a text description after applying the
            # transformation associated with the value2text function.
            str = string(interpret(val))
            xoffset = get_length(tick) + 3 + div(length(str) * CImGui.GetFontSize(), 2)
            yoffset = div(CImGui.GetFontSize(), 2)
            CImGui.AddText(draw_list, ImVec2(x - xoffset, yₙ - yoffset), black, "$str",);
        end
    end
end

function stretch_linearly(x, A, B, a, b)
    (x-A) * ((b-a) / (B-A)) + a
end

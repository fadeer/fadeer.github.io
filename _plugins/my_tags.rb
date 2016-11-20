class MyImageTag < Liquid::Tag
  def initialize(tag_name, params, tokens)
    super
    @params = params
  end

  def render(context)
    base="http://7xkxri.com1.z0.glb.clouddn.com/"
    params = split_params(@params)
    image=params[0].strip
    inames = image.split(".")
    iname = inames[0].strip
    itype = inames[1].strip

    html =  "<picture> "
    html += "<img "
    html += "src=\"#{base}#{image}\" alt=\"#{image}\" "
    html += "srcset=\" "
    html += "#{base}#{iname}-s.#{itype} 400w, "
    html += "#{base}#{iname}-m.#{itype} 800w, "
    html += "#{base}#{iname}-l.#{itype} 1000w, "
    html += "\"/>"
    html += "</picture>"

    return html;
  end

  def split_params(params)
    params.split("|")
  end
end
Liquid::Template.register_tag('my_image', MyImageTag)

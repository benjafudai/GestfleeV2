# Attachables for Active Storage. The content type is detected from the bytes,
# so each one starts with the real file signature.
module FileHelpers
  def pdf_file(filename = "documento.pdf")
    { io: StringIO.new("%PDF-1.4\n%%EOF\n"), filename: filename, content_type: "application/pdf" }
  end

  def png_file(filename = "foto.png")
    { io: StringIO.new("\x89PNG\r\n\x1A\n".b + ("\x00".b * 32)), filename: filename, content_type: "image/png" }
  end

  def text_file(filename = "notas.txt")
    { io: StringIO.new("solo texto"), filename: filename, content_type: "text/plain" }
  end
end

RSpec.configure do |config|
  config.include FileHelpers
end

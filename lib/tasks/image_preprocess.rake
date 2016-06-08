require 'rmagick'

namespace :project do
  namespace :marriages do 
  
  
    ENTRIES_PER_PAGE=50
    HEADER_PROPORTION=0.075 #experimentation shows that the top 7% of the page is the pre-printed header
    FOOTER_PROPORTION=0.001 
  
  
    def draw_rectangle(image,start_x,start_y,width,height)
      end_x = start_x+width
      end_y = start_y+height
      gc = Magick::Draw.new
      
      gc.stroke('blue')
      gc.stroke_width(1)
    
      # top line
      gc.line(start_x, start_y, end_x, start_y)
      # bottom line
      gc.line(start_x, end_y, end_x, end_y)
      # left line
      gc.line(start_x, start_y, start_x, end_y) 
      # right line
      gc.line(end_x, start_y, end_x, end_y)
  
      gc.draw(image)
    end
  
  
    # identifies rectangles for one page
    def find_entry_rectangles(x_offset,y_offset,page_width,page_height)  # take offset
      # how big is the header?
      header_height = page_height * HEADER_PROPORTION
      footer_height = page_height * FOOTER_PROPORTION
      entry_height = (page_height - header_height - footer_height) / ENTRIES_PER_PAGE
  
      entries = []
      ENTRIES_PER_PAGE.times do |i|
        entry_y = y_offset + header_height + entry_height*i
        slop_entry_y = entry_y - entry_height * 0.1
        slop_entry_height = entry_height * 0.2
        entries << [x_offset,slop_entry_y,page_width,slop_entry_height]
      end    
      entries
    end
  
   
  
    def draw_entry_rectangles(image_file, entry_rectangles)
      image = Magick::ImageList.new(image_file).first
  
      entry_rectangles.each do |rectangle|
        draw_rectangle(image, rectangle[0],rectangle[1],rectangle[2],rectangle[3])      
      end
      
      ext = File.extname(image_file)
      out_filename = File.basename(image_file.sub(ext, ".entries"+ext))
      image.write(out_filename)
    end
  
  
  
  
  
    desc "Draw rectangles on a local image to demonstrate entry locations"
    task :draw_rectangles, [:image_file,:page_x,:page_y,:page_w,:page_h] => :environment do |task, args|
      if args.count != 5
        print "\n\nUsage: rake project:marriages:draw_rectangles[image_file,page_x,page_y,page_w,page_h]\n"
        print "\nimage_file: local copy of a marriage application index image\n"
        print "page_x: x coordinate of upper-left corner of the index page\n"
        print "page_y: y coordinate of upper-left corner of the index page\n"
        print "page_w: width of an index page\n"
        print "page_h: height of an index page\n"
        print "\nexample:\nrake project:marriages:draw_rectangles[../images/brooklyn_1929_p1111.jpg,190,80,560,875]\n"
        exit
      end
      draw_entry_rectangles(args[:image_file], find_entry_rectangles(args[:page_x],args[:page_y],args[:page_w],args[:page_h]))
    end

        
    
  
  end  

end

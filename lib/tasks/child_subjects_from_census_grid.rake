require 'rmagick'

namespace :project do
  namespace :freecen do 
  
  
    CENSUS_ENTRIES_PER_PAGE=31
    CENSUS_HEADER_PROPORTION=0.178 #experimentation shows that the top 7% of the page is the pre-printed header
    CENSUS_FOOTER_PROPORTION=0.050 
  
  
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
  
  
    VERTICAL_SLOP = 0.4
    # identifies rectangles for one column
    def find_entry_rectangles(x_offset,y_offset,column_width,page_height)  # take offset
      # how big is the header?
      header_height = page_height * CENSUS_HEADER_PROPORTION
      footer_height = page_height * CENSUS_FOOTER_PROPORTION
      entry_height = (page_height - header_height - footer_height) / CENSUS_ENTRIES_PER_PAGE
  
      entries = []
      CENSUS_ENTRIES_PER_PAGE.times do |i|
        entry_y = y_offset + header_height + entry_height*i
        slop_entry_y = entry_y  - entry_height * (VERTICAL_SLOP / 2)
        slop_entry_height = entry_height  * VERTICAL_SLOP
        entries << [x_offset,slop_entry_y,column_width,slop_entry_height]
      end    
      entries
    end
  
    # identifies rectangles for one column
  # ENTRY_WIDTHS = [70,198,46,46,46,245,120,90,45,45,270,47,47,47,275,170,110]
    module Tasks 
      NO_OF_SCHEDULE = "em_no_of_schedule"
      ADDRESS = "em_address"
      INHABITED = "em_inhabited"
      UNINHABITED = "em_uninhabited"
      ROOMS_OCCUPIED = "em_rooms_occupied"
      NAME_AND_SURNAME = "em_name_and_surname"
      RELATION_TO_HEAD = "em_relation_to_head"
      MARITAL_CONDITION = "em_marital_condition"
      AGE_MALE = "em_age_male"
      AGE_FEMALE = "em_age_female"
      OCCUPATION = "em_occupation"
      EMPLOYER = "em_employment_employer"
      EMPLOYED = "em_employment_employed"
      NEITHER = "em_employment_neither"
      BIRTH_PLACE = "em_birth_place"
      IGNORE = "IGNORE"
      LANGUAGE = "em_language"
    end
  
  
    ENTRY_PROPORTIONS = {
      Tasks::NO_OF_SCHEDULE => 0.03630705394190872,
      Tasks::ADDRESS => 0.10269709543568464, 
      Tasks::INHABITED => 0.023858921161825725, 
      Tasks::UNINHABITED => 0.023858921161825725, 
      Tasks::ROOMS_OCCUPIED => 0.023858921161825725, 
      Tasks::NAME_AND_SURNAME => 0.1270746887966805, 
      Tasks::RELATION_TO_HEAD => 0.06224066390041494, 
      Tasks::MARITAL_CONDITION => 0.046680497925311204, 
      Tasks::AGE_MALE => 0.023340248962655602, 
      Tasks::AGE_FEMALE => 0.023340248962655602, 
      Tasks::OCCUPATION => 0.1400414937759336, 
      Tasks::EMPLOYER => 0.02437759336099585, 
      Tasks::EMPLOYED => 0.02437759336099585, 
      Tasks::NEITHER => 0.02437759336099585, 
      Tasks::BIRTH_PLACE => 0.14263485477178423, 
      Tasks::IGNORE => 0.08817427385892117, 
      Tasks::LANGUAGE => 0.05705394190871369}

    def find_all_rectangles(x_offset,y_offset,page_width,page_height)  # take offset
      entries = []
      
      column_x_offset = 0
      ENTRY_PROPORTIONS.keys.each do |column_proportion|
        column_width = page_width * column_proportion
        entries += find_entry_rectangles(x_offset+column_x_offset, y_offset, column_width, page_height)
        column_x_offset += column_width
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
      if args.count != 5 && args.count != 1
        print "\n\nUsage: rake project:marriages:draw_rectangles[image_file,page_x,page_y,page_w,page_h]\n"
        print "\nimage_file: local copy of a marriage application index image\n"
        print "page_x: x coordinate of upper-left corner of the index page\n"
        print "page_y: y coordinate of upper-left corner of the index page\n"
        print "page_w: width of an index page\n"
        print "page_h: height of an index page\n"
        print "\nexample:\nrake project:marriages:draw_rectangles[../images/brooklyn_1929_p1111.jpg,190,80,560,875]\n"
        exit
      end
      if args.count = 1
        image = Magick::ImageList.new(args[:image_file]).first
        page_x = 0
        page_y = 0
        page_w = image.columns
        page_h = image.rows
      else
        page_x = args[:page_x].to_i
        page_y = args[:page_y].to_i
        page_w = args[:page_w].to_i
        page_h = args[:page_h].to_i
      end
      draw_entry_rectangles(args[:image_file], find_all_rectangles(page_x,page_y,page_w,page_h))
      
    end


    EXAMPLE_CHILD_SUBJECT = 
    {"_id"=>BSON::ObjectId('57bbb67ba020dd0bf8df8db3'),
      "type"=>"em_no_of_schedule",
     "status"=>"active",
     "classification_count"=>0,
     "secondary_subject_count"=>0,
     "classifying_user_ids"=>[],
     "deleting_user_ids"=>[],
     "creating_user_ids"=>[],
     "created_by_user_id"=>"57bbb550a020dd0a95a45117",
     "group_id"=>BSON::ObjectId('57bbb651a020dd0bcefc0191'),
     "location"=>{"standard"=>"freecen_poc/01.01.crop.deskew.jpg"},
     "region"=>
      {"toolName"=>"rectangleTool",
       "color"=>"red",
       "x"=>8.562606305631686,
       "y"=>265.55718976790985,
       "width"=>62.483870967741936,
       "height"=>39.92036186053548,
       "label"=>"No. of Schedule"},
     "width"=>1937,
     "height"=>1482,
     "data"=>
      {"belongsToUser"=>"true",
       "toolName"=>"rectangleTool",
       "userCreated"=>"true",
       "subToolIndex"=>"0",
       "color"=>"red",
       "isTranscribable"=>"true",
       "x"=>"8.562606305631686",
       "y"=>"265.55718976790985",
       "width"=>"62.483870967741936",
       "height"=>"39.92036186053548",
       "_key"=>"0.9161070742965762",
       "status"=>"mark",
       "isUncommitted"=>"true"},
     "parent_subject_id"=>BSON::ObjectId('57bbb651a020dd0bcefc0193'),
     "subject_set_id"=>BSON::ObjectId('57bbb651a020dd0bcefc0192'),
     "random_no"=>0.2592093024905481}


        
  desc "Create child subjects from a grid"
    task :child_subjects_from_census_grid, [:image_file,:page_x,:page_y,:page_w,:page_h] => :environment do |task, args|
      transcribe_workflow = Workflow.where(:name => 'transcribe').first
      Subject.where(:secondary_subject_count => 0, :type => 'root').each do |root_subject|
        page_width = root_subject['width']
        page_height = root_subject['height']
        column_x_offset = 0
        ENTRY_PROPORTIONS.each_pair do |task_name,proportion|  
          column_width = page_width * proportion
          entries = find_entry_rectangles(column_x_offset, 0, column_width, page_height)
          column_x_offset += column_width
          entries.each do |rectangle|
            child = Subject.new(root_subject.attributes.except('_id').deep_dup)
            child.parent_subject=root_subject
            child.type = task_name
            child.classification_count = 0
            child.secondary_subject_count = 0
            child.status = 'active'
            child.workflow = transcribe_workflow
            
            rectangle_attrs = {
              "toolName"=>"rectangleTool",
              "color"=>"red",
              "x"=>rectangle[0],
              "y"=>rectangle[1],
              "width"=>rectangle[2],
              "height"=>rectangle[3]
            }
            child['region'] = rectangle_attrs.deep_dup
            child['region'].merge!(
            {
              'label' => task_name.titleize
            })
            child['data'] = rectangle_attrs#.map { |a,b| a => b.to_s }
            child["data"].merge!(
              {"belongsToUser"=>"false",
               "userCreated"=>"false",
               "subToolIndex"=>"0",
               "isTranscribable"=>"true",
               "status"=>"mark",
               "isUncommitted"=>"true"})

            child.delete("meta_data")
            child.delete("order")
            child.delete("workflow_id")
            child.delete("random_no")


            print "creating child for #{task_name} at #{rectangle[0]},#{rectangle[1]}\tcount=#{Subject.count}\n"
            child.save!
          end
          
        end        
      end
#      draw_entry_rectangles(args[:image_file], find_all_rectangles(page_x,page_y,page_w,page_h))
      
    end

        
    
  
  end  

end

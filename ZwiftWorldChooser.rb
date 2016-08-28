# author: Piotr Kubica
require 'tmpdir'
require 'nokogiri'

zwiftWorlds = {
	:default => "Default - Zwift calendar",
	1 => "Watopia",
	2 => "Richmond",
	3 => "London"}

class ZwiftWorldChooser
	attr_accessor :zwiftPath, :prefPath
	def initialize
		@prefPath = "#{Dir.home}/Documents/Zwift/prefs.xml"
		@settingsPath = "#{Dir.tmpdir}/zwiftWorldChooser.txt"
		# load settings if exist
		if File.exist?(@settingsPath)
			fileLines = File.readlines(@settingsPath)
			return false unless fileLines.size >= 1
			@prefPath = fileLines[0] if File.exist?(fileLines[0])
		else
			settingsFile = File.new(@settingsPath, "w+")
			settingsFile.close
		end
	end
	def isReadyToRun?
		messages = []
		messages << "#{@prefPath} not found. Please check your configuration." unless File.exist?(@prefPath)
		messages
	end 
	def updateSettings
		settingsFile = File.new(@settingsPath, "w")
		settingsFile.write("#{@prefPath}\n")
		settingsFile.close
	end  
	def readPrefXml
		perfFile = File.open("#{@prefPath}", "r")
		prefXml = Nokogiri::XML(perfFile)
		perfFile.close
		prefXml
	end 
	def updatePrefs worldId
		prefXml = readPrefXml
		if worldId == :default
			removeWorldNode prefXml
		else 
			addWorldNode worldId, prefXml
		end
		perfFile = File.open("#{@prefPath}", "w")
		perfFile.write("#{prefXml.to_xml}")
		perfFile.close
	end 
	def readWorld
		prefXml = readPrefXml
		if prefXml.xpath("//ZWIFT//WORLD").empty?
			:default
		else
			worldNode = prefXml.xpath("//ZWIFT//WORLD")[0]
			worldNode.content.to_i
		end
	end
	def removeWorldNode xml
		(xml.xpath("//ZWIFT//WORLD")[0]).remove unless xml.xpath("//ZWIFT//WORLD").empty?
	end
	def addWorldNode worldId, xml
		if xml.xpath("//ZWIFT//WORLD").empty?
			worldNode = Nokogiri::XML::Node.new "WORLD", xml
			worldNode.content = "#{worldId}"
			zwitNode = xml.xpath("//ZWIFT//DEVICES")[0]
			zwitNode.add_previous_sibling worldNode
		else
			worldNode = xml.xpath("//ZWIFT//WORLD")[0]
			worldNode.content = "#{worldId}"
		end
	end 
end 
zwiftWorldChooser = ZwiftWorldChooser.new

# Shoes.show_log
Shoes.app(title: "Zwift World Chooser", width: 450, height: 200, resizable: false) do
 	@main = stack do
 		stack margin: 10 do
	 		flow margin: 10 do
		   		@label = inscription ("Ride in... ")
		   		@label.displace(0, 5)
	   			@listbox = list_box items: zwiftWorlds.values, 
	   								choose: zwiftWorlds[zwiftWorldChooser.readWorld]
	   			@listbox.style(:width => 200)
			end
			flow margin: 10 do
				flow width: 110 do
					@options = button "Configuration..." do
						@main.hide()
						@config.show()
					end
					@options.style(:width => 100)
	 			end
	 			flow width: 110 do
					@launch = button "Save" do
						errorMessages = zwiftWorldChooser.isReadyToRun?
						if errorMessages.empty? 
							zwiftWorldChooser.updateSettings
							zwiftWorldChooser.updatePrefs zwiftWorlds.key(@listbox.text)
						else 
							alert errorMessages
						end
					end 
					@launch.style(:width => 100)
				end
			end
		end
	end 
	@config = stack do
		stack margin: 10, margin_top: 5 do
			stack margin: 10, margin_top: 5, margin_bottom: 5 do
				inscription ("Choose files:")
			end
			stack do
				flow margin: 10, margin_top: 5 do
					flow width: 85 do
						@configPathLabel = inscription ("prefs.xml:")
						@configPathLabel.displace(0, 5)
					end 
					
					@configPathInput = edit_line width: 280
					@configPathInput.text = zwiftWorldChooser.prefPath
					
					flow margin_left: 5, width: 35 do
						@openFileConfig = button "..." do
							@filePrefs = ask_open_file	
							@configPathInput.text = @filePrefs.gsub!("\\", "/") unless @filePrefs.nil?
						end 
						@openFileConfig.style(:width => 30)
					end 
				end 
				flow margin: 10, margin_top: 5 do
					@configOK = button "OK" do
						@config.hide()
						@main.show()
					end 
					@configOK.style(:width => 100)
				end 
			end
		end
	end
	@config.hide()
end
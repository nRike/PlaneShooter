module (..., package.seeall)

function new()
	local context = require("robotlegs/Context").new()
	context.superStartup = context.startup
	
	function context:startup()
		print("MainContext::startup, ID: ", self.ID)
		self:superStartup()
		
		self:mapCommand("startThisMug", "commands/BootstrapCommand")
		
		self:mapMediator("Player", "mediators/PlayerMediator")
		
		self:dispatch({name="startThisMug", target=self})
	end

	return context
end
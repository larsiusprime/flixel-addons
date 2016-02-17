package flixel.addons.api.steam;
import de.polygonal.ds.M;
import de.polygonal.ds.Map;
import flixel.addons.api.steam.FlxSteamControllerManager.FlxSteamController;
import flixel.addons.api.steam.FlxSteamControllerManager.XYEitherBoth;
import flixel.input.FlxInput;
import flixel.input.gamepad.id.FlxGamepadButtonList;
import steamwrap.api.Controller;
import steamwrap.api.Steam;
import steamwrap.data.ControllerConfig;
import steamwrap.data.ButtonAction;
import steamwrap.data.AnalogTriggerAction;
import steamwrap.data.StickPadGyroAction;

/**
 * The Steam API uses a totally different paradigm from a conventional game
 * controller and therefore cannot be unified with either the Lime, OpenFL or 
 * Flixel Gamepad/Joystick APIs. The Steamwrap library provides direct low-
 * level access, but this wraps things up in a more convenient manner.
 * 
 * USAGE:
 * 
 ***********
 * 
 * Create a new FlxSteamControllerManager and pass it a ControllerConfig object
 * (you should parse this from the same VDF file you used to set up your Steam
 * Controller with the Steam API).
 * 
 ***********
 * 
 * Call refresh() as often as you want to check for connected/disconnected
 * controllers.
 * 
 ***********
 * 
 * Call update() every frame to get fresh input for all controllers
 * 
 ***********
 * 
 * Get a controller object with e.g., var myController = getController(0);
 * 
 ***********
 * 
 * Be sure to activate an action set for your controllers before you try to poll for input
 * 
 ************
 * 
 * Check controller input like this:
 * 
 * //Get action handle directly from the Steam API:
 * var jump = Steam.controller.getDigitalActionHandle("jump");
 * 
 * //later...
 * 
 * if(myController.digitalValue(jump,JUST_PRESSED)) {
 *    doJump();
 * }
 * 
 ************
 * 
 * 
 * @author 
 */
class FlxSteamControllerManager
{
	/**
	 * Total number of controllers that have ever been detected during this application's lifetime
	 */
	public var numControllers(get, null):Int = 0;
	
	/**
	 * Total number of controllers that are active right now
	 */
	public var numActiveControllers(get, null):Int;
	
	public function new(Config:ControllerConfig) 
	{
		config = Config;
		
		actionSets     = [];
		digitalHandles = [];
		analogHandles  = [];
		
		for (actionSet:ControllerActionSet in config.actions)
		{
			var asName = actionSet.name;
			var asHandle = Steam.controllers.getActionSetHandle(asName);
			
			actionSets[asHandle] = asName;
			digitalHandles[asHandle] = [];
			analogHandles [asHandle] = [];
			
			for (button:ButtonAction in actionSet.button)
			{
				var bnHandle = Steam.controllers.getDigitalActionHandle(button.name);
				digitalHandles[asHandle].push(bnHandle);
			}
			
			for (analog:AnalogTriggerAction in actionSet.analogTrigger)
			{
				var anHandle = Steam.controllers.getAnalogActionHandle(analog.name);
				analogHandles[asHandle].push(anHandle);
			}
			
			for (stickPadGyro:StickPadGyroAction in actionSet.stickPadGyro)
			{
				var spgHandle = Steam.controllers.getAnalogActionHandle(stickPadGyro.name);
				analogHandles[asHandle].push(anHandle);
			}
		}
		
		refresh();
	}
	
	/**
	 * Enable an action set for a given controller
	 * @param	actionSet	the name of the action set
	 * @param	controller	the controller to activate; if null, activates this set for all of them
	 * @return
	 */
	
	public function activateActionSet(actionSet:String, ?controller:FlxSteamController):Bool
	{
		var actionHandle = Steam.controllers.getActionSetHandle(actionSet);
		
		var b = false;
		
		if (controller != null && controller.active)
		{
			controller.actionSet = actionHandle;
			b = true;
		}
		else
		{
			for (controller in controllers)
			{
				if (controller.active)
				{
					controller.actionSet = actionHandle;
					b = true;
				}
			}
		}
		
		return b;
	}
	
	/**
	 * Get a connected Steam controller
	 * @param	i an integer between 0 and numControllers (NOT the controller's steam API handle!)
	 * @return
	 */
	
	public function getController(i:Int):FlxSteamController
	{
		if (i < 0 || i >= controllers.length) return null;
		return controllers[i];
	}
	
	/**
	 * Poll for input & update internal controller states
	 */
	
	public function update():Void
	{
		for (i in 0...controllers.length)
		{
			if (controllers[i].active)
			{
				controllers[i].update(digitalHandles, analogHandles);
			}
		}
	}
	
	/**
	 * Check for connected steam controllers & activate / deactivate accordingly
	 */
	
	public function refresh():Void
	{
		var controllerHandles = Steam.controllers.getConnectedControllers();
		
		for (i in 0...controllers.length)
		{
			//deactive existing controllers that aren't in the list of connected handles
			if (controllerHandles.indexOf(controllers[i].handle) == -1)
			{
				controllers[i].active = false;
			}
		}
		
		for (i in 0...controllerHandles.length)
		{
			var match = false;
			for (j in 0...controllers.length)
			{
				if (controllers[j].handle == controllerHandles[i])
				{
					match = true;
					break;
				}
			}
			//create new controllers to match new connected handles
			if (!match)
			{
				controllers.push(new FlxSteamController(controllerHandles[i], this);
			}
		}
	}
	
	private var actionSets:Array<String>;
	private var digitalHandles:Array<Array<Int>>;
	private var analogHandles:Array<Array<Int>>;
	
	private var config:ControllerConfig;
	private var controllers:Array<FlxSteamController>
	
	private function get_numControllers():Int
	{
		return controllers.length;
	}
	
	private function get_numActiveControllers():Int
	{
		var c = 0;
		for (i in 0...controllers.length) {
			if (controllers[i].active) {
				c++;
			}
		}
		return c;
	}
}

@:allow(FlxSteamControllerManager)
class FlxSteamController
{
	public var active(default, null):Bool;
	public var handle(default, null):Int;
	public var actionSet(default, set):Int;
	
	private function new(Handle:Int, fscm:FlxSteamControllerManager)
	{
		handle = Handle;
		digitalActions = [];
		analogActions  = [];
		analogActionData = [];
		
		for (i in 0...fscm.actionSets.length)
		{
			digitalActions[i] = [];
			analogActions [i] = [];
			
			for (di in 0...fscm.digitalHandles.length)
			{
				digitalActions[i].push(new FlxSteamDigitalInput(fscm.digitalHandles[di]));
			}
			
			for (ai in 0...fscm.analogHandles.length)
			{
				analogActions[i].push(new ControllerAnalogActionData(fscm.analogHandles[ai]));
			}
		}
	}
	
	/**
	 * Update all the internal button states
	 * @param	digitalHandles	handles of all digital actions for the current action set
	 * @param	analogHandles	handles of all analog actions for the current action set
	 */
	
	public function update(digitalHandles:Array<Int>, analogHandles:Array<Int>):Void
	{
		if (actionSet < 0) return;
		for (di in 0...digitalHandles.length)
		{
			digitalActions[actionSet][di].setData(Steam.controllers.getDigitalActionData(handle, digitalHandles[di]));
			digitalActions[actionSet][di].input.update();
		}
		for (ai in 0...analogHandles.length)
		{
			analogActions[actionSet][ai].setData(Steam.controllers.getAnalogActionData(handle, analogHandles[ai], analogData));
		}
	}
	
	/**
	 * Status of a given digital action input
	 * @param	actionHandle	handle for the digital action
	 * @param	state	PRESSED, JUST_PRESSED, RELEASED, JUST_RELEASED
	 * @return
	 */
	
	public function digitalValue(actionHandle:Int, state:FlxInputState):Bool
	{
		if (actionSet < 0 || actionHandle < 0 || actionHandle >= digitalActions[actionSet].length) return false;
		return digitalActions[actionSet][actionHandle].input.current == state;
	}
	
	/**
	 * Value of a given analog action input
	 * @param	actionHandle	handle for the analog action
	 * @param	which	X or Y
	 * @return	-1.0 to 1.0 (joystick_move mode) or screen coordinate (absolute_mouse mode) or 0.0 to 1.0 (analog trigger)
	 */
	
	public function analogValue(actionHandle:Int, which:XY):Float
	{
		if (actionSet < 0 || actionHandle < 0 || actionHandle >= analogActions[actionSet].length) return false;
		return switch(which)
		{
			case X: analogActions[actionSet][actionHandle].data.x;
			case Y: analogActions[actionSet][actionHandle].data.y;
		}
	}
	
	/**
	 * Whether an analog action input has just changed value
	 * @param	actionHandle	handle for the analog action
	 * @param	which	X, Y, Either, Both: which axes you are checking for
	 * @return
	 */
	
	public function analogJustMoved(actionHandle:Int, which:XYEitherBoth):Bool
	{
		if (actionSet < 0 || actionHandle < 0 || actionHandle >= analogActions[actionSet].length) return false;
		return switch(which)
		{
			case X: analogActions[actionSet][actionHandle].justMoved.x;
			case Y: analogActions[actionSet][actionHandle].justMoved.y;
			case Either: analogActions[actionSet][actionHandle].justMoved.either;
			case Both: analogActions[actionSet][actionHandle].justMoved.both;
		}
	}
	
	/**
	 * Whether an analog action input is in its dead zone or off state
	 * @param	actionHandle	handle for the analog action
	 * @param	which	X, Y, Either, Both: which axes youa re checking for
	 * @return
	 */
	
	public function analogReleased(actionHandle:Int, which:XYEitherBoth):Bool
	{
		if (actionSet < 0 || actionHandle < 0 || actionHandle >= analogActions[actionSet].length) return false;
		return switch(which)
		{
			case X: analogActions[actionSet][actionHandle].released.x;
			case Y: analogActions[actionSet][actionHandle].released.y;
			case Either: analogActions[actionSet][actionHandle].released.either;
			case Both: analogActions[actionSet][actionHandle].released.both;
		}
	}
	
	private function set_actionSet(actionSetHandle:Int):Int
	{
		if (Steam.controllers.activateActionSet(handle, actionSetHandle) == 1)
		{
			actionSet = actionSetHandle;
		}
		else
		{
			actionSet = -1;
		}
		return actionSet;
	}
	
	//static helper variable for filling up from the steam API without lots of allocations
	private static var analogData:ControllerAnalogActionData = new ControllerAnalogActionData();
	
	private var digitalActions:Array<Array<FlxSteamDigitalInput>>;
	private var analogActions:Array<Array<FlxSteamAnalogInput>>;
}

enum XY {
	X;
	Y;
}

enum XYEitherBoth {
	X;
	Y;
	Either;
	Both;
}

class FlxSteamDigitalInput
{
	public var input:FlxInput<Int>;
	public var data(default, null):ControllerDigitalActionData;
	
	public function new(id:Int)
	{
		input = new FlxInput<Int>(id);
		data  = 0;
	}
	
	public function setData(d:ControllerDigitalActionData):Void
	{
		data = d;
		if (data.bActive && data.bState)
		{
			input.press();
		}
		else
		{
			input.release();
		}
	}
}

class FlxSteamAnalogInput
{
	public var justMoved(default, null):FlxSteamAnalogStateList;
	public var released (default, null):FlxSteamAnalogStateList;
	public var inputMode:AnalogInputMode;
	public var data:ControllerAnalogActionData;
	
	public function new(InputMode:AnalogInputMode)
	{
		inputMode = InputMode;
		justMoved = new FlxSteamAnalogStateList();
		released  = new FlxSteamAnalogStateList();
		data = new ControllerAnalogActionData();
	}
	
	public function setData(d:ControllerAnalogActionData):Void
	{
		data.bActive = d.bActive;
		
		if (!data.bActive)
		{
			justMoved.both = false;
			released.both = true;
			return data;
		}
		
		data.eMode = d.eMode;
		switch(inputMode)
		{
			case AnalogInputMode.AbsoluteMouse:
				released.both = false;
			case AnalogInputMode.JoystickMove :
				released.x = (d.x == 0);
				released.y = (d.y == 0);
		}
		justMoved.x = (data.x != d.x);
		justMoved.y = (data.y != d.y);
		data.x = d.x;
		data.y = d.y;
	}
}

class FlxSteamAnalogStateList
{
	public var x:Bool;
	public var y:Bool;
	public var either(get,null):Bool;
	public var both(get,set):Bool;
	
	public function get_both:Bool()   { return x && y };
	public function get_either:Bool() { return x || y };
	
	public function set_both(b:Bool)
	{
		x = y = b;
	}
	
	public function new()
	{
		x = y = false;
	}
}
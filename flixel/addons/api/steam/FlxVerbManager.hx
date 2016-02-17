package flixel.addons.api.steam;
import com.leveluplabs.tdrpg.NameValue;
import de.polygonal.ds.Map;
import flixel.addons.api.steam.FlxVerbManager.FlxDigitalGamepadInput;
import flixel.addons.api.steam.FlxVerbManager.FlxDigitalInputType;
import flixel.addons.api.steam.FlxVerbManager.FlxDigitalVerb;
import flixel.addons.api.steam.FlxVerbManager.FlxDigitalVerbInputType;
import flixel.addons.api.steam.FlxVerbManager.FlxVerb;
import flixel.addons.api.steam.FlxVerbManager.IFlxGamepadVerbInput;
import flixel.input.FlxInput;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.IFlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouse;
import flixel.input.mouse.FlxMouseButton;
import steamwrap.api.Controller;
import steamwrap.api.Steam;

/**
 * ...
 * @author 
 */
class FlxVerbManager
{
	public var currentSet(default, set):Int;
	
	public function new() 
	{
		sets = [];
	}
	
	public function addSet(Name:String, Digital:Array<FlxVerb>, Analog:Array<FlxVerb>):Int
	{
		var existsIndex:Int = -1;
		var i = 0;
		for (set in sets)
		{
			if (set.name == Name)
			{
				existsIndex = i;
				break;
			}
			i++;
		}
		
		var returnVal = -1;
		
		if (existsIndex != -1)
		{
			sets[existsIndex].digital = Digital;
			sets[existsIndex].analog  = Analog;
			returnVal = existsIndex;
		}
		else
		{
			sets.push(new FlxVerbSet(Name, Digital, Analog));
			returnVal = sets.length - 1;
		}
		
		sets[returnVal].handle = returnVal;
		
		return returnVal;
	}
	
	public function update(elapsed:Float):Void
	{
		if (currentSet == -1) return;
		sets[currentSet].update(elapsed);
	}
	
	public function set_currentSet(i:Int):Int
	{
		if (i >= 0 && i < sets.length)
		{
			currentSet = i;
		}
		else
		{
			currentSet = -1;
		}
		return currentSet;
	}
	
	private var sets:Array<FlxVerbSet>;
}

@:allow(FlxVerbManager)
class FlxVerbSet
{
	private var name(default, null):String;
	private var handle(default, null):Int;
	private var digital:Array<FlxVerb>;
	private var analog:Array<FlxVerb>;
	
	private function new(Name:String, Digital:Array<FlxVerb>, Analog:Array<FlxVerb>)
	{
		name = Name;
		digital = digital;
		analog = analog;
	}
	
	private function update(elapsed:Float):Void
	{
		for (verb in digital)
		{
			verb.update();
		}
		
		for (verb in analog)
		{
			verb.update();
		}
	}
}

class FlxVerb
{
	public var name(default, null):String;
	public var handle(default, null):Int;
	public var callback(default, null):FlxVerb->Void;
	
	public function update():Void
	{
		for (input in inputs)
		{
			input.update();
			
			if (callback != null && input.fire())
			{
				callback(this);
				return;			//fire a maximum of once per frame per verb
			}
		}
	}
}

class FlxDigitalVerb extends FlxVerb
{
	public function new(Name:String, Callback:FlxVerb->Void, Handle:Int = -1)
	{
		name = Name;
		handle = Handle;
		callback = Callback;
	}
	
	/**
	 * Add an input value that will activate this verb
	 * @param	InputType What kind of input is it (keyboard press, mouse click, gamepad button, etc)
	 * @param	InputID The integer identifier of the input in question (button ID or key code)
	 * @param	FireStatus The status to check for (PRESSED, JUST_RELEASED, etc)
	 * @param	DeviceID The integer identifier of the device (gamepad or steam controller) in question
	 * @return
	 */
	
	public function addInput(InputType:FlxDigitalInputType, InputID:Int, FireStatus:FlxVerbStatus, DeviceID:Int):FlxDigitalVerb
	{
		if (false == checkExists(InputType, InputID, FireStatus, DeviceID))
		{
			inputs.push(new FlxDigitalInput(InputType, InputID, FireStatus, DeviceID);
		}
		return this;
	}
	
	private function checkExists(InputType:FlxDigitalInputType, InputID:Int, FireStatus:FlxVerbStatus, DeviceID:Int):Bool
	{
		for (input in inputs)
		{
			if (input.type == InputType && input.input.ID == InputID && input.fireStatus == FireStatus && input.deviceID == DeviceID)
			{
				return true;
			}
		}
		return false;
	}
	
	private var inputs:Array<FlxDigitalInput>;
}

class FlxAnalogVerb extends FlxVerb
{
	
	/**
	 * Add an input value that will activate this verb
	 * @param	InputType What kind of input is it (mouse movement, gamepad stick/trigger, etc)
	 * @param	InputID The integer identifier of the input in question (button ID or key code)
	 * @param	FireStatus The status to check for (PRESSED, JUST_RELEASED, etc)
	 * @param	DeviceID The integer identifier of the device (gamepad or steam controller) in question
	 * @param	Axis which axis or axes to pay attention to
	 * @return
	 */
	 
	public function addInput(InputType:FlxAnalogInputType, InputID:Int, FireStatus:FlxVerbStatus, DeviceID:Int, ?Axis:FlxAnalogAxis=FlxAnalogAxis.EITHER):Bool
	{
		if (false == checkExists(InputType, InputID, FireStatus, DeviceID, Axis))
		{
			inputs.push(new FlxAnalogInput(InputType, InputID, Axis, FireStatus, DeviceID);
		}
		return this;
	}
	
	private function checkExists(InputType:FlxAnalogInputType, InputID:Int, FireStatus:FlxVerbStatus, DeviceID:Int, Axis:FlxAnalogAxis):Bool
	{
		for (input in inputs)
		{
			if (input.type == InputType && input.ID == InputID && input.axis == Axis && input.fireStatus == FireStatus && input.deviceID == DeviceID)
			{
				return true;
			}
		}
		return false;
	}
	
	private var inputs:Array<FlxAnalogInput>;
}

enum FlxDigitalInputType
{
	Unknown;
	MouseClick;
	KeyboardPress;
	GamepadButtonPress;
	SteamControllerDigitalAction;
}

enum FlxAnalogInputType
{
	Unknown;
	Mouse;
	Gamepad;
	SteamControllerAnalogAction;
}

enum FlxAnalogAxis
{
	X;
	Y;
	BOTH;
	EITHER;
}

abstract FlxVerbStatus(Int)
{
	var      RELEASED:Int = 0x0000001;
	var JUST_RELEASED:Int = 0x0000010;
	var       PRESSED:Int = 0x0000100;
	var  JUST_PRESSED:Int = 0x0001000;
	
	public function matches(other:FlxVerbStatus):Bool
	{
		return (this & other == other);
	}
}

class FlxVerbInput
{
	public var type(default, null):FlxDigitalInputType = FlxDigitalInputType.Unknown;
	public var deviceID(default, null):Int = HANDLE_FIRST_ACTIVE;
	public var fireStatus(default, null):FlxVerbStatus;
	
	public static inline var HANDLE_ALL:Int = -1;
	public static inline var HANDLE_FIRST_ACTIVE:Int = -2;
	
	public function new(InputType:FlxDigitalInputType, FireStatus:FlxVerbStatus, DeviceID:Int)
	{
		type = InputType;
		fireStatus = FireStatus;
		deviceID = DeviceID;
	}
	
	public function update():Void
	{
		
	}
	
	public function fire():Bool
	{
		return false;
	}
}

/**********DIGITAL FLXVERB INPUT************/

class FlxDigitalInput extends FlxVerbInput
{
	public var input(default, null):FlxInput<Int>;
	
	public function new(InputType:FlxDigitalInputType, InputID:Int, FireStatus:FlxVerbStatus, DeviceID:Int)
	{
		super(InputType, FireStatus, DeviceID);
		input = new FlxInput<Int>(ID);
	}
	
	public override function update():Void
	{
		var pressed = switch(type)
		{
			case MouseClick: checkMouse();
			case KeyboardPress: checkKey();
			case GamepadButtonPress: checkGamepad();
			case SteamControllerDigitalAction: checkSteamController();
			default: false;
		}
		if (pressed)
			input.press();
		else
			input.release();
	}
	
	public override function fire():Bool
	{
		return switch(input.current)
		{
			FlxInputState.PRESSED:       fireStatus.matches(FlxVerbStatus.PRESSED);
			FlxInputState.JUST_PRESSED:  fireStatus.matches(FlxVerbStatus.JUST_PRESSED);
			FlxInputState.RELEASED:      fireStatus.matches(FlxVerbStatus.RELEASED);
			FlxInputState.JUST_RELEASED: fireStatus.matches(FlxVerbStatus.JUST_RELEASED);
		}
	}
	
	private inline function checkMouse():Bool
	{
		return switch(input.ID)
		{
			case FlxMouseButtonID.LEFT  : FlxG.mouse.pressed;
			case FlxMouseButtonID.MIDDLE: FlxG.mouse.pressedMiddle;
			case FlxMouseButtonID.RIGHT : FlxG.mouse.pressedRight;
		}
	}
	
	private inline function checkKey():Bool
	{
		return (FlxG.keys.checkStatus(input.ID, FlxInputState.PRESSED);
	}
	
	private inline function checkGamepad():Bool
	{
		if (deviceID == FlxVerbInput.HANDLE_ALL)
		{
			return (FlxG.gamepads.anyPressed(input.ID));
		}
		else
		{
			var gamepad:FlxGamepad = null;
			
			if (deviceID == FlxVerbInput.HANDLE_FIRST_ACTIVE)
			{
				gamepad = FlxG.gamepads.getFirstActiveGamepad();
			}
			else if(deviceID >= 0)
			{
				gamepad = FlxG.gamepads.getByID(deviceID);
			}
			
			if (gamepad != null)
			{
				return (gamepad.checkStatus(input.ID))
			}
		}
		return false;
	}
	
	private inline function checkSteamController():Bool
	{
		#if steamwrap
			//TODO: implement HANDLE_FIRST_ACTIVE
			var data = Steam.controllers.getDigitalActionData(deviceID, input.ID);
			return (data.bActive && data.bState);
		#end
	}
}

/**********ANALOG FLXVERB INPUT************/


class FlxAnalogInput extends FlxVerbInput
{
	public var axis(default, null):FlxAnalogAxis;
	
	public var x(default, null):Float;
	public var y(default, null):Float;
	public var xMoved(default, null):FlxInputState<Int>;
	public var yMoved(default, null):FlxInputState<Int>;
	public var bothMoved(default, null):FlxInputState<Int>;
	public var eitherMoved(default, null):FlxInputState<Int>;
	
	function new (InputType:FlxAnalogInputType, InputID:Int, FireStatus:FlxVerbStatus, DeviceID:Int, Axis:FlxAnalogAxis=FlxAnalogAxis.EITHER)
	{
		super(InputType, FireStatus, DeviceID);
		axis = Axis;
	}
	
	public function update():Void
	{
		switch(type)
		{
			case FlxAnalogInputType.Mouse: checkMouse();
			case FlxAnalogInputType.Gamepad: checkGamepad();
			case FlxAnalogInputType.SteamControllerAnalogAction: checkSteamController();
			default://
		}
	}
	
	public override function fire():Bool
	{
		return switch(axis)
		{
			case X: checkStatus(xMoved, fireStatus);
			case Y: checkStatus(yMoved, fireStatus);
			case EITHER: checkStatus(eitherMoved, fireStatus);
			case BOTH: checkStatus(bothMoved, fireStatus);
		}
	}
	
	private inline function checkStatus(inputState:FlxInputState, status:FlxVerbStatus):Bool
	{
		return switch(inputState)
		{
			case PRESSED: status.matches(FlxVerbStatus.PRESSED);
			case JUST_PRESSED: status.matches(FlxVerbStatus.JUST_PRESSED);
			case RELEASED: status.matches(FlxVerbStatus.RELEASED);
			case JUST_RELEASED: status.matches(FlxVerbStatus.JUST_RELEASED);
		}
	}
	
	private function checkMouse():Void
	{
		updateVals(FlxG.mouse.x, FlxG.mouse.y);
	}
	
	private function checkGamepad():Void
	{
		if (deviceID != FlxVerbInput.HANDLE_ALL)
		{
			var gamepad:FlxGamepad = null;
			
			if (deviceID == FlxVerbInput.HANDLE_FIRST_ACTIVE)
			{
				gamepad = FlxG.gamepads.getFirstActiveGamepad();
			}
			else if(deviceID >= 0)
			{
				gamepad = FlxG.gamepads.getByID(deviceID);
			}
			
			if (gamepad != null)
			{
				switch(input.ID)
				{
					case FlxGamepadInputID.LEFT_ANALOG_STICK: 
						updateVals(gamepad.analog.value.LEFT_STICK_X, gamepad.analog.value.LEFT_STICK_Y);
					case FlxGamepadInputID.RIGHT_ANALOG_STICK:
						updateVals(gamepad.analog.value.RIGHT_STICK_X, gamepad.analog.value.RIGHT_STICK_Y);
					case FlxGamepadInputID.LEFT_TRIGGER:
						updateVals(gamepad.analog.value.LEFT_TRIGGER, 0);
					case FlxGamepadInputID.RIGHT_TRIGGER:
						updateVals(gamepad.analog.value.RIGHT_TRIGGER, 0);
				}
			}
		}
		return false;
	}
	
	#if steamwrap
	private static var analogActionData:ControllerAnalogActionData = new ControllerAnalogActionData();
	#end
	
	private inline function checkSteamController():Bool
	{
		#if steamwrap
		//TODO: implement HANDLE_FIRST_ACTIVE
		analogActionData = Steam.controllers.getAnalogActionData(controllerHandle, input.ID, analogActionData);
		updateVals(analogActionData.x, analogActionData.y);
		#end
	}
	
	private function updateVals(X:Float, Y:Float):Void
	{
		if (X != x)
		{
			xMoved.press();
		}
		else
		{
			xMoved.release();
		}
		
		if (Y != y)
		{
			yMoved.press();
		}
		else
		{
			yMoved.release();
		}
		
		if (xMoved.current == PRESSED && yMoved.current == PRESSED)
		{
			bothMoved.press();
		}
		else
		{
			bothMoved.release();
		}
		
		if (xMoved.current == PRESSED || yMoved.current == PRESSED)
		{
			eitherMoved.press();
		}
		else
		{
			eitherMoved.release();
		}
		
		x = X;
		y = Y;
	}
}
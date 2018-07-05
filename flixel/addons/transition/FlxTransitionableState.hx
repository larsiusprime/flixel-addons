package flixel.addons.transition;

import flixel.FlxState;
import flixel.tweens.FlxTween;

/**
 * FlxTransitionableState
 * 
 * A FlxState which can perform visual transitions
 * 
 * Usage:
 * 
 * First, extend FlxTransitionableState as ie, FooState
 * 
 * Method 1: 
 *  
 *  var in:TransitionData = new TransitionData(...);		//add your data where "..." is
 *  var out:TransitionData = new TransitionData(...);
 * 
 *  FlxG.switchState(new FooState(in,out));
 * 
 * Method 2:
 * 
 *  FlxTransitionableState.defaultTransIn = new TransitionData(...);
 *  FlxTransitionableState.defaultTransOut = new TransitionData(...);
 *  
 *  FlxG.switchState(new FooState());
 * 
 */

class FlxTransitionableState extends FlxState
{
	//global default transitions for ALL states, used if transIn/transOut are null
	public static var defaultTransIn:TransitionData=null;
	public static var defaultTransOut:TransitionData=null;
	
	public static var skipNextTransIn:Bool = false;
	public static var skipNextTransOut:Bool = false;
	
	//beginning & ending transitions for THIS state:
	public var transIn:TransitionData;
	public var transOut:TransitionData;
	
	public var hasTransIn(get, null):Bool;
	public var hasTransOut(get, null):Bool;
	
	public var transitioning(default, null):Bool = false;
	
	/**
	 * Create a state with the ability to do visual transitions
	 * @param	TransIn		Plays when the state begins
	 * @param	TransOut	Plays when the state ends
	 */
	
	public function new(?TransIn:TransitionData, ?TransOut:TransitionData)
	{
		transIn = TransIn;
		transOut = TransOut;
		
		if (transIn == null && defaultTransIn != null)
		{
			transIn = defaultTransIn;
		}
		if (transOut == null && defaultTransOut != null)
		{
			transOut = defaultTransOut;
		}
		super();
	}
	
	override public function destroy():Void
	{
		super.destroy();
		transIn = null;
		transOut = null;
		_onExit = null;
	}
	
	override public function create():Void 
	{
		super.create();
		transitionIn();
	}
	
	override public function switchTo(nextState:FlxState):Bool 
	{
		if (!hasTransOut)
		{
			return true;
		}
		
		if (!_exiting)
		{
			transitionToState(nextState);
			return transOutFinished;
		}

		if (!transOutFinished)
		{
			checkTransOutFinished(); //fix an edge case bug
		}
		return transOutFinished;
	}
	
	private function checkTransOutFinished()
	{
		if (subState != null)
		{
			if (Std.is(subState, Transition))
			{
				var _trans:Transition = cast subState;
				if (_trans.checkFinished())
				{
					transOutFinished = true;
				}
				else
				{
					return;
				}
			}
		}
		else
		{
			transOutFinished = true;
		}
		return;
	}
	
	private function transitionToState(nextState:FlxState):Void
	{
		if (_exiting)
		{
			return;
		}
		
		//play the exit transition, and when it's done call FlxG.switchState
		_exiting = true;
		transitionOut(function()
		{
			doSwitchState(nextState);
		});
		
		if (skipNextTransOut)
		{
			skipNextTransOut = false;
			finishTransOut();
		}
	}
	
	private function doSwitchState(nextState:FlxState):Void
	{
		FlxG.switchState(nextState);
	}
	
	/**
	 * Starts the in-transition. Can be called manually at any time.
	 */
	public function transitionIn():Void
	{
		if (transitioning) return;
		
		transitioning = true;
		if (transIn != null && transIn.type != NONE)
		{
			if (skipNextTransIn)
			{
				skipNextTransIn = false;
				if (finishTransIn != null)
				{
					finishTransIn();
				}
				return;
			}
			
			var _trans = createTransition(transIn);
			
			_trans.setStatus(FULL);
			openSubState(_trans);
			
			_trans.finishCallback = finishTransIn;
			_trans.start(OUT);
		}
	}
	
	/**
	 * Starts the out-transition. Can be called manually at any time.
	 */
	public function transitionOut(?OnExit:Void->Void):Void
	{
		if (transitioning) return;
		
		transitioning = true;
		_onExit = OnExit;
		if (hasTransOut)
		{
			var _trans = createTransition(transOut);
			
			_trans.setStatus(EMPTY);
			openSubState(_trans);
			
			_trans.finishCallback = finishTransOut;
			_trans.start(IN);
		}
		else
		{
			_onExit();
		}
	}
	
	private var transOutFinished:Bool = false;
	
	private var _exiting:Bool = false;
	private var _onExit:Void->Void;
	
	private function get_hasTransIn():Bool
	{
		return transIn != null && transIn.type != NONE;
	}
	
	private function get_hasTransOut():Bool
	{
		return transOut != null && transOut.type != NONE;
	}
	
	private function createTransition(data:TransitionData):Transition
	{
		return switch (data.type)
		{
			case TILES: new Transition(data);
			case FADE: new Transition(data);
			default: null;
		}
	}
	
	private function finishTransIn()
	{
		closeSubState();
		transitioning = false;
	}
	
	private function finishTransOut()
	{
		transOutFinished = true;
		
		if (!_exiting)
		{
			closeSubState();
		}
		
		if (_onExit != null)
		{
			_onExit();
		}
		
		transitioning = false;
	}
}
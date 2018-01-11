package flixel.addons.transition;

import flixel.addons.transition.FlxTransitionSprite.TransitionStatus;
import flixel.addons.transition.TransitionData;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

/**
 * ...
 * @author larsiusprime
 */
@:allow(flixel.addons.transition.Transition)
class TransitionEffect extends FlxSpriteGroup
{
	public var finishCallback:Void->Void;
	public var finished(default, null):Bool = false;
	
	private var _started:Bool = false;
	private var _endStatus:TransitionStatus;
	private var _finalDelayTime:Float = 0.01;
	
	private var _data:TransitionData;
	private var tween:FlxTween;
	
	private var _elapsed:Float = 0.0;
	private var _paused:Bool = false;

	public function new(data:TransitionData) 
	{
		_data = data;
		super();
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		finishCallback = null;
	}
		
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (_started && tween != null && tween.active)
		{
			_elapsed += elapsed;
		}
	}
	
	public function start(NewStatus:TransitionStatus):Void
	{
		_started = true;
		if (NewStatus == IN)
		{
			_endStatus = FULL;
		}
		else
		{
			_endStatus = EMPTY;
		}
	}
	
	public function pause(b:Bool):Void
	{
		_paused = b;
		//pause logic per subclass
	}
	
	public function setStatus(NewStatus:TransitionStatus):Void
	{
		//override per subclass
	}
	
	private function checkFinished():Bool
	{
		
		if (finished) return true;
		var totalTime = tween.duration + _finalDelayTime;
		if (_elapsed > totalTime)
		{
			return true;
		}
		return false;
	}
	
	private function delayThenFinish():Void
	{
		new FlxTimer().start(_finalDelayTime, onFinish);	//force one last render call before exiting
	}
	
	private function onFinish(f:FlxTimer):Void
	{
		finished = true;
		if (finishCallback != null)
		{
			finishCallback();
			finishCallback = null;
		}
	}
}